use std::fs;
use std::path::{Path, PathBuf};
use std::time::Duration;

use rusqlite::Connection;

use crate::capability_probe::{self, SqliteCapabilities};
use crate::migration::{self, MigrationError, MigrationReport};

pub const FORMAL_DATABASE_FILE_NAME: &str = "anyangtai.sqlite";

pub struct FormalDatabase {
    path: PathBuf,
    _connection: Connection,
    capabilities: SqliteCapabilities,
    migration_report: MigrationReport,
}

impl FormalDatabase {
    pub fn open(data_dir: impl AsRef<Path>) -> Result<Self, MigrationError> {
        fs::create_dir_all(data_dir.as_ref())?;
        let path = data_dir.as_ref().join(FORMAL_DATABASE_FILE_NAME);
        let mut connection = Connection::open(&path)?;
        configure_connection(&connection)?;
        let capabilities = capability_probe::probe(&connection)?;
        let migration_report = migration::migrate(&mut connection, env!("CARGO_PKG_VERSION"))?;

        Ok(Self {
            path,
            _connection: connection,
            capabilities,
            migration_report,
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
}

fn configure_connection(connection: &Connection) -> Result<(), MigrationError> {
    connection.busy_timeout(Duration::from_secs(5))?;
    connection.pragma_update(None, "foreign_keys", true)?;
    connection.pragma_update(None, "journal_mode", "WAL")?;
    connection.pragma_update(None, "synchronous", "FULL")?;
    Ok(())
}
