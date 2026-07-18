use std::time::Instant;

use rusqlite::{Connection, OptionalExtension, TransactionBehavior, params};
use sha2::{Digest, Sha256};
use thiserror::Error;
use time::OffsetDateTime;
use time::macros::format_description;

const BOOTSTRAP_SQL: &str = r#"CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    checksum_sha256 TEXT NOT NULL,
    applied_at TEXT NOT NULL,
    application_version TEXT NOT NULL,
    execution_ms INTEGER NOT NULL,
    CONSTRAINT ck_schema_migrations__version_positive CHECK (version > 0),
    CONSTRAINT ck_schema_migrations__name_present CHECK (length(trim(name)) > 0),
    CONSTRAINT ck_schema_migrations__checksum_sha256 CHECK (
        length(checksum_sha256) = 64
        AND checksum_sha256 NOT GLOB '*[^0-9a-f]*'
    ),
    CONSTRAINT ck_schema_migrations__applied_at_format CHECK (
        length(applied_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', applied_at) = applied_at
    ),
    CONSTRAINT ck_schema_migrations__application_version_present CHECK (
        length(trim(application_version)) > 0
    ),
    CONSTRAINT ck_schema_migrations__execution_ms_nonnegative CHECK (execution_ms >= 0)
) STRICT;"#;

#[derive(Debug, Clone, Copy)]
pub(crate) struct Migration {
    pub version: i64,
    pub name: &'static str,
    pub sql: &'static str,
}

pub(crate) const MIGRATIONS: &[Migration] = &[
    Migration {
        version: 1,
        name: "schema_metadata_and_institution",
        sql: include_str!("../migrations/0001_schema_metadata_and_institution.sql"),
    },
    Migration {
        version: 2,
        name: "attachments_and_audit",
        sql: include_str!("../migrations/0002_attachments_and_audit.sql"),
    },
    Migration {
        version: 3,
        name: "staff_and_organization",
        sql: include_str!("../migrations/0003_staff_and_organization.sql"),
    },
    Migration {
        version: 4,
        name: "institution_sites_and_resources",
        sql: include_str!("../migrations/0004_institution_sites_and_resources.sql"),
    },
    Migration {
        version: 5,
        name: "staff_site_assignments",
        sql: include_str!("../migrations/0005_staff_site_assignments.sql"),
    },
];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MigrationReport {
    pub available: usize,
    pub applied: usize,
    pub newly_applied: usize,
}

