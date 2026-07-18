use anyangtai_application::TechnicalProbePort;
use anyangtai_storage::{FORMAL_DATABASE_FILE_NAME, FormalDatabase, SqliteTechnicalProbe};
use rusqlite::{Connection, params};
use sha2::{Digest, Sha256};

const INSTITUTION_ID: &str = "01J00000000000000000000000";
const ATTACHMENT_ID: &str = "01J00000000000000000000001";
const AUDIT_ID: &str = "01J00000000000000000000002";
const NOW: &str = "2026-07-18T01:30:00.000Z";

#[test]
fn first_install_and_reopen_are_ordered_and_idempotent() {
    let temp = tempfile::tempdir().unwrap();
    let first = FormalDatabase::open(temp.path()).unwrap();

    assert_eq!(first.path(), temp.path().join(FORMAL_DATABASE_FILE_NAME));
    assert!(first.capabilities().foreign_keys_enabled);
    assert!(first.capabilities().wal_enabled);
    assert!(first.capabilities().json_supported);
    assert!(first.capabilities().strict_supported);
    assert_eq!(first.migration_report().available, 2);
    assert_eq!(first.migration_report().applied, 2);
    assert_eq!(first.migration_report().newly_applied, 2);
    drop(first);

    let second = FormalDatabase::open(temp.path()).unwrap();
    assert_eq!(second.migration_report().applied, 2);
    assert_eq!(second.migration_report().newly_applied, 0);
    let connection = open_test_connection(second.path());

    let versions = connection
        .prepare("SELECT version, name FROM schema_migrations ORDER BY version")
        .unwrap()
        .query_map([], |row| {
            Ok((row.get::<_, i64>(0)?, row.get::<_, String>(1)?))
        })
        .unwrap()
        .collect::<Result<Vec<_>, _>>()
        .unwrap();
    assert_eq!(
        versions,
        vec![
            (1, "schema_metadata_and_institution".to_owned()),
            (2, "attachments_and_audit".to_owned()),
        ]
    );
}

#[test]
fn altered_applied_checksum_blocks_reopen() {
    let temp = tempfile::tempdir().unwrap();
    let database = FormalDatabase::open(temp.path()).unwrap();
    let connection = open_test_connection(database.path());
    connection
        .execute(
            "UPDATE schema_migrations SET checksum_sha256 = ?1 WHERE version = 1",
            ["0".repeat(64)],
        )
        .unwrap();
    drop(database);

    let error = FormalDatabase::open(temp.path()).err().unwrap();
    assert_eq!(error.code(), "MIGRATION_BLOCKED");
}

#[test]
fn constraints_foreign_keys_and_integrity_protect_the_first_tables() {
    let temp = tempfile::tempdir().unwrap();
    let database = FormalDatabase::open(temp.path()).unwrap();
    let connection = open_test_connection(database.path());
    insert_institution(&connection, INSTITUTION_ID, "ORG-001").unwrap();

    assert!(insert_institution(&connection, "short", "ORG-002").is_err());
    assert!(insert_institution(&connection, "01J00000000000000000000003", "ORG-001").is_err());

    let invalid_time = connection.execute(
        "UPDATE institutions SET updated_at = '2026-07-18 01:30:00' WHERE id = ?1",
        [INSTITUTION_ID],
    );
    assert!(invalid_time.is_err());

    insert_attachment(&connection, ATTACHMENT_ID, INSTITUTION_ID).unwrap();
    assert!(
        insert_attachment(
            &connection,
            "01J00000000000000000000004",
            "01J00000000000000000000999"
        )
        .is_err()
    );
    assert!(
        connection
            .execute(
                "UPDATE attachments SET file_size_bytes = -1 WHERE id = ?1",
                [ATTACHMENT_ID],
            )
            .is_err()
    );
    assert!(
        connection
            .execute(
                "UPDATE attachments SET content_hash_sha256 = 'ABC' WHERE id = ?1",
                [ATTACHMENT_ID],
            )
            .is_err()
    );

    insert_audit(&connection, AUDIT_ID, "create").unwrap();
    assert!(insert_audit(&connection, "01J00000000000000000000005", "delete").is_err());

    let foreign_key_violations: i64 = connection
        .query_row("SELECT COUNT(*) FROM pragma_foreign_key_check", [], |row| {
            row.get(0)
        })
        .unwrap();
    let integrity: String = connection
        .query_row("PRAGMA integrity_check", [], |row| row.get(0))
        .unwrap();
    assert_eq!(foreign_key_violations, 0);
    assert_eq!(integrity, "ok");
}

#[test]
fn formal_schema_matches_the_reviewed_snapshot() {
    let temp = tempfile::tempdir().unwrap();
    let database = FormalDatabase::open(temp.path()).unwrap();
    let connection = open_test_connection(database.path());
    let actual = schema_snapshot(&connection);
    let expected = include_str!("snapshots/m0_m1_schema.snapshot").trim();

    assert_eq!(actual, expected);
}

