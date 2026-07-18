use std::fs;
use std::path::{Path, PathBuf};
use std::time::Duration;

use rusqlite::Connection;

use crate::backup;
use crate::capability_probe::{self, SqliteCapabilities};
use crate::migration::{self, MigrationError, MigrationReport};

pub const FORMAL_DATABASE_FILE_NAME: &str = "anyangtai.sqlite";

pub struct FormalDatabase {
    path: PathBuf,
    _connection: Connection,
    capabilities: SqliteCapabilities,
    migration_report: MigrationReport,
    pre_upgrade_backup_path: Option<PathBuf>,
}

impl FormalDatabase {
    pub fn open(data_dir: impl AsRef<Path>) -> Result<Self, MigrationError> {
        fs::create_dir_all(data_dir.as_ref())?;
        let path = data_dir.as_ref().join(FORMAL_DATABASE_FILE_NAME);
        let mut connection = Connection::open(&path)?;
        configure_connection(&connection)?;
        let capabilities = capability_probe::probe(&connection)?;
        migration::bootstrap(&connection)?;
        let current_version = migration::current_version(&connection)?;
        let latest_version = migration::latest_version();
        let pre_upgrade_backup_path = match current_version {
            Some(version) if version > 0 && version < latest_version => {
                Some(backup::create_pre_upgrade_backup(
                    &connection,
                    data_dir.as_ref(),
                    version,
                    latest_version,
                )?)
            }
            _ => None,
        };
        let migration_report = migration::migrate(&mut connection, env!("CARGO_PKG_VERSION"))?;

        Ok(Self {
            path,
            _connection: connection,
            capabilities,
            migration_report,
            pre_upgrade_backup_path,
        })
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn capabilities(&self) -> &SqliteCapabilities {
        &self.capabilities
    }

    pub fn migration_report(&self) -> MigrationReport {
        self.migration_report
    }

    pub fn pre_upgrade_backup_path(&self) -> Option<&Path> {
        self.pre_upgrade_backup_path.as_deref()
    }
}

fn configure_connection(connection: &Connection) -> Result<(), MigrationError> {
    connection.busy_timeout(Duration::from_secs(5))?;
    connection.pragma_update(None, "foreign_keys", true)?;
    connection.pragma_update(None, "journal_mode", "WAL")?;
    connection.pragma_update(None, "synchronous", "FULL")?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::migration::{MIGRATIONS, apply_migrations, bootstrap};

    fn create_m0_m1_database(root: &Path) {
        let database_path = root.join(FORMAL_DATABASE_FILE_NAME);
        let mut baseline = Connection::open(&database_path).unwrap();
        configure_connection(&baseline).unwrap();
        bootstrap(&baseline).unwrap();
        apply_migrations(&mut baseline, "0.1.0", &MIGRATIONS[..2]).unwrap();
    }

    #[test]
    fn upgrading_an_m0_m1_file_creates_and_verifies_a_pre_upgrade_backup() {
        let temp = tempfile::tempdir().unwrap();
        create_m0_m1_database(temp.path());

        let upgraded = FormalDatabase::open(temp.path()).unwrap();
        let backup_path = upgraded.pre_upgrade_backup_path().unwrap();
        assert!(backup_path.exists());
        assert_eq!(upgraded.migration_report().applied, 7);

        let backup = Connection::open(backup_path).unwrap();
        let backup_version: i64 = backup
            .query_row("SELECT MAX(version) FROM schema_migrations", [], |row| {
                row.get(0)
            })
            .unwrap();
        let has_staff_table: bool = backup
            .query_row(
                "SELECT EXISTS(SELECT 1 FROM sqlite_schema WHERE name = 'staff_members')",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(backup_version, 2);
        assert!(!has_staff_table);
    }

    #[test]
    fn upgrading_an_m2_file_backs_up_version_five_before_m3() {
        let temp = tempfile::tempdir().unwrap();
        let database_path = temp.path().join(FORMAL_DATABASE_FILE_NAME);
        let mut baseline = Connection::open(&database_path).unwrap();
        configure_connection(&baseline).unwrap();
        bootstrap(&baseline).unwrap();
        apply_migrations(&mut baseline, "0.1.0", &MIGRATIONS[..5]).unwrap();
        drop(baseline);

        let upgraded = FormalDatabase::open(temp.path()).unwrap();
        let backup_path = upgraded.pre_upgrade_backup_path().unwrap();
        let backup = Connection::open(backup_path).unwrap();
        let backup_version: i64 = backup
            .query_row("SELECT MAX(version) FROM schema_migrations", [], |row| {
                row.get(0)
            })
            .unwrap();
        let has_service_catalog: bool = backup
            .query_row(
                "SELECT EXISTS(SELECT 1 FROM sqlite_schema WHERE name = 'service_items')",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(backup_version, 5);
        assert!(!has_service_catalog);
        assert_eq!(upgraded.migration_report().applied, 7);
    }

    #[test]
    fn upgrading_an_m3_file_backs_up_version_six_before_m4() {
        let temp = tempfile::tempdir().unwrap();
        let database_path = temp.path().join(FORMAL_DATABASE_FILE_NAME);
        let mut baseline = Connection::open(&database_path).unwrap();
        configure_connection(&baseline).unwrap();
        bootstrap(&baseline).unwrap();
        apply_migrations(&mut baseline, "0.1.0", &MIGRATIONS[..6]).unwrap();
        drop(baseline);

        let upgraded = FormalDatabase::open(temp.path()).unwrap();
        let backup_path = upgraded.pre_upgrade_backup_path().unwrap();
        let backup = Connection::open(backup_path).unwrap();
        let backup_version: i64 = backup
            .query_row("SELECT MAX(version) FROM schema_migrations", [], |row| {
                row.get(0)
            })
            .unwrap();
        let has_relationships: bool = backup
            .query_row(
                "SELECT EXISTS(SELECT 1 FROM sqlite_schema WHERE name = 'service_relationships')",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(backup_version, 6);
        assert!(!has_relationships);
        assert_eq!(upgraded.migration_report().applied, 7);
    }

    #[test]
    fn a_backup_failure_prevents_any_upgrade_migration() {
        let temp = tempfile::tempdir().unwrap();
        create_m0_m1_database(temp.path());
        fs::write(temp.path().join("backups"), b"blocks backup directory").unwrap();

        let error = FormalDatabase::open(temp.path()).err().unwrap();
        assert_eq!(error.code(), "STORAGE_FAILURE");

        let database = Connection::open(temp.path().join(FORMAL_DATABASE_FILE_NAME)).unwrap();
        let version: i64 = database
            .query_row("SELECT MAX(version) FROM schema_migrations", [], |row| {
                row.get(0)
            })
            .unwrap();
        let has_staff_table: bool = database
            .query_row(
                "SELECT EXISTS(SELECT 1 FROM sqlite_schema WHERE name = 'staff_members')",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(version, 2);
        assert!(!has_staff_table);
    }
}