#[derive(Debug, Error)]
pub enum MigrationError {
    #[error("SQLite operation failed")]
    Sqlite(#[from] rusqlite::Error),
    #[error("database directory operation failed")]
    Io(#[from] std::io::Error),
    #[error("required SQLite capability is unavailable: {0}")]
    CapabilityMissing(&'static str),
    #[error("migration blocked: {reason}")]
    Blocked { reason: String },
    #[error("failed to create a canonical UTC timestamp")]
    Timestamp,
    #[error("pre-upgrade backup verification failed")]
    BackupVerification,
}

impl MigrationError {
    pub fn code(&self) -> &'static str {
        match self {
            Self::Blocked { .. } => "MIGRATION_BLOCKED",
            Self::CapabilityMissing(_) => "SQLITE_CAPABILITY_MISSING",
            Self::Sqlite(_) | Self::Io(_) | Self::Timestamp | Self::BackupVerification => {
                "STORAGE_FAILURE"
            }
        }
    }
}

pub(crate) fn migrate(
    connection: &mut Connection,
    application_version: &str,
) -> Result<MigrationReport, MigrationError> {
    bootstrap(connection)?;
    apply_migrations(connection, application_version, MIGRATIONS)
}

pub(crate) fn latest_version() -> i64 {
    MIGRATIONS.last().map_or(0, |migration| migration.version)
}

pub(crate) fn current_version(connection: &Connection) -> Result<Option<i64>, MigrationError> {
    let migrations_table_exists: bool = connection.query_row(
        "SELECT EXISTS(
            SELECT 1 FROM sqlite_schema WHERE type = 'table' AND name = 'schema_migrations'
         )",
        [],
        |row| row.get(0),
    )?;
    if !migrations_table_exists {
        return Ok(None);
    }

    let version = connection.query_row(
        "SELECT COALESCE(MAX(version), 0) FROM schema_migrations",
        [],
        |row| row.get(0),
    )?;
    Ok(Some(version))
}

pub(crate) fn bootstrap(connection: &Connection) -> Result<(), MigrationError> {
    let existing_sql: Option<String> = connection
        .query_row(
            "SELECT sql FROM sqlite_schema WHERE type = 'table' AND name = 'schema_migrations'",
            [],
            |row| row.get(0),
        )
        .optional()?;

    match existing_sql {
        None => connection.execute_batch(BOOTSTRAP_SQL)?,
        Some(sql) if normalize_sql(&sql) == normalize_sql(BOOTSTRAP_SQL) => {}
        Some(_) => {
            return Err(MigrationError::Blocked {
                reason: "schema_migrations definition does not match this application".to_owned(),
            });
        }
    }

    Ok(())
}

pub(crate) fn apply_migrations(
    connection: &mut Connection,
    application_version: &str,
    migrations: &[Migration],
) -> Result<MigrationReport, MigrationError> {
    validate_catalog(migrations)?;
    validate_applied_prefix(connection, migrations)?;

    let mut newly_applied = 0;
    for migration in migrations {
        let checksum = sha256_hex(migration.sql.as_bytes());
        let applied: Option<(String, String)> = connection
            .query_row(
                "SELECT name, checksum_sha256 FROM schema_migrations WHERE version = ?1",
                [migration.version],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .optional()?;

        match applied {
            Some((name, applied_checksum))
                if name == migration.name && applied_checksum == checksum =>
            {
                continue;
            }
            Some((name, applied_checksum)) => {
                return Err(MigrationError::Blocked {
                    reason: format!(
                        "applied migration {:04} differs (name={name}, checksum={applied_checksum})",
                        migration.version
                    ),
                });
            }
            None => {}
        }

        let started = Instant::now();
        let transaction = connection.transaction_with_behavior(TransactionBehavior::Immediate)?;
        transaction.execute_batch(migration.sql)?;
        let execution_ms = i64::try_from(started.elapsed().as_millis()).unwrap_or(i64::MAX);
        transaction.execute(
            "INSERT INTO schema_migrations(
                version, name, checksum_sha256, applied_at, application_version, execution_ms
             ) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                migration.version,
                migration.name,
                checksum,
                utc_now_rfc3339_millis()?,
                application_version,
                execution_ms,
            ],
        )?;
        transaction.commit()?;
        newly_applied += 1;
    }

    let applied = connection.query_row("SELECT COUNT(*) FROM schema_migrations", [], |row| {
        row.get::<_, usize>(0)
    })?;

    Ok(MigrationReport {
        available: migrations.len(),
        applied,
        newly_applied,
    })
}

fn validate_catalog(migrations: &[Migration]) -> Result<(), MigrationError> {
    for (index, migration) in migrations.iter().enumerate() {
        let expected = i64::try_from(index + 1).unwrap_or(i64::MAX);
        if migration.version != expected {
            return Err(MigrationError::Blocked {
                reason: format!(
                    "migration catalog is not contiguous: expected {expected}, found {}",
                    migration.version
                ),
            });
        }
    }
    Ok(())
}

fn validate_applied_prefix(
    connection: &Connection,
    migrations: &[Migration],
) -> Result<(), MigrationError> {
    let mut statement =
        connection.prepare("SELECT version FROM schema_migrations ORDER BY version")?;
    let versions = statement
        .query_map([], |row| row.get::<_, i64>(0))?
        .collect::<Result<Vec<_>, _>>()?;

    for (index, version) in versions.iter().enumerate() {
        let expected = i64::try_from(index + 1).unwrap_or(i64::MAX);
        if *version != expected || index >= migrations.len() {
            return Err(MigrationError::Blocked {
                reason: format!(
                    "applied migration history is not a supported prefix at version {version}"
                ),
            });
        }
    }
    Ok(())
}

