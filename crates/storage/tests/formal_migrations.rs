use anyangtai_application::TechnicalProbePort;
use anyangtai_storage::{FORMAL_DATABASE_FILE_NAME, FormalDatabase, SqliteTechnicalProbe};
use rusqlite::{Connection, params};
use sha2::{Digest, Sha256};

const INSTITUTION_ID: &str = "01J00000000000000000000000";
const ATTACHMENT_ID: &str = "01J00000000000000000000001";
const AUDIT_ID: &str = "01J00000000000000000000002";
const STAFF_ID: &str = "01J00000000000000000000010";
const SITE_ID: &str = "01J00000000000000000000011";
const SPACE_ID: &str = "01J00000000000000000000012";
const POSITION_ID: &str = "01J00000000000000000000013";
const DAY_AREA_ID: &str = "01J00000000000000000000014";
const HOME_AREA_ID: &str = "01J00000000000000000000015";
const SITE_ASSIGNMENT_ID: &str = "01J00000000000000000000016";
const SERVICE_ITEM_ID: &str = "01J00000000000000000000030";
const CHARGE_ITEM_ID: &str = "01J00000000000000000000031";
const PRICE_PLAN_ID: &str = "01J00000000000000000000032";
const PACKAGE_TEMPLATE_ID: &str = "01J00000000000000000000033";
const PACKAGE_VERSION_ID: &str = "01J00000000000000000000034";
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
    assert_eq!(first.migration_report().available, 6);
    assert_eq!(first.migration_report().applied, 6);
    assert_eq!(first.migration_report().newly_applied, 6);
    assert!(first.pre_upgrade_backup_path().is_none());
    drop(first);

    let second = FormalDatabase::open(temp.path()).unwrap();
    assert_eq!(second.migration_report().applied, 6);
    assert_eq!(second.migration_report().newly_applied, 0);
    assert!(second.pre_upgrade_backup_path().is_none());
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
            (3, "staff_and_organization".to_owned()),
            (4, "institution_sites_and_resources".to_owned()),
            (5, "staff_site_assignments".to_owned()),
            (6, "service_catalog_pricing_and_packages".to_owned()),
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
    let expected = include_str!("snapshots/m0_m3_schema.snapshot").trim();

    assert_eq!(actual, expected);
}

