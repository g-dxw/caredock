use rusqlite::Connection;

use crate::migration::MigrationError;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SqliteCapabilities {
    pub sqlite_version: String,
    pub foreign_keys_enabled: bool,
    pub wal_enabled: bool,
    pub json_supported: bool,
    pub strict_supported: bool,
}

pub(crate) fn probe(connection: &Connection) -> Result<SqliteCapabilities, MigrationError> {
    let sqlite_version =
        connection.query_row("SELECT sqlite_version()", [], |row| row.get::<_, String>(0))?;
    let foreign_keys_enabled =
        connection.query_row("PRAGMA foreign_keys", [], |row| row.get::<_, bool>(0))?;
    let journal_mode =
        connection.query_row("PRAGMA journal_mode", [], |row| row.get::<_, String>(0))?;
    let wal_enabled = journal_mode.eq_ignore_ascii_case("wal");
    let json_supported = connection
        .query_row("SELECT json_valid('{\"probe\":true}')", [], |row| {
            row.get::<_, bool>(0)
        })
        .unwrap_or(false);

    let strict_supported = connection
        .execute_batch(
            "CREATE TEMP TABLE __anyangtai_strict_probe(value TEXT NOT NULL) STRICT;\
             DROP TABLE __anyangtai_strict_probe;",
        )
        .is_ok();

    if !foreign_keys_enabled {
        return Err(MigrationError::CapabilityMissing("foreign_keys"));
    }
    if !wal_enabled {
        return Err(MigrationError::CapabilityMissing("WAL journal mode"));
    }
    if !json_supported {
        return Err(MigrationError::CapabilityMissing("json_valid"));
    }
    if !strict_supported {
        return Err(MigrationError::CapabilityMissing("STRICT tables"));
    }

    Ok(SqliteCapabilities {
        sqlite_version,
        foreign_keys_enabled,
        wal_enabled,
        json_supported,
        strict_supported,
    })
}