fn utc_now_rfc3339_millis() -> Result<String, MigrationError> {
    let now = OffsetDateTime::now_utc();
    let value = now
        .replace_nanosecond((now.nanosecond() / 1_000_000) * 1_000_000)
        .map_err(|_| MigrationError::Timestamp)?;
    value
        .format(format_description!(
            "[year]-[month]-[day]T[hour]:[minute]:[second].[subsecond digits:3]Z"
        ))
        .map_err(|_| MigrationError::Timestamp)
}

fn sha256_hex(value: &[u8]) -> String {
    format!("{:x}", Sha256::digest(value))
}

fn normalize_sql(sql: &str) -> String {
    sql.trim()
        .trim_end_matches(';')
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn failed_migration_rolls_back_its_schema_and_version_record() {
        let mut connection = Connection::open_in_memory().unwrap();
        bootstrap(&connection).unwrap();
        let migrations = [
            Migration {
                version: 1,
                name: "first",
                sql: "CREATE TABLE first_table(id TEXT PRIMARY KEY) STRICT;",
            },
            Migration {
                version: 2,
                name: "broken",
                sql: "CREATE TABLE half_table(id TEXT PRIMARY KEY) STRICT; INVALID SQL;",
            },
        ];

        assert!(apply_migrations(&mut connection, "test", &migrations).is_err());
        let first_exists: bool = connection
            .query_row(
                "SELECT EXISTS(SELECT 1 FROM sqlite_schema WHERE name = 'first_table')",
                [],
                |row| row.get(0),
            )
            .unwrap();
        let half_exists: bool = connection
            .query_row(
                "SELECT EXISTS(SELECT 1 FROM sqlite_schema WHERE name = 'half_table')",
                [],
                |row| row.get(0),
            )
            .unwrap();
        let versions: i64 = connection
            .query_row("SELECT COUNT(*) FROM schema_migrations", [], |row| {
                row.get(0)
            })
            .unwrap();

        assert!(first_exists);
        assert!(!half_exists);
        assert_eq!(versions, 1);
    }

    #[test]
    fn a_changed_applied_migration_is_blocked() {
        let mut connection = Connection::open_in_memory().unwrap();
        bootstrap(&connection).unwrap();
        let original = [Migration {
            version: 1,
            name: "one",
            sql: "CREATE TABLE one(id TEXT PRIMARY KEY) STRICT;",
        }];
        apply_migrations(&mut connection, "test", &original).unwrap();

        let changed = [Migration {
            version: 1,
            name: "one",
            sql: "CREATE TABLE one(id TEXT PRIMARY KEY, changed TEXT) STRICT;",
        }];
        let error = apply_migrations(&mut connection, "test", &changed).unwrap_err();

        assert_eq!(error.code(), "MIGRATION_BLOCKED");
    }

    #[test]
    fn m0_m1_database_upgrades_in_order_to_m2() {
        let mut connection = Connection::open_in_memory().unwrap();
        connection
            .pragma_update(None, "foreign_keys", true)
            .unwrap();
        bootstrap(&connection).unwrap();

        let baseline = apply_migrations(&mut connection, "0.1.0", &MIGRATIONS[..2]).unwrap();
        assert_eq!(baseline.applied, 2);
        assert_eq!(baseline.newly_applied, 2);

        let upgraded = apply_migrations(&mut connection, "0.1.0", MIGRATIONS).unwrap();
        assert_eq!(upgraded.applied, 5);
        assert_eq!(upgraded.newly_applied, 3);

        let versions = connection
            .prepare("SELECT version FROM schema_migrations ORDER BY version")
            .unwrap()
            .query_map([], |row| row.get::<_, i64>(0))
            .unwrap()
            .collect::<Result<Vec<_>, _>>()
            .unwrap();
        assert_eq!(versions, vec![1, 2, 3, 4, 5]);
    }
}