#[test]
fn m2_staff_site_and_resource_constraints_form_a_valid_chain() {
    let temp = tempfile::tempdir().unwrap();
    let database = FormalDatabase::open(temp.path()).unwrap();
    let connection = open_test_connection(database.path());
    insert_institution(&connection, INSTITUTION_ID, "ORG-M2").unwrap();
    insert_staff(&connection, STAFF_ID, INSTITUTION_ID, "STAFF-001").unwrap();

    connection
        .execute(
            "INSERT INTO departments(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, parent_id,
                department_code, name, manager_staff_id, sort_order, status
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, NULL,
                'CARE', '照护部', ?4, 0, 'active')",
            params!["01J00000000000000000000017", INSTITUTION_ID, NOW, STAFF_ID],
        )
        .unwrap();
    connection
        .execute(
            "INSERT INTO employment_periods(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, staff_id,
                employment_type, start_date, end_date, status, employer_name, personnel_note
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?4,
                'formal', '2026-01-01', NULL, 'active', NULL, NULL)",
            params!["01J00000000000000000000018", INSTITUTION_ID, NOW, STAFF_ID],
        )
        .unwrap();
    assert!(
        connection
            .execute(
                "INSERT INTO employment_periods(
                    id, institution_id, created_at, created_source, updated_at, record_version,
                    staff_id, employment_type, start_date, end_date, status
                 ) VALUES (?1, ?2, ?3, 'manual', ?3, 1, ?4, 'formal',
                    '2026-02-01', NULL, 'ended')",
                params!["01J00000000000000000000019", INSTITUTION_ID, NOW, STAFF_ID],
            )
            .is_err()
    );

    connection
        .execute(
            "INSERT INTO institution_capabilities(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, capability_type,
                enabled, declared_capacity, policy_notice_code, policy_notice_seen_at,
                institution_note
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1,
                'day', 1, 10, 'POLICY-1', ?3, NULL)",
            params!["01J00000000000000000000020", INSTITUTION_ID, NOW, STAFF_ID],
        )
        .unwrap();
    assert!(
        connection
            .execute(
                "INSERT INTO institution_capabilities(
                    id, institution_id, created_at, created_source, updated_at, record_version,
                    capability_type, enabled, declared_capacity
                 ) VALUES (?1, ?2, ?3, 'manual', ?3, 1, 'home', 1, 1)",
                params!["01J00000000000000000000021", INSTITUTION_ID, NOW],
            )
            .is_err()
    );

    insert_site(
        &connection,
        SITE_ID,
        INSTITUTION_ID,
        STAFF_ID,
        1,
        "SITE-001",
    )
    .unwrap();
    connection
        .execute(
            "INSERT INTO service_site_scenes(
                institution_id, created_at, created_by_staff_id, created_source,
                service_site_id, scene
             ) VALUES (?1, ?2, ?3, 'manual', ?4, 'day')",
            params![INSTITUTION_ID, NOW, STAFF_ID, SITE_ID],
        )
        .unwrap();
    assert!(
        insert_site(
            &connection,
            "01J00000000000000000000022",
            INSTITUTION_ID,
            STAFF_ID,
            1,
            "SITE-002"
        )
        .is_err()
    );

    connection
        .execute(
            "INSERT INTO space_nodes(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, site_id, parent_id,
                node_type, space_code, name, sort_order, status
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, NULL,
                'room', 'R-101', '101室', 0, 'active')",
            params![SPACE_ID, INSTITUTION_ID, NOW, STAFF_ID, SITE_ID],
        )
        .unwrap();
    connection
        .execute(
            "INSERT INTO accommodation_positions(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, site_id, space_node_id,
                position_code, name, primary_use, respite_eligible,
                occupancy_gender_rule, status, status_note
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, ?6,
                'BED-01', '101-1床', 'residential_bed', 1, 'none', 'active', NULL)",
            params![
                POSITION_ID,
                INSTITUTION_ID,
                NOW,
                STAFF_ID,
                SITE_ID,
                SPACE_ID
            ],
        )
        .unwrap();
    connection
        .execute(
            "INSERT INTO accommodation_position_features(
                institution_id, created_at, created_by_staff_id, created_source,
                accommodation_position_id, feature_value
             ) VALUES (?1, ?2, ?3, 'manual', ?4, '靠近护理站')",
            params![INSTITUTION_ID, NOW, STAFF_ID, POSITION_ID],
        )
        .unwrap();
    connection
        .execute(
            "INSERT INTO day_care_areas(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, site_id, space_node_id,
                area_code, name, capacity, numbered_rest_positions, status
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, ?6,
                'DAY-01', '日间活动区', 10, 1, 'active')",
            params![
                DAY_AREA_ID,
                INSTITUTION_ID,
                NOW,
                STAFF_ID,
                SITE_ID,
                SPACE_ID
            ],
        )
        .unwrap();

    connection
        .execute(
            "INSERT INTO home_service_areas(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, site_id, area_code,
                name, province_code, city_code, boundary_description, travel_note, status
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, 'HOME-01',
                '中心城区', '41', '4101', '站点周边五公里', NULL, 'active')",
            params![HOME_AREA_ID, INSTITUTION_ID, NOW, STAFF_ID, SITE_ID],
        )
        .unwrap();
    connection
        .execute(
            "INSERT INTO home_service_area_districts(
                institution_id, created_at, created_by_staff_id, created_source,
                home_service_area_id, district_code
             ) VALUES (?1, ?2, ?3, 'manual', ?4, '410102')",
            params![INSTITUTION_ID, NOW, STAFF_ID, HOME_AREA_ID],
        )
        .unwrap();

    connection
        .execute(
            "INSERT INTO site_assignments(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, staff_id, site_id,
                is_primary, effective_from_date, effective_to_date
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?4, ?5,
                1, '2026-01-01', NULL)",
            params![SITE_ASSIGNMENT_ID, INSTITUTION_ID, NOW, STAFF_ID, SITE_ID],
        )
        .unwrap();
    connection
        .execute(
            "INSERT INTO site_assignment_scenes(
                institution_id, created_at, created_by_staff_id, created_source,
                site_assignment_id, scene
             ) VALUES (?1, ?2, ?3, 'manual', ?4, 'day')",
            params![INSTITUTION_ID, NOW, STAFF_ID, SITE_ASSIGNMENT_ID],
        )
        .unwrap();
    connection
        .execute(
            "DELETE FROM site_assignments WHERE id = ?1",
            [SITE_ASSIGNMENT_ID],
        )
        .unwrap();
    let remaining_assignment_scenes: i64 = connection
        .query_row(
            "SELECT COUNT(*) FROM site_assignment_scenes WHERE site_assignment_id = ?1",
            [SITE_ASSIGNMENT_ID],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(remaining_assignment_scenes, 0);

    let integrity: String = connection
        .query_row("PRAGMA integrity_check", [], |row| row.get(0))
        .unwrap();
    let foreign_key_violations: i64 = connection
        .query_row("SELECT COUNT(*) FROM pragma_foreign_key_check", [], |row| {
            row.get(0)
        })
        .unwrap();
    assert_eq!(integrity, "ok");
    assert_eq!(foreign_key_violations, 0);
}

