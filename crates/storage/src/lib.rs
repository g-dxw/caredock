use std::fs;
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyangtai_application::{ProbePortError, TechnicalProbePort};
use anyangtai_domain::R0ProbeReport;
use rusqlite::backup::Backup;
use rusqlite::{Connection, OptionalExtension, TransactionBehavior, params};
use sha2::{Digest, Sha256};
use thiserror::Error;

const DATABASE_FILE_NAME: &str = "r0-probe.sqlite";
const BACKUP_FILE_NAME: &str = "r0-probe-backup.sqlite";

struct ProbeMigration {
    version: i64,
    name: &'static str,
    sql: &'static str,
}

const PROBE_MIGRATIONS: &[ProbeMigration] = &[
    ProbeMigration {
        version: 1,
        name: "create_probe_tables",
        sql: r#"
            CREATE TABLE r0_probe_parent (
                id TEXT PRIMARY KEY,
                label TEXT NOT NULL
            ) STRICT;

            CREATE TABLE r0_probe_child (
                id TEXT PRIMARY KEY,
                parent_id TEXT NOT NULL,
                payload_json TEXT NOT NULL CHECK (json_valid(payload_json)),
                FOREIGN KEY (parent_id) REFERENCES r0_probe_parent(id) ON DELETE RESTRICT
            ) STRICT;

            CREATE TABLE r0_probe_audit (
                id TEXT PRIMARY KEY,
                action TEXT NOT NULL,
                payload_json TEXT NOT NULL CHECK (json_valid(payload_json))
            ) STRICT;

            CREATE TABLE r0_probe_files (
                storage_key TEXT PRIMARY KEY,
                content_sha256 TEXT NOT NULL,
                status TEXT NOT NULL CHECK (status IN ('active', 'failed'))
            ) STRICT;
        "#,
    },
    ProbeMigration {
        version: 2,
        name: "create_probe_indexes",
        sql: r#"
            CREATE INDEX ix_r0_probe_child__parent
            ON r0_probe_child(parent_id);
        "#,
    },
];