#[test]
fn formal_database_and_r0_probe_remain_isolated() {
    let temp = tempfile::tempdir().unwrap();
    let formal = FormalDatabase::open(temp.path()).unwrap();
    let probe = SqliteTechnicalProbe::new(temp.path());
    probe.run_probe().unwrap();

    let formal_connection = open_test_connection(formal.path());
    let formal_has_probe_table: bool = formal_connection
        .query_row(
            "SELECT EXISTS(SELECT 1 FROM sqlite_schema WHERE name = 'r0_probe_parent')",
            [],
            |row| row.get(0),
        )
        .unwrap();
    let probe_connection = Connection::open(temp.path().join("r0-probe.sqlite")).unwrap();
    let probe_has_formal_table: bool = probe_connection
        .query_row(
            "SELECT EXISTS(SELECT 1 FROM sqlite_schema WHERE name = 'institutions')",
            [],
            |row| row.get(0),
        )
        .unwrap();

    assert!(!formal_has_probe_table);
    assert!(!probe_has_formal_table);
}

fn open_test_connection(path: &std::path::Path) -> Connection {
    let connection = Connection::open(path).unwrap();
    connection
        .pragma_update(None, "foreign_keys", true)
        .unwrap();
    connection
}

fn insert_institution(
    connection: &Connection,
    id: &str,
    institution_code: &str,
) -> rusqlite::Result<usize> {
    connection.execute(
        "INSERT INTO institutions(
            id, created_at, created_by_staff_id, created_source, updated_at,
            updated_by_staff_id, record_version, institution_code, name, short_name,
            registration_type, ownership_nature, operation_mode,
            legal_representative_name, contact_phone, province_code, city_code,
            district_code, address_detail, postal_code, status, initialized_at
         ) VALUES (
            ?1, ?2, NULL, 'manual', ?2, NULL, 1, ?3, '安养台测试机构', NULL,
            'enterprise', 'private_nonprofit', 'self_operated', NULL,
            '010-12345678', '41', '4101', '410102', '测试路1号', NULL, 'active', ?2
         )",
        params![id, NOW, institution_code],
    )
}

fn insert_attachment(
    connection: &Connection,
    id: &str,
    institution_id: &str,
) -> rusqlite::Result<usize> {
    connection.execute(
        "INSERT INTO attachments(
            id, institution_id, created_at, created_by_staff_id, created_source,
            updated_at, updated_by_staff_id, record_version, attachment_code,
            original_file_name, media_type, file_size_bytes, content_hash_sha256,
            local_storage_key, sensitivity_level, captured_at, uploaded_at, status
         ) VALUES (
            ?1, ?2, ?3, NULL, 'manual', ?3, NULL, 1, ?4,
            'license.pdf', 'application/pdf', 128, ?5,
            ?6, 'L2', NULL, ?3, 'active'
         )",
        params![
            id,
            institution_id,
            NOW,
            format!("ATT-{}", &id[23.min(id.len())..]),
            "a".repeat(64),
            format!("documents/{id}.pdf"),
        ],
    )
}

fn insert_audit(connection: &Connection, id: &str, action: &str) -> rusqlite::Result<usize> {
    connection.execute(
        "INSERT INTO audit_events(
            id, institution_id, occurred_at, operator_staff_id, event_source,
            action, target_type, target_id, summary, before_digest, after_digest, reason
         ) VALUES (?1, ?2, ?3, NULL, 'user', ?4, 'institution', ?2, ?5, NULL, NULL, NULL)",
        params![
            id,
            INSTITUTION_ID,
            NOW,
            action,
            format!("audit action: {action}")
        ],
    )
}

fn schema_snapshot(connection: &Connection) -> String {
    let tables = connection
        .prepare(
            "SELECT name, sql FROM sqlite_schema
             WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
             ORDER BY name",
        )
        .unwrap()
        .query_map([], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
        })
        .unwrap()
        .collect::<Result<Vec<_>, _>>()
        .unwrap();
    let mut lines = Vec::new();

    for (table, sql) in tables {
        let strict: bool = connection
            .query_row(
                "SELECT strict FROM pragma_table_list WHERE name = ?1",
                [&table],
                |row| row.get(0),
            )
            .unwrap();
        lines.push(format!(
            "TABLE {table} strict={} sql_sha256={:x}",
            i32::from(strict),
            Sha256::digest(sql.as_bytes())
        ));

        let escaped_table = table.replace('"', "\"\"");
        let columns = connection
            .prepare(&format!("PRAGMA table_xinfo(\"{escaped_table}\")"))
            .unwrap()
            .query_map([], |row| {
                Ok(format!(
                    "  COLUMN {} {} not_null={} default={} pk={} hidden={}",
                    row.get::<_, String>(1)?,
                    row.get::<_, String>(2)?,
                    row.get::<_, bool>(3)? as i32,
                    row.get::<_, Option<String>>(4)?
                        .unwrap_or_else(|| "NULL".to_owned()),
                    row.get::<_, i32>(5)?,
                    row.get::<_, i32>(6)?,
                ))
            })
            .unwrap()
            .collect::<Result<Vec<_>, _>>()
            .unwrap();
        lines.extend(columns);

        let foreign_keys = connection
            .prepare(&format!("PRAGMA foreign_key_list(\"{escaped_table}\")"))
            .unwrap()
            .query_map([], |row| {
                Ok(format!(
                    "  FK {} -> {}.{} on_update={} on_delete={}",
                    row.get::<_, String>(3)?,
                    row.get::<_, String>(2)?,
                    row.get::<_, String>(4)?,
                    row.get::<_, String>(5)?,
                    row.get::<_, String>(6)?,
                ))
            })
            .unwrap()
            .collect::<Result<Vec<_>, _>>()
            .unwrap();
        lines.extend(foreign_keys);
    }

    lines.join("\n")
}
