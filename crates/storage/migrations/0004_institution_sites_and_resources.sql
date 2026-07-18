CREATE TABLE institution_capabilities (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    capability_type TEXT NOT NULL,
    enabled INTEGER NOT NULL,
    declared_capacity INTEGER,
    policy_notice_code TEXT,
    policy_notice_seen_at TEXT,
    institution_note TEXT,

    CONSTRAINT uq_institution_capabilities__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_institution_capabilities__institution_type UNIQUE (
        institution_id, capability_type
    ),
    CONSTRAINT fk_institution_capabilities__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_institution_capabilities__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_institution_capabilities__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_institution_capabilities__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_institution_capabilities__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_institution_capabilities__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
        AND (policy_notice_seen_at IS NULL OR (
            length(policy_notice_seen_at) = 24
            AND strftime('%Y-%m-%dT%H:%M:%fZ', policy_notice_seen_at) = policy_notice_seen_at
        ))
    ),
    CONSTRAINT ck_institution_capabilities__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_institution_capabilities__capability_type CHECK (
        capability_type IN ('home', 'day', 'residential', 'respite')
    ),
    CONSTRAINT ck_institution_capabilities__enabled CHECK (enabled IN (0, 1)),
    CONSTRAINT ck_institution_capabilities__declared_capacity CHECK (
        declared_capacity IS NULL OR (
            capability_type <> 'home' AND declared_capacity >= 0
        )
    ),
    CONSTRAINT ck_institution_capabilities__policy_notice CHECK (
        policy_notice_seen_at IS NULL OR policy_notice_code IS NOT NULL
    )
) STRICT;

CREATE TABLE feature_preferences (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    feature_key TEXT NOT NULL,
    recommended INTEGER NOT NULL,
    enabled INTEGER NOT NULL,
    preference_source TEXT NOT NULL,
    changed_at TEXT NOT NULL,

    CONSTRAINT uq_feature_preferences__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_feature_preferences__institution_feature_key UNIQUE (
        institution_id, feature_key
    ),
    CONSTRAINT fk_feature_preferences__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_feature_preferences__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_feature_preferences__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_feature_preferences__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_feature_preferences__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_feature_preferences__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND length(changed_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', changed_at) = changed_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_feature_preferences__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_feature_preferences__feature_key CHECK (length(trim(feature_key)) > 0),
    CONSTRAINT ck_feature_preferences__booleans CHECK (
        recommended IN (0, 1) AND enabled IN (0, 1)
    ),
    CONSTRAINT ck_feature_preferences__preference_source CHECK (
        preference_source IN ('recommendation', 'user_override')
    )
) STRICT;

CREATE TABLE service_sites (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    site_code TEXT NOT NULL,
    name TEXT NOT NULL,
    site_type TEXT NOT NULL,
    is_default INTEGER NOT NULL,
    manager_staff_id TEXT,
    contact_phone TEXT,
    province_code TEXT NOT NULL,
    city_code TEXT NOT NULL,
    district_code TEXT NOT NULL,
    address_detail TEXT NOT NULL,
    status TEXT NOT NULL,
    disabled_reason TEXT,

    CONSTRAINT uq_service_sites__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_service_sites__institution_site_code UNIQUE (institution_id, site_code),
    CONSTRAINT fk_service_sites__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_sites__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_sites__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_sites__manager_staff FOREIGN KEY (institution_id, manager_staff_id)
        REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_service_sites__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (manager_staff_id IS NULL OR length(manager_staff_id) = 26)
    ),
    CONSTRAINT ck_service_sites__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_service_sites__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_service_sites__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_service_sites__required_text CHECK (
        length(trim(site_code)) > 0
        AND length(trim(name)) > 0
        AND length(trim(address_detail)) > 0
    ),
    CONSTRAINT ck_service_sites__site_type CHECK (
        site_type IN ('comprehensive', 'home_service', 'day_care', 'residential', 'other')
    ),
    CONSTRAINT ck_service_sites__is_default CHECK (is_default IN (0, 1)),
    CONSTRAINT ck_service_sites__address_codes CHECK (
        length(province_code) = 2 AND province_code NOT GLOB '*[^0-9]*'
        AND length(city_code) = 4 AND city_code NOT GLOB '*[^0-9]*'
        AND length(district_code) = 6 AND district_code NOT GLOB '*[^0-9]*'
    ),
    CONSTRAINT ck_service_sites__status CHECK (
        (status = 'active' AND disabled_reason IS NULL)
        OR (status = 'inactive' AND disabled_reason IS NOT NULL AND length(trim(disabled_reason)) > 0)
    )
) STRICT;

CREATE UNIQUE INDEX uq_service_sites__institution_default
ON service_sites(institution_id)
WHERE is_default = 1;