#[test]
fn m3_catalog_pricing_and_package_constraints_preserve_the_three_layers() {
    let temp = tempfile::tempdir().unwrap();
    let database = FormalDatabase::open(temp.path()).unwrap();
    let connection = open_test_connection(database.path());
    insert_institution(&connection, INSTITUTION_ID, "ORG-M3").unwrap();
    insert_staff(&connection, STAFF_ID, INSTITUTION_ID, "STAFF-M3").unwrap();

    insert_service_item(&connection, SERVICE_ITEM_ID, "SVC-001", "active", None).unwrap();
    connection
        .execute(
            "INSERT INTO service_item_scenes(
                institution_id, created_at, created_by_staff_id, created_source,
                service_item_id, scene
             ) VALUES (?1, ?2, ?3, 'manual', ?4, 'day')",
            params![INSTITUTION_ID, NOW, STAFF_ID, SERVICE_ITEM_ID],
        )
        .unwrap();
    connection
        .execute(
            "INSERT INTO service_item_qualification_requirements(
                institution_id, created_at, created_by_staff_id, created_source,
                service_item_id, qualification_type
             ) VALUES (?1, ?2, ?3, 'manual', ?4, 'elderly_care')",
            params![INSTITUTION_ID, NOW, STAFF_ID, SERVICE_ITEM_ID],
        )
        .unwrap();
    connection
        .execute(
            "INSERT INTO service_item_evidence_requirements(
                institution_id, created_at, created_by_staff_id, created_source,
                service_item_id, evidence_type
             ) VALUES (?1, ?2, ?3, 'manual', ?4, 'note')",
            params![INSTITUTION_ID, NOW, STAFF_ID, SERVICE_ITEM_ID],
        )
        .unwrap();
    assert!(
        insert_service_item(
            &connection,
            "01J00000000000000000000035",
            "SVC-002",
            "inactive",
            None
        )
        .is_err()
    );

    insert_charge_item(&connection, CHARGE_ITEM_ID, "CHG-001").unwrap();
    insert_charge_item(&connection, "01J00000000000000000000036", "CHG-002").unwrap();
    connection
        .execute(
            "INSERT INTO service_charge_links(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, service_item_id,
                charge_item_id, is_default, note
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, ?6, 1, NULL)",
            params![
                "01J00000000000000000000037",
                INSTITUTION_ID,
                NOW,
                STAFF_ID,
                SERVICE_ITEM_ID,
                CHARGE_ITEM_ID
            ],
        )
        .unwrap();
    assert!(
        connection
            .execute(
                "INSERT INTO service_charge_links(
                    id, institution_id, created_at, created_source, updated_at, record_version,
                    service_item_id, charge_item_id, is_default
                 ) VALUES (?1, ?2, ?3, 'manual', ?3, 1, ?4, ?5, 1)",
                params![
                    "01J00000000000000000000038",
                    INSTITUTION_ID,
                    NOW,
                    SERVICE_ITEM_ID,
                    "01J00000000000000000000036"
                ],
            )
            .is_err()
    );

    connection
        .execute(
            "INSERT INTO price_plans(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, price_plan_code,
                charge_item_id, name, scene_scope, site_id, home_area_id, status
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, 'PRICE-001',
                ?5, '日间免费体验价', 'day', NULL, NULL, 'active')",
            params![PRICE_PLAN_ID, INSTITUTION_ID, NOW, STAFF_ID, CHARGE_ITEM_ID],
        )
        .unwrap();
    assert!(
        insert_price_version(
            &connection,
            "01J00000000000000000000039",
            1,
            Some(0),
            0,
            "draft",
            None
        )
        .is_err()
    );
    insert_price_version(
        &connection,
        "01J00000000000000000000040",
        1,
        Some(0),
        1,
        "active",
        None,
    )
    .unwrap();
    assert!(
        insert_price_version(
            &connection,
            "01J00000000000000000000041",
            2,
            Some(1000),
            0,
            "draft",
            None
        )
        .is_err()
    );

    connection
        .execute(
            "INSERT INTO package_templates(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, package_code,
                name, applicable_scene, status
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1,
                'PKG-001', '日间基础套餐', 'day', 'active')",
            params![PACKAGE_TEMPLATE_ID, INSTITUTION_ID, NOW, STAFF_ID],
        )
        .unwrap();
    connection
        .execute(
            "INSERT INTO package_versions(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version, package_template_id,
                version_no, version_name, billing_cycle, package_price_cents,
                effective_from_date, effective_to_date, description, status, change_reason
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5,
                1, '首版', 'month', 50000, '2026-01-01', NULL,
                '日间基础套餐首版', 'active', NULL)",
            params![
                PACKAGE_VERSION_ID,
                INSTITUTION_ID,
                NOW,
                STAFF_ID,
                PACKAGE_TEMPLATE_ID
            ],
        )
        .unwrap();
    assert!(
        insert_package_entitlement(
            &connection,
            "01J00000000000000000000042",
            None,
            None,
            None,
            None
        )
        .is_err()
    );
    insert_package_entitlement(
        &connection,
        "01J00000000000000000000043",
        Some(4000),
        Some("time"),
        Some("month"),
        Some(r#"{"schema_version":1,"frequency_type":"weekly","times":1}"#),
    )
    .unwrap();
    assert!(
        connection
            .execute(
                "UPDATE package_entitlements
                 SET suggested_frequency_json = '{\"schema_version\":0}' WHERE id = ?1",
                ["01J00000000000000000000043"],
            )
            .is_err()
    );
    connection
        .execute(
            "INSERT INTO package_included_charges(
                id, institution_id, created_at, created_by_staff_id, created_source,
                updated_at, updated_by_staff_id, record_version,
                package_version_id, charge_item_id, inclusion_note
             ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, ?6, '套餐内已包含')",
            params![
                "01J00000000000000000000044",
                INSTITUTION_ID,
                NOW,
                STAFF_ID,
                PACKAGE_VERSION_ID,
                CHARGE_ITEM_ID
            ],
        )
        .unwrap();

    let integrity: String = connection
        .query_row("PRAGMA integrity_check", [], |row| row.get(0))
        .unwrap();
    let foreign_key_violations: i64 = connection
        .query_row("SELECT COUNT(*) FROM pragma_foreign_key_check", [], |row| {
            row.get(0)
        })
        .unwrap();
    assert_eq!(integrity, "ok");
    assert_eq!(foreign_key_violations, 0);
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