#[derive(Debug, Error)]
enum ProbeStorageError {
    #[error("sqlite probe failed")]
    Sqlite(#[from] rusqlite::Error),
    #[error("file probe failed")]
    Io(#[from] std::io::Error),
    #[error("probe migration checksum mismatch at version {0}")]
    ChecksumMismatch(i64),
    #[error("probe invariant failed: {0}")]
    Invariant(&'static str),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct MigrationResult {
    total: usize,
    newly_applied: usize,
}

pub struct SqliteTechnicalProbe {
    root_dir: PathBuf,
}

impl SqliteTechnicalProbe {
    pub fn new(root_dir: impl Into<PathBuf>) -> Self {
        Self {
            root_dir: root_dir.into(),
        }
    }

    fn execute(&self) -> Result<R0ProbeReport, ProbeStorageError> {
        fs::create_dir_all(&self.root_dir)?;
        let database_path = self.root_dir.join(DATABASE_FILE_NAME);
        let backup_path = self.root_dir.join(BACKUP_FILE_NAME);
        let mut connection = Connection::open(&database_path)?;
        connection.busy_timeout(Duration::from_secs(5))?;
        connection.pragma_update(None, "foreign_keys", true)?;

        let journal_mode: String =
            connection.query_row("PRAGMA journal_mode = WAL", [], |row| row.get(0))?;
        let foreign_keys_enabled: bool =
            connection.query_row("PRAGMA foreign_keys", [], |row| row.get(0))?;
        let sqlite_version: String =
            connection.query_row("SELECT sqlite_version()", [], |row| row.get(0))?;
        let json_supported: bool =
            connection.query_row("SELECT json_valid('{}')", [], |row| row.get(0))?;

        let first_migration_run = apply_probe_migrations(&mut connection)?;
        let second_migration_run = apply_probe_migrations(&mut connection)?;
        let strict_supported: bool = connection.query_row(
            "SELECT strict FROM pragma_table_list WHERE name = 'r0_probe_parent'",
            [],
            |row| row.get(0),
        )?;

        let transaction_rollback_verified = verify_transaction_rollback(&mut connection)?;
        let write_contention_verified = verify_write_contention(&database_path)?;
        let backup_restore_verified = verify_backup_restore(&connection, &backup_path)?;
        let attachment_two_phase_verified =
            verify_attachment_two_phase(&mut connection, &self.root_dir)?;

        Ok(R0ProbeReport {
            sqlite_version,
            foreign_keys_enabled,
            wal_enabled: journal_mode.eq_ignore_ascii_case("wal"),
            json_supported,
            strict_supported,
            migration_count: first_migration_run.total,
            migration_idempotent: second_migration_run.total == first_migration_run.total
                && second_migration_run.newly_applied == 0,
            transaction_rollback_verified,
            write_contention_verified,
            backup_restore_verified,
            attachment_two_phase_verified,
            database_path_label: DATABASE_FILE_NAME.to_owned(),
        })
    }
}

impl TechnicalProbePort for SqliteTechnicalProbe {
    fn run_probe(&self) -> Result<R0ProbeReport, ProbePortError> {
        self.execute()
            .map_err(|_| ProbePortError::storage_failure())
    }
}

fn apply_probe_migrations(
    connection: &mut Connection,
) -> Result<MigrationResult, ProbeStorageError> {
    connection.execute_batch(
        r#"
        CREATE TABLE IF NOT EXISTS schema_migrations_probe (
            version INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            checksum_sha256 TEXT NOT NULL,
            applied_at_epoch_ms INTEGER NOT NULL
        ) STRICT;
        "#,
    )?;

    let mut newly_applied = 0;
    for migration in PROBE_MIGRATIONS {
        let checksum = sha256_hex(migration.sql.as_bytes());
        let existing_checksum: Option<String> = connection
            .query_row(
                "SELECT checksum_sha256 FROM schema_migrations_probe WHERE version = ?1",
                [migration.version],
                |row| row.get(0),
            )
            .optional()?;

        match existing_checksum {
            Some(existing) if existing != checksum => {
                return Err(ProbeStorageError::ChecksumMismatch(migration.version));
            }
            Some(_) => continue,
            None => {}
        }

        let transaction = connection.transaction_with_behavior(TransactionBehavior::Immediate)?;
        transaction.execute_batch(migration.sql)?;
        transaction.execute(
            "INSERT INTO schema_migrations_probe(
                version, name, checksum_sha256, applied_at_epoch_ms
             ) VALUES (?1, ?2, ?3, ?4)",
            params![
                migration.version,
                migration.name,
                checksum,
                unix_epoch_millis()
            ],
        )?;
        transaction.commit()?;
        newly_applied += 1;
    }

    let total: usize =
        connection.query_row("SELECT COUNT(*) FROM schema_migrations_probe", [], |row| {
            row.get(0)
        })?;

    Ok(MigrationResult {
        total,
        newly_applied,
    })
}

fn verify_transaction_rollback(connection: &mut Connection) -> Result<bool, ProbeStorageError> {
    let token = format!("tx-{}-{}", std::process::id(), unix_epoch_millis());
    let transaction = connection.transaction_with_behavior(TransactionBehavior::Immediate)?;
    transaction.execute(
        "INSERT INTO r0_probe_parent(id, label) VALUES (?1, 'rollback-probe')",
        [&token],
    )?;

    if transaction
        .execute(
            "INSERT INTO r0_probe_parent(id, label) VALUES (?1, 'must-fail')",
            [&token],
        )
        .is_ok()
    {
        return Err(ProbeStorageError::Invariant(
            "duplicate primary key unexpectedly succeeded",
        ));
    }

    transaction.rollback()?;
    let remaining: usize = connection.query_row(
        "SELECT COUNT(*) FROM r0_probe_parent WHERE id = ?1",
        [&token],
        |row| row.get(0),
    )?;

    Ok(remaining == 0)
}

fn verify_write_contention(database_path: &Path) -> Result<bool, ProbeStorageError> {
    let mut first_connection = Connection::open(database_path)?;
    let second_connection = Connection::open(database_path)?;
    first_connection.busy_timeout(Duration::from_millis(100))?;
    second_connection.busy_timeout(Duration::from_millis(100))?;

    let token = format!("contention-{}-{}", std::process::id(), unix_epoch_millis());
    let first_transaction =
        first_connection.transaction_with_behavior(TransactionBehavior::Immediate)?;
    first_transaction.execute(
        "INSERT INTO r0_probe_parent(id, label) VALUES (?1, 'lock-holder')",
        [&token],
    )?;

    let blocked_while_locked = second_connection
        .execute(
            "INSERT INTO r0_probe_parent(id, label) VALUES (?1, 'must-wait')",
            [&format!("{token}-blocked")],
        )
        .is_err();
    first_transaction.rollback()?;

    let released_token = format!("{token}-released");
    let succeeds_after_release = second_connection
        .execute(
            "INSERT INTO r0_probe_parent(id, label) VALUES (?1, 'after-release')",
            [&released_token],
        )
        .is_ok();
    second_connection.execute(
        "DELETE FROM r0_probe_parent WHERE id = ?1",
        [&released_token],
    )?;

    Ok(blocked_while_locked && succeeds_after_release)
}

fn verify_backup_restore(
    connection: &Connection,
    backup_path: &Path,
) -> Result<bool, ProbeStorageError> {
    remove_sqlite_files(backup_path)?;
    let mut destination = Connection::open(backup_path)?;
    {
        let backup = Backup::new(connection, &mut destination)?;
        backup.run_to_completion(5, Duration::from_millis(10), None)?;
    }
    drop(destination);

    let restored = Connection::open(backup_path)?;
    let migration_count: usize =
        restored.query_row("SELECT COUNT(*) FROM schema_migrations_probe", [], |row| {
            row.get(0)
        })?;
    let integrity: String = restored.query_row("PRAGMA integrity_check", [], |row| row.get(0))?;

    Ok(migration_count == PROBE_MIGRATIONS.len() && integrity == "ok")
}

fn verify_attachment_two_phase(
    connection: &mut Connection,
    root_dir: &Path,
) -> Result<bool, ProbeStorageError> {
    let staging_dir = root_dir.join("attachment-staging");
    let final_dir = root_dir.join("attachments");
    fs::create_dir_all(&staging_dir)?;
    fs::create_dir_all(&final_dir)?;

    connection.execute(
        "DELETE FROM r0_probe_files WHERE storage_key IN ('success.txt', 'failure.txt')",
        [],
    )?;

    let success_stage = staging_dir.join("success.tmp");
    let success_final = final_dir.join("success.txt");
    remove_if_exists(&success_stage)?;
    remove_if_exists(&success_final)?;
    let success_content = b"anyangtai-r0-anonymous-attachment";
    fs::write(&success_stage, success_content)?;
    let success_hash = sha256_hex(success_content);
    fs::rename(&success_stage, &success_final)?;

    let success_transaction =
        connection.transaction_with_behavior(TransactionBehavior::Immediate)?;
    if let Err(error) = success_transaction.execute(
        "INSERT INTO r0_probe_files(storage_key, content_sha256, status)
         VALUES ('success.txt', ?1, 'active')",
        [&success_hash],
    ) {
        remove_if_exists(&success_final)?;
        return Err(error.into());
    }
    if let Err(error) = success_transaction.commit() {
        remove_if_exists(&success_final)?;
        return Err(error.into());
    }

    let failure_stage = staging_dir.join("failure.tmp");
    let failure_final = final_dir.join("failure.txt");
    remove_if_exists(&failure_stage)?;
    remove_if_exists(&failure_final)?;
    let failure_content = b"anyangtai-r0-failure-injection";
    fs::write(&failure_stage, failure_content)?;
    let failure_hash = sha256_hex(failure_content);
    fs::rename(&failure_stage, &failure_final)?;

    let failure_transaction =
        connection.transaction_with_behavior(TransactionBehavior::Immediate)?;
    failure_transaction.execute(
        "INSERT INTO r0_probe_files(storage_key, content_sha256, status)
         VALUES ('failure.txt', ?1, 'active')",
        [&failure_hash],
    )?;
    failure_transaction.rollback()?;
    remove_if_exists(&failure_final)?;

    let success_row: usize = connection.query_row(
        "SELECT COUNT(*) FROM r0_probe_files
         WHERE storage_key = 'success.txt' AND content_sha256 = ?1 AND status = 'active'",
        [&success_hash],
        |row| row.get(0),
    )?;
    let failure_row: usize = connection.query_row(
        "SELECT COUNT(*) FROM r0_probe_files WHERE storage_key = 'failure.txt'",
        [],
        |row| row.get(0),
    )?;

    Ok(success_row == 1
        && success_final.exists()
        && failure_row == 0
        && !failure_final.exists()
        && !failure_stage.exists())
}

fn sha256_hex(value: &[u8]) -> String {
    format!("{:x}", Sha256::digest(value))
}

fn unix_epoch_millis() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis()
        .try_into()
        .unwrap_or(i64::MAX)
}

fn remove_sqlite_files(path: &Path) -> Result<(), std::io::Error> {
    remove_if_exists(path)?;
    remove_if_exists(&PathBuf::from(format!("{}-shm", path.display())))?;
    remove_if_exists(&PathBuf::from(format!("{}-wal", path.display())))
}

fn remove_if_exists(path: &Path) -> Result<(), std::io::Error> {
    match fs::remove_file(path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn full_probe_verifies_sqlite_transactions_backup_and_files() {
        let temp = tempfile::tempdir().unwrap();
        let probe = SqliteTechnicalProbe::new(temp.path());

        let report = probe.run_probe().unwrap();

        assert!(report.foreign_keys_enabled);
        assert!(report.wal_enabled);
        assert!(report.json_supported);
        assert!(report.strict_supported);
        assert_eq!(report.migration_count, 2);
        assert!(report.migration_idempotent);
        assert!(report.transaction_rollback_verified);
        assert!(report.write_contention_verified);
        assert!(report.backup_restore_verified);
        assert!(report.attachment_two_phase_verified);
        assert_eq!(report.database_path_label, DATABASE_FILE_NAME);
    }

    #[test]
    fn changed_applied_migration_checksum_is_blocked_and_masked() {
        let temp = tempfile::tempdir().unwrap();
        let probe = SqliteTechnicalProbe::new(temp.path());
        probe.run_probe().unwrap();

        let database_path = temp.path().join(DATABASE_FILE_NAME);
        let connection = Connection::open(database_path).unwrap();
        connection
            .execute(
                "UPDATE schema_migrations_probe SET checksum_sha256 = 'tampered' WHERE version = 1",
                [],
            )
            .unwrap();

        let error = probe.run_probe().unwrap_err();
        assert_eq!(error.code, "STORAGE_FAILURE");
        assert!(!error.safe_message.contains("checksum"));
        assert!(
            !error
                .safe_message
                .contains(temp.path().to_string_lossy().as_ref())
        );
    }
}
