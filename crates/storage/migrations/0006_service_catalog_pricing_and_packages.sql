CREATE TABLE service_items (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    service_code TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    standard_steps TEXT,
    default_duration_minutes INTEGER,
    result_unit TEXT NOT NULL,
    risk_level TEXT NOT NULL,
    status TEXT NOT NULL,
    disabled_reason TEXT,

    CONSTRAINT uq_service_items__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_service_items__institution_service_code UNIQUE (
        institution_id, service_code
    ),
    CONSTRAINT fk_service_items__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_items__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_items__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_service_items__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_service_items__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_service_items__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_service_items__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_service_items__required_text CHECK (
        length(trim(service_code)) > 0
        AND length(trim(name)) > 0
        AND length(trim(description)) > 0
    ),
    CONSTRAINT ck_service_items__category CHECK (
        category IN (
            'personal_care', 'daily_living', 'health_monitoring', 'rehabilitation',
            'social_activity', 'meal', 'cleaning', 'escort', 'emergency', 'other'
        )
    ),
    CONSTRAINT ck_service_items__default_duration CHECK (
        default_duration_minutes IS NULL OR default_duration_minutes > 0
    ),
    CONSTRAINT ck_service_items__result_unit CHECK (
        result_unit IN ('time', 'minute', 'hour', 'item', 'portion', 'day', 'month')
    ),
    CONSTRAINT ck_service_items__risk_level CHECK (
        risk_level IN ('low', 'medium', 'high')
    ),
    CONSTRAINT ck_service_items__status CHECK (
        (status IN ('draft', 'active') AND disabled_reason IS NULL)
        OR (
            status = 'inactive'
            AND disabled_reason IS NOT NULL
            AND length(trim(disabled_reason)) > 0
        )
    )
) STRICT;

CREATE TABLE service_item_scenes (
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    service_item_id TEXT NOT NULL,
    scene TEXT NOT NULL,

    CONSTRAINT pk_service_item_scenes PRIMARY KEY (institution_id, service_item_id, scene),
    CONSTRAINT fk_service_item_scenes__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_item_scenes__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_item_scenes__service_item FOREIGN KEY (
        institution_id, service_item_id
    ) REFERENCES service_items(institution_id, id) ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT ck_service_item_scenes__ulids CHECK (
        length(institution_id) = 26 AND length(service_item_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
    ),
    CONSTRAINT ck_service_item_scenes__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_service_item_scenes__created_at CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
    ),
    CONSTRAINT ck_service_item_scenes__scene CHECK (
        scene IN ('home', 'day', 'residential', 'respite')
    )
) STRICT;

CREATE TABLE service_item_qualification_requirements (
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    service_item_id TEXT NOT NULL,
    qualification_type TEXT NOT NULL,

    CONSTRAINT pk_service_item_qualification_requirements PRIMARY KEY (
        institution_id, service_item_id, qualification_type
    ),
    CONSTRAINT fk_service_item_qualification_requirements__institution FOREIGN KEY (
        institution_id
    ) REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_item_qualification_requirements__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_item_qualification_requirements__service_item FOREIGN KEY (
        institution_id, service_item_id
    ) REFERENCES service_items(institution_id, id) ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT ck_service_item_qualification_requirements__ulids CHECK (
        length(institution_id) = 26 AND length(service_item_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
    ),
    CONSTRAINT ck_service_item_qualification_requirements__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_service_item_qualification_requirements__created_at CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
    ),
    CONSTRAINT ck_service_item_qualification_requirements__qualification_type CHECK (
        qualification_type IN (
            'elderly_care', 'nursing', 'rehabilitation', 'social_work',
            'first_aid', 'food_safety', 'driver', 'other'
        )
    )
) STRICT;