fn insert_staff(
    connection: &Connection,
    id: &str,
    institution_id: &str,
    staff_code: &str,
) -> rusqlite::Result<usize> {
    connection.execute(
        "INSERT INTO staff_members(
            id, institution_id, created_at, created_by_staff_id, created_source,
            updated_at, updated_by_staff_id, record_version, staff_code, full_name,
            gender, birth_date, id_type, id_number, id_number_normalized,
            mobile, mobile_normalized, email, emergency_contact_name,
            emergency_contact_phone, avatar_attachment_id, profile_note
         ) VALUES (?1, ?2, ?3, NULL, 'manual', ?3, NULL, 1, ?4, '测试员工',
            'unknown', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)",
        params![id, institution_id, NOW, staff_code],
    )
}

fn insert_site(
    connection: &Connection,
    id: &str,
    institution_id: &str,
    manager_staff_id: &str,
    is_default: i64,
    site_code: &str,
) -> rusqlite::Result<usize> {
    connection.execute(
        "INSERT INTO service_sites(
            id, institution_id, created_at, created_by_staff_id, created_source,
            updated_at, updated_by_staff_id, record_version, site_code, name,
            site_type, is_default, manager_staff_id, contact_phone, province_code,
            city_code, district_code, address_detail, status, disabled_reason
         ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, '测试站点',
            'comprehensive', ?6, ?4, NULL, '41', '4101', '410102',
            '测试路2号', 'active', NULL)",
        params![
            id,
            institution_id,
            NOW,
            manager_staff_id,
            site_code,
            is_default
        ],
    )
}

