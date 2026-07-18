use std::fs;
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use rusqlite::Connection;
use rusqlite::backup::Backup;

use crate::migration::MigrationError;

pub(crate) fn create_pre_upgrade_backup(
    source: &Connection,
    data_dir: &Path,
    from_version: i64,
    to_version: i64,
) -> Result<PathBuf, MigrationError> {
    let backup_dir = data_dir.join("backups");
    fs::create_dir_all(&backup_dir)?;
    let token = unix_epoch_millis();
    let file_name = format!(
        "pre-upgrade-v{from_version:04}-to-v{to_version:04}-{token}-{}.sqlite",
        std::process::id()
    );
    let final_path = backup_dir.join(file_name);
    let partial_path = PathBuf::from(format!("{}.partial", final_path.display()));

    let result = create_and_verify(source, &partial_path, from_version);
    if let Err(error) = result {
        remove_if_exists(&partial_path)?;
        return Err(error);
    }
    fs::rename(&partial_path, &final_path)?;
    Ok(final_path)
}

fn create_and_verify(
    source: &Connection,
    destination_path: &Path,
    expected_version: i64,
) -> Result<(), MigrationError> {
    remove_if_exists(destination_path)?;
    let mut destination = Connection::open(destination_path)?;
    {
        let backup = Backup::new(source, &mut destination)?;
        backup.run_to_completion(16, Duration::from_millis(10), None)?;
    }
    drop(destination);

    let verification = Connection::open(destination_path)?;
    let integrity: String =
        verification.query_row("PRAGMA integrity_check", [], |row| row.get(0))?;
    let version: i64 = verification.query_row(
        "SELECT COALESCE(MAX(version), 0) FROM schema_migrations",
        [],
        |row| row.get(0),
    )?;
    if integrity != "ok" || version != expected_version {
        return Err(MigrationError::BackupVerification);
    }
    Ok(())
}

fn unix_epoch_millis() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis()
}

fn remove_if_exists(path: &Path) -> Result<(), std::io::Error> {
    match fs::remove_file(path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error),
    }
}