CREATE TABLE service_item_evidence_requirements (
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    service_item_id TEXT NOT NULL,
    evidence_type TEXT NOT NULL,

    CONSTRAINT pk_service_item_evidence_requirements PRIMARY KEY (
        institution_id, service_item_id, evidence_type
    ),
    CONSTRAINT fk_service_item_evidence_requirements__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_item_evidence_requirements__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_item_evidence_requirements__service_item FOREIGN KEY (
        institution_id, service_item_id
    ) REFERENCES service_items(institution_id, id) ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT ck_service_item_evidence_requirements__ulids CHECK (
        length(institution_id) = 26 AND length(service_item_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
    ),
    CONSTRAINT ck_service_item_evidence_requirements__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_service_item_evidence_requirements__created_at CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
    ),
    CONSTRAINT ck_service_item_evidence_requirements__evidence_type CHECK (
        evidence_type IN ('note', 'photo', 'signature', 'metric', 'attachment')
    )
) STRICT;

CREATE TABLE charge_items (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    charge_code TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    default_unit TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL,

    CONSTRAINT uq_charge_items__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_charge_items__institution_charge_code UNIQUE (institution_id, charge_code),
    CONSTRAINT fk_charge_items__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_charge_items__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_charge_items__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_charge_items__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_charge_items__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_charge_items__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_charge_items__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_charge_items__required_text CHECK (
        length(trim(charge_code)) > 0 AND length(trim(name)) > 0
    ),
    CONSTRAINT ck_charge_items__category CHECK (
        category IN ('service', 'bed', 'meal', 'management', 'supplies', 'package', 'other')
    ),
    CONSTRAINT ck_charge_items__default_unit CHECK (
        default_unit IN (
            'per_time', 'per_minute', 'per_hour', 'per_item', 'per_portion',
            'per_day', 'per_week', 'per_month', 'one_time', 'package_fixed'
        )
    ),
    CONSTRAINT ck_charge_items__status CHECK (status IN ('draft', 'active', 'inactive'))
) STRICT;