fn insert_service_item(
    connection: &Connection,
    id: &str,
    service_code: &str,
    status: &str,
    disabled_reason: Option<&str>,
) -> rusqlite::Result<usize> {
    connection.execute(
        "INSERT INTO service_items(
            id, institution_id, created_at, created_by_staff_id, created_source,
            updated_at, updated_by_staff_id, record_version, service_code, name,
            category, description, standard_steps, default_duration_minutes,
            result_unit, risk_level, status, disabled_reason
         ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, '日间照护',
            'personal_care', '提供日间基础照护', NULL, 30,
            'time', 'low', ?6, ?7)",
        params![
            id,
            INSTITUTION_ID,
            NOW,
            STAFF_ID,
            service_code,
            status,
            disabled_reason
        ],
    )
}

fn insert_charge_item(
    connection: &Connection,
    id: &str,
    charge_code: &str,
) -> rusqlite::Result<usize> {
    connection.execute(
        "INSERT INTO charge_items(
            id, institution_id, created_at, created_by_staff_id, created_source,
            updated_at, updated_by_staff_id, record_version, charge_code, name,
            category, default_unit, description, status
         ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, '日间照护费',
            'service', 'per_time', NULL, 'active')",
        params![id, INSTITUTION_ID, NOW, STAFF_ID, charge_code],
    )
}

fn insert_price_version(
    connection: &Connection,
    id: &str,
    version_no: i64,
    amount_cents: Option<i64>,
    is_free: i64,
    status: &str,
    change_reason: Option<&str>,
) -> rusqlite::Result<usize> {
    connection.execute(
        "INSERT INTO price_versions(
            id, institution_id, created_at, created_by_staff_id, created_source,
            updated_at, updated_by_staff_id, record_version, price_plan_id,
            version_no, charge_unit, amount_cents, is_free, effective_from_date,
            effective_to_date, status, change_reason
         ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5,
            ?6, 'per_time', ?7, ?8, '2026-01-01', NULL, ?9, ?10)",
        params![
            id,
            INSTITUTION_ID,
            NOW,
            STAFF_ID,
            PRICE_PLAN_ID,
            version_no,
            amount_cents,
            is_free,
            status,
            change_reason
        ],
    )
}

fn insert_package_entitlement(
    connection: &Connection,
    id: &str,
    quota_quantity_milli: Option<i64>,
    quota_unit: Option<&str>,
    quota_cycle: Option<&str>,
    suggested_frequency_json: Option<&str>,
) -> rusqlite::Result<usize> {
    connection.execute(
        "INSERT INTO package_entitlements(
            id, institution_id, created_at, created_by_staff_id, created_source,
            updated_at, updated_by_staff_id, record_version, package_version_id,
            service_item_id, entitlement_type, quota_quantity_milli, quota_unit,
            quota_cycle, suggested_frequency_json, overage_policy, sort_order
         ) VALUES (?1, ?2, ?3, ?4, 'manual', ?3, ?4, 1, ?5, ?6,
            'fixed_quota', ?7, ?8, ?9, ?10, 'prompt_extra', 0)",
        params![
            id,
            INSTITUTION_ID,
            NOW,
            STAFF_ID,
            PACKAGE_VERSION_ID,
            SERVICE_ITEM_ID,
            quota_quantity_milli,
            quota_unit,
            quota_cycle,
            suggested_frequency_json
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
        let escaped_table = table.replace('"', "\"\"");
        let column_count: i64 = connection
            .query_row(
                &format!("SELECT COUNT(*) FROM pragma_table_xinfo(\"{escaped_table}\")"),
                [],
                |row| row.get(0),
            )
            .unwrap();
        let foreign_key_column_count: i64 = connection
            .query_row(
                &format!("SELECT COUNT(*) FROM pragma_foreign_key_list(\"{escaped_table}\")"),
                [],
                |row| row.get(0),
            )
            .unwrap();
        lines.push(format!(
            "TABLE {table} strict={} columns={column_count} fk_columns={foreign_key_column_count} sql_sha256={:x}",
            i32::from(strict),
            Sha256::digest(sql.as_bytes())
        ));
    }

    let indexes = connection
        .prepare(
            "SELECT name, tbl_name, sql FROM sqlite_schema
             WHERE type = 'index' AND sql IS NOT NULL
             ORDER BY name",
        )
        .unwrap()
        .query_map([], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
            ))
        })
        .unwrap()
        .collect::<Result<Vec<_>, _>>()
        .unwrap();
    for (name, table, sql) in indexes {
        lines.push(format!(
            "INDEX {name} table={table} sql_sha256={:x}",
            Sha256::digest(sql.as_bytes())
        ));
    }

    lines.join("\n")
}