CREATE TABLE service_site_scenes (
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    service_site_id TEXT NOT NULL,
    scene TEXT NOT NULL,

    CONSTRAINT pk_service_site_scenes PRIMARY KEY (institution_id, service_site_id, scene),
    CONSTRAINT fk_service_site_scenes__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_site_scenes__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_site_scenes__service_site FOREIGN KEY (
        institution_id, service_site_id
    ) REFERENCES service_sites(institution_id, id) ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT ck_service_site_scenes__ulids CHECK (
        length(institution_id) = 26
        AND length(service_site_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
    ),
    CONSTRAINT ck_service_site_scenes__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_service_site_scenes__created_at CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
    ),
    CONSTRAINT ck_service_site_scenes__scene CHECK (
        scene IN ('home', 'day', 'residential', 'respite')
    )
) STRICT;

CREATE TABLE space_nodes (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    site_id TEXT NOT NULL,
    parent_id TEXT,
    node_type TEXT NOT NULL,
    space_code TEXT NOT NULL,
    name TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    status TEXT NOT NULL,

    CONSTRAINT uq_space_nodes__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_space_nodes__site_type_code UNIQUE (
        institution_id, site_id, node_type, space_code
    ),
    CONSTRAINT fk_space_nodes__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_space_nodes__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_space_nodes__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_space_nodes__site FOREIGN KEY (institution_id, site_id)
        REFERENCES service_sites(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_space_nodes__parent FOREIGN KEY (institution_id, parent_id)
        REFERENCES space_nodes(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_space_nodes__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(site_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (parent_id IS NULL OR length(parent_id) = 26)
        AND parent_id IS NOT id
    ),
    CONSTRAINT ck_space_nodes__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_space_nodes__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_space_nodes__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_space_nodes__node_type CHECK (
        node_type IN ('building', 'floor', 'room', 'area')
    ),
    CONSTRAINT ck_space_nodes__required_text CHECK (
        length(trim(space_code)) > 0 AND length(trim(name)) > 0
    ),
    CONSTRAINT ck_space_nodes__sort_order CHECK (sort_order >= 0),
    CONSTRAINT ck_space_nodes__status CHECK (status IN ('active', 'inactive'))
) STRICT;

CREATE TABLE accommodation_positions (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    site_id TEXT NOT NULL,
    space_node_id TEXT NOT NULL,
    position_code TEXT NOT NULL,
    name TEXT NOT NULL,
    primary_use TEXT NOT NULL,
    respite_eligible INTEGER NOT NULL,
    occupancy_gender_rule TEXT,
    status TEXT NOT NULL,
    status_note TEXT,

    CONSTRAINT uq_accommodation_positions__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_accommodation_positions__site_position_code UNIQUE (
        institution_id, site_id, position_code
    ),
    CONSTRAINT fk_accommodation_positions__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_accommodation_positions__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_accommodation_positions__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_accommodation_positions__site FOREIGN KEY (institution_id, site_id)
        REFERENCES service_sites(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_accommodation_positions__space_node FOREIGN KEY (
        institution_id, space_node_id
    ) REFERENCES space_nodes(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_accommodation_positions__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(site_id) = 26 AND length(space_node_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_accommodation_positions__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_accommodation_positions__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_accommodation_positions__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_accommodation_positions__required_text CHECK (
        length(trim(position_code)) > 0 AND length(trim(name)) > 0
    ),
    CONSTRAINT ck_accommodation_positions__primary_use CHECK (
        primary_use IN ('residential_bed', 'respite_position')
    ),
    CONSTRAINT ck_accommodation_positions__respite_eligible CHECK (
        respite_eligible IN (0, 1)
    ),
    CONSTRAINT ck_accommodation_positions__gender_rule CHECK (
        occupancy_gender_rule IS NULL OR occupancy_gender_rule IN ('none', 'male', 'female')
    ),
    CONSTRAINT ck_accommodation_positions__status CHECK (
        status IN ('active', 'maintenance', 'inactive')
    )
) STRICT;

CREATE TABLE accommodation_position_features (
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    accommodation_position_id TEXT NOT NULL,
    feature_value TEXT NOT NULL,

    CONSTRAINT pk_accommodation_position_features PRIMARY KEY (
        institution_id, accommodation_position_id, feature_value
    ),
    CONSTRAINT fk_accommodation_position_features__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_accommodation_position_features__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_accommodation_position_features__position FOREIGN KEY (
        institution_id, accommodation_position_id
    ) REFERENCES accommodation_positions(institution_id, id)
        ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT ck_accommodation_position_features__ulids CHECK (
        length(institution_id) = 26 AND length(accommodation_position_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
    ),
    CONSTRAINT ck_accommodation_position_features__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_accommodation_position_features__created_at CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
    ),
    CONSTRAINT ck_accommodation_position_features__feature_value CHECK (
        length(trim(feature_value)) > 0 AND feature_value = trim(feature_value)
    )
) STRICT;

CREATE TABLE day_care_areas (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    site_id TEXT NOT NULL,
    space_node_id TEXT,
    area_code TEXT NOT NULL,
    name TEXT NOT NULL,
    capacity INTEGER NOT NULL,
    numbered_rest_positions INTEGER NOT NULL,
    status TEXT NOT NULL,

    CONSTRAINT uq_day_care_areas__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_day_care_areas__site_area_code UNIQUE (institution_id, site_id, area_code),
    CONSTRAINT fk_day_care_areas__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_care_areas__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_care_areas__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_care_areas__site FOREIGN KEY (institution_id, site_id)
        REFERENCES service_sites(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_care_areas__space_node FOREIGN KEY (institution_id, space_node_id)
        REFERENCES space_nodes(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_day_care_areas__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(site_id) = 26
        AND (space_node_id IS NULL OR length(space_node_id) = 26)
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_day_care_areas__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_day_care_areas__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_day_care_areas__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_day_care_areas__required_text CHECK (
        length(trim(area_code)) > 0 AND length(trim(name)) > 0
    ),
    CONSTRAINT ck_day_care_areas__capacity CHECK (capacity > 0),
    CONSTRAINT ck_day_care_areas__numbered_positions CHECK (
        numbered_rest_positions IN (0, 1)
    ),
    CONSTRAINT ck_day_care_areas__status CHECK (
        status IN ('active', 'maintenance', 'inactive')
    )
) STRICT;

CREATE TABLE day_rest_positions (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    day_care_area_id TEXT NOT NULL,
    position_code TEXT NOT NULL,
    name TEXT NOT NULL,
    status TEXT NOT NULL,

    CONSTRAINT uq_day_rest_positions__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_day_rest_positions__area_position_code UNIQUE (
        institution_id, day_care_area_id, position_code
    ),
    CONSTRAINT fk_day_rest_positions__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_rest_positions__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_rest_positions__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_rest_positions__day_care_area FOREIGN KEY (
        institution_id, day_care_area_id
    ) REFERENCES day_care_areas(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_day_rest_positions__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(day_care_area_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_day_rest_positions__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_day_rest_positions__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_day_rest_positions__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_day_rest_positions__required_text CHECK (
        length(trim(position_code)) > 0 AND length(trim(name)) > 0
    ),
    CONSTRAINT ck_day_rest_positions__status CHECK (
        status IN ('active', 'maintenance', 'inactive')
    )
) STRICT;

CREATE TABLE home_service_areas (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    site_id TEXT NOT NULL,
    area_code TEXT NOT NULL,
    name TEXT NOT NULL,
    province_code TEXT NOT NULL,
    city_code TEXT NOT NULL,
    boundary_description TEXT NOT NULL,
    travel_note TEXT,
    status TEXT NOT NULL,

    CONSTRAINT uq_home_service_areas__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_home_service_areas__site_area_code UNIQUE (
        institution_id, site_id, area_code
    ),
    CONSTRAINT fk_home_service_areas__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_service_areas__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_service_areas__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_service_areas__site FOREIGN KEY (institution_id, site_id)
        REFERENCES service_sites(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_home_service_areas__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(site_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_home_service_areas__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_home_service_areas__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_home_service_areas__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_home_service_areas__required_text CHECK (
        length(trim(area_code)) > 0
        AND length(trim(name)) > 0
        AND length(trim(boundary_description)) > 0
    ),
    CONSTRAINT ck_home_service_areas__address_codes CHECK (
        length(province_code) = 2 AND province_code NOT GLOB '*[^0-9]*'
        AND length(city_code) = 4 AND city_code NOT GLOB '*[^0-9]*'
    ),
    CONSTRAINT ck_home_service_areas__status CHECK (status IN ('active', 'inactive'))
) STRICT;

CREATE TABLE home_service_area_districts (
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    home_service_area_id TEXT NOT NULL,
    district_code TEXT NOT NULL,

    CONSTRAINT pk_home_service_area_districts PRIMARY KEY (
        institution_id, home_service_area_id, district_code
    ),
    CONSTRAINT fk_home_service_area_districts__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_service_area_districts__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_service_area_districts__home_service_area FOREIGN KEY (
        institution_id, home_service_area_id
    ) REFERENCES home_service_areas(institution_id, id) ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT ck_home_service_area_districts__ulids CHECK (
        length(institution_id) = 26 AND length(home_service_area_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
    ),
    CONSTRAINT ck_home_service_area_districts__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_home_service_area_districts__created_at CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
    ),
    CONSTRAINT ck_home_service_area_districts__district_code CHECK (
        length(district_code) = 6 AND district_code NOT GLOB '*[^0-9]*'
    )
) STRICT;
