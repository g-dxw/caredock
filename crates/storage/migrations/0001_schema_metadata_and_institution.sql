CREATE TABLE institutions (
    id TEXT PRIMARY KEY,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    institution_code TEXT NOT NULL,
    name TEXT NOT NULL,
    short_name TEXT,
    registration_type TEXT,
    ownership_nature TEXT,
    operation_mode TEXT,
    legal_representative_name TEXT,
    contact_phone TEXT NOT NULL,
    province_code TEXT NOT NULL,
    city_code TEXT NOT NULL,
    district_code TEXT NOT NULL,
    address_detail TEXT NOT NULL,
    postal_code TEXT,
    status TEXT NOT NULL,
    initialized_at TEXT NOT NULL,

    CONSTRAINT uq_institutions__institution_code UNIQUE (institution_code),
    CONSTRAINT ck_institutions__id_ulid CHECK (length(id) = 26),
    CONSTRAINT ck_institutions__created_by_staff_ulid CHECK (
        created_by_staff_id IS NULL OR length(created_by_staff_id) = 26
    ),
    CONSTRAINT ck_institutions__updated_by_staff_ulid CHECK (
        updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26
    ),
    CONSTRAINT ck_institutions__created_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_institutions__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND length(initialized_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', initialized_at) = initialized_at
        AND updated_at >= created_at
        AND initialized_at >= created_at
    ),
    CONSTRAINT ck_institutions__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_institutions__institution_code_present CHECK (
        length(trim(institution_code)) > 0
    ),
    CONSTRAINT ck_institutions__name_present CHECK (length(trim(name)) > 0),
    CONSTRAINT ck_institutions__contact_phone_present CHECK (
        length(trim(contact_phone)) > 0
    ),
    CONSTRAINT ck_institutions__address_codes CHECK (
        length(province_code) = 2
        AND province_code NOT GLOB '*[^0-9]*'
        AND length(city_code) = 4
        AND city_code NOT GLOB '*[^0-9]*'
        AND length(district_code) = 6
        AND district_code NOT GLOB '*[^0-9]*'
    ),
    CONSTRAINT ck_institutions__address_detail_present CHECK (
        length(trim(address_detail)) > 0
    ),
    CONSTRAINT ck_institutions__registration_type CHECK (
        registration_type IS NULL OR registration_type IN (
            'enterprise', 'social_organization', 'public_institution',
            'individual_business', 'other'
        )
    ),
    CONSTRAINT ck_institutions__ownership_nature CHECK (
        ownership_nature IS NULL OR ownership_nature IN (
            'public', 'private_nonprofit', 'private_for_profit', 'mixed', 'other'
        )
    ),
    CONSTRAINT ck_institutions__operation_mode CHECK (
        operation_mode IS NULL OR operation_mode IN (
            'self_operated', 'entrusted', 'cooperative', 'chain', 'other'
        )
    ),
    CONSTRAINT ck_institutions__status CHECK (status IN ('active', 'inactive'))
) STRICT;