CREATE TABLE service_charge_links (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    service_item_id TEXT NOT NULL,
    charge_item_id TEXT NOT NULL,
    is_default INTEGER NOT NULL,
    note TEXT,

    CONSTRAINT uq_service_charge_links__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_service_charge_links__service_charge UNIQUE (
        institution_id, service_item_id, charge_item_id
    ),
    CONSTRAINT fk_service_charge_links__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_charge_links__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_charge_links__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_charge_links__service_item FOREIGN KEY (
        institution_id, service_item_id
    ) REFERENCES service_items(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_charge_links__charge_item FOREIGN KEY (
        institution_id, charge_item_id
    ) REFERENCES charge_items(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_service_charge_links__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(service_item_id) = 26 AND length(charge_item_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_service_charge_links__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_service_charge_links__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_service_charge_links__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_service_charge_links__is_default CHECK (is_default IN (0, 1))
) STRICT;

CREATE UNIQUE INDEX uq_service_charge_links__service_default
ON service_charge_links(institution_id, service_item_id)
WHERE is_default = 1;

CREATE TABLE price_plans (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    price_plan_code TEXT NOT NULL,
    charge_item_id TEXT NOT NULL,
    name TEXT NOT NULL,
    scene_scope TEXT NOT NULL,
    site_id TEXT,
    home_area_id TEXT,
    status TEXT NOT NULL,

    CONSTRAINT uq_price_plans__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_price_plans__institution_price_plan_code UNIQUE (
        institution_id, price_plan_code
    ),
    CONSTRAINT fk_price_plans__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_price_plans__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_price_plans__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_price_plans__charge_item FOREIGN KEY (institution_id, charge_item_id)
        REFERENCES charge_items(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_price_plans__site FOREIGN KEY (institution_id, site_id)
        REFERENCES service_sites(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_price_plans__home_area FOREIGN KEY (institution_id, home_area_id)
        REFERENCES home_service_areas(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_price_plans__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(charge_item_id) = 26
        AND (site_id IS NULL OR length(site_id) = 26)
        AND (home_area_id IS NULL OR length(home_area_id) = 26)
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_price_plans__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_price_plans__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_price_plans__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_price_plans__required_text CHECK (
        length(trim(price_plan_code)) > 0 AND length(trim(name)) > 0
    ),
    CONSTRAINT ck_price_plans__scope CHECK (
        scene_scope IN ('all', 'home', 'day', 'residential', 'respite')
        AND (home_area_id IS NULL OR (scene_scope = 'home' AND site_id IS NOT NULL))
    ),
    CONSTRAINT ck_price_plans__status CHECK (status IN ('draft', 'active', 'inactive'))
) STRICT;

CREATE TABLE price_versions (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    price_plan_id TEXT NOT NULL,
    version_no INTEGER NOT NULL,
    charge_unit TEXT NOT NULL,
    amount_cents INTEGER,
    is_free INTEGER NOT NULL,
    effective_from_date TEXT NOT NULL,
    effective_to_date TEXT,
    status TEXT NOT NULL,
    change_reason TEXT,

    CONSTRAINT uq_price_versions__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_price_versions__plan_version UNIQUE (
        institution_id, price_plan_id, version_no
    ),
    CONSTRAINT fk_price_versions__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_price_versions__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_price_versions__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_price_versions__price_plan FOREIGN KEY (institution_id, price_plan_id)
        REFERENCES price_plans(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_price_versions__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(price_plan_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_price_versions__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_price_versions__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_price_versions__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_price_versions__version_no CHECK (version_no > 0),
    CONSTRAINT ck_price_versions__charge_unit CHECK (
        charge_unit IN (
            'per_time', 'per_minute', 'per_hour', 'per_item', 'per_portion',
            'per_day', 'per_week', 'per_month', 'one_time', 'package_fixed'
        )
    ),
    CONSTRAINT ck_price_versions__amount_free_state CHECK (
        (is_free = 1 AND amount_cents = 0)
        OR (is_free = 0 AND (amount_cents IS NULL OR amount_cents > 0))
    ),
    CONSTRAINT ck_price_versions__dates CHECK (
        length(effective_from_date) = 10
        AND effective_from_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
        AND date(effective_from_date) = effective_from_date
        AND (effective_to_date IS NULL OR (
            length(effective_to_date) = 10
            AND effective_to_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(effective_to_date) = effective_to_date
            AND effective_to_date >= effective_from_date
        ))
    ),
    CONSTRAINT ck_price_versions__status CHECK (
        status IN ('draft', 'scheduled', 'active', 'expired', 'cancelled')
        AND (status NOT IN ('scheduled', 'active', 'expired') OR amount_cents IS NOT NULL)
    ),
    CONSTRAINT ck_price_versions__change_reason CHECK (
        version_no = 1 OR (change_reason IS NOT NULL AND length(trim(change_reason)) > 0)
    )
) STRICT;

CREATE TABLE package_templates (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    package_code TEXT NOT NULL,
    name TEXT NOT NULL,
    applicable_scene TEXT NOT NULL,
    status TEXT NOT NULL,

    CONSTRAINT uq_package_templates__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_package_templates__institution_package_code UNIQUE (
        institution_id, package_code
    ),
    CONSTRAINT fk_package_templates__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_templates__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_templates__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_package_templates__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_package_templates__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_package_templates__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_package_templates__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_package_templates__required_text CHECK (
        length(trim(package_code)) > 0 AND length(trim(name)) > 0
    ),
    CONSTRAINT ck_package_templates__applicable_scene CHECK (
        applicable_scene IN ('home', 'day', 'residential', 'respite')
    ),
    CONSTRAINT ck_package_templates__status CHECK (status IN ('draft', 'active', 'inactive'))
) STRICT;

CREATE TABLE package_versions (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    package_template_id TEXT NOT NULL,
    version_no INTEGER NOT NULL,
    version_name TEXT,
    billing_cycle TEXT NOT NULL,
    package_price_cents INTEGER NOT NULL,
    effective_from_date TEXT NOT NULL,
    effective_to_date TEXT,
    description TEXT,
    status TEXT NOT NULL,
    change_reason TEXT,

    CONSTRAINT uq_package_versions__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_package_versions__template_version UNIQUE (
        institution_id, package_template_id, version_no
    ),
    CONSTRAINT fk_package_versions__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_versions__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_versions__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_versions__package_template FOREIGN KEY (
        institution_id, package_template_id
    ) REFERENCES package_templates(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_package_versions__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(package_template_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_package_versions__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_package_versions__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_package_versions__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_package_versions__version_no CHECK (version_no > 0),
    CONSTRAINT ck_package_versions__billing_cycle CHECK (
        billing_cycle IN ('week', 'month', 'agreed', 'one_time')
    ),
    CONSTRAINT ck_package_versions__package_price CHECK (package_price_cents >= 0),
    CONSTRAINT ck_package_versions__dates CHECK (
        length(effective_from_date) = 10
        AND effective_from_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
        AND date(effective_from_date) = effective_from_date
        AND (effective_to_date IS NULL OR (
            length(effective_to_date) = 10
            AND effective_to_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(effective_to_date) = effective_to_date
            AND effective_to_date >= effective_from_date
        ))
    ),
    CONSTRAINT ck_package_versions__status CHECK (
        status IN ('draft', 'scheduled', 'active', 'expired', 'cancelled')
    ),
    CONSTRAINT ck_package_versions__change_reason CHECK (
        version_no = 1 OR (change_reason IS NOT NULL AND length(trim(change_reason)) > 0)
    )
) STRICT;

CREATE TABLE package_entitlements (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    package_version_id TEXT NOT NULL,
    service_item_id TEXT NOT NULL,
    entitlement_type TEXT NOT NULL,
    quota_quantity_milli INTEGER,
    quota_unit TEXT,
    quota_cycle TEXT,
    suggested_frequency_json TEXT,
    overage_policy TEXT NOT NULL,
    sort_order INTEGER NOT NULL,

    CONSTRAINT uq_package_entitlements__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_package_entitlements__version_service UNIQUE (
        institution_id, package_version_id, service_item_id
    ),
    CONSTRAINT fk_package_entitlements__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_entitlements__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_entitlements__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_entitlements__package_version FOREIGN KEY (
        institution_id, package_version_id
    ) REFERENCES package_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_entitlements__service_item FOREIGN KEY (
        institution_id, service_item_id
    ) REFERENCES service_items(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_package_entitlements__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(package_version_id) = 26 AND length(service_item_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_package_entitlements__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_package_entitlements__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_package_entitlements__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_package_entitlements__quota_group CHECK (
        (
            entitlement_type = 'fixed_quota'
            AND quota_quantity_milli IS NOT NULL AND quota_quantity_milli > 0
            AND quota_unit IN ('time', 'minute', 'hour', 'item', 'portion', 'day', 'month')
            AND quota_cycle IN ('day', 'week', 'month', 'relationship_period')
        )
        OR (
            entitlement_type IN ('unlimited', 'included_on_demand')
            AND quota_quantity_milli IS NULL AND quota_unit IS NULL AND quota_cycle IS NULL
        )
    ),
    CONSTRAINT ck_package_entitlements__suggested_frequency_json CHECK (
        suggested_frequency_json IS NULL OR (
            json_valid(suggested_frequency_json)
            AND json_type(suggested_frequency_json) = 'object'
            AND json_type(suggested_frequency_json, '$.schema_version') = 'integer'
            AND json_extract(suggested_frequency_json, '$.schema_version') > 0
        )
    ),
    CONSTRAINT ck_package_entitlements__overage_policy CHECK (
        overage_policy IN ('prompt_extra', 'gift', 'allow_overuse', 'manual')
    ),
    CONSTRAINT ck_package_entitlements__sort_order CHECK (sort_order >= 0)
) STRICT;

CREATE TABLE package_included_charges (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    package_version_id TEXT NOT NULL,
    charge_item_id TEXT NOT NULL,
    inclusion_note TEXT,

    CONSTRAINT uq_package_included_charges__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_package_included_charges__version_charge UNIQUE (
        institution_id, package_version_id, charge_item_id
    ),
    CONSTRAINT fk_package_included_charges__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_included_charges__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_included_charges__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_included_charges__package_version FOREIGN KEY (
        institution_id, package_version_id
    ) REFERENCES package_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_package_included_charges__charge_item FOREIGN KEY (
        institution_id, charge_item_id
    ) REFERENCES charge_items(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_package_included_charges__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(package_version_id) = 26 AND length(charge_item_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_package_included_charges__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_package_included_charges__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_package_included_charges__record_version CHECK (record_version >= 1)
) STRICT;
