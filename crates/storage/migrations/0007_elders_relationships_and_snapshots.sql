CREATE TABLE elders (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    elder_code TEXT NOT NULL,
    full_name TEXT NOT NULL,
    gender TEXT,
    birth_date TEXT,
    id_type TEXT,
    id_number TEXT,
    id_number_normalized TEXT,
    nationality TEXT,
    mobile TEXT,
    mobile_normalized TEXT,
    marital_status TEXT,
    living_status_note TEXT,
    photo_attachment_id TEXT,
    profile_status TEXT NOT NULL,
    death_date TEXT,
    general_note TEXT,

    CONSTRAINT uq_elders__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_elders__institution_elder_code UNIQUE (institution_id, elder_code),
    CONSTRAINT fk_elders__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_elders__created_by_staff FOREIGN KEY (institution_id, created_by_staff_id)
        REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_elders__updated_by_staff FOREIGN KEY (institution_id, updated_by_staff_id)
        REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_elders__photo_attachment FOREIGN KEY (institution_id, photo_attachment_id)
        REFERENCES attachments(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_elders__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (photo_attachment_id IS NULL OR length(photo_attachment_id) = 26)
    ),
    CONSTRAINT ck_elders__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_elders__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_elders__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_elders__required_text CHECK (
        length(trim(elder_code)) > 0 AND length(trim(full_name)) > 0
    ),
    CONSTRAINT ck_elders__gender CHECK (
        gender IS NULL OR gender IN ('male', 'female', 'unknown')
    ),
    CONSTRAINT ck_elders__birth_date CHECK (
        birth_date IS NULL OR (
            length(birth_date) = 10
            AND birth_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(birth_date) = birth_date
        )
    ),
    CONSTRAINT ck_elders__identity CHECK (
        (id_type IS NULL AND id_number IS NULL AND id_number_normalized IS NULL)
        OR (
            id_type IN ('national_id', 'passport', 'residence_permit', 'other')
            AND id_number IS NOT NULL AND length(trim(id_number)) > 0
        )
    ),
    CONSTRAINT ck_elders__mobile_projection CHECK (
        mobile_normalized IS NULL OR mobile IS NOT NULL
    ),
    CONSTRAINT ck_elders__marital_status CHECK (
        marital_status IS NULL OR marital_status IN (
            'unmarried', 'married', 'divorced', 'widowed', 'unknown'
        )
    ),
    CONSTRAINT ck_elders__profile_status CHECK (
        profile_status IN ('active', 'inactive', 'deceased')
        AND (profile_status = 'deceased' OR death_date IS NULL)
    ),
    CONSTRAINT ck_elders__death_date CHECK (
        death_date IS NULL OR (
            length(death_date) = 10
            AND death_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(death_date) = death_date
        )
    )
) STRICT;

CREATE TABLE elder_contacts (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    elder_id TEXT NOT NULL,
    full_name TEXT NOT NULL,
    relationship_to_elder TEXT NOT NULL,
    mobile TEXT,
    mobile_normalized TEXT,
    phone TEXT,
    phone_normalized TEXT,
    id_type TEXT,
    id_number TEXT,
    id_number_normalized TEXT,
    address_json TEXT,
    preferred_contact_method TEXT,
    contact_note TEXT,
    status TEXT NOT NULL,

    CONSTRAINT uq_elder_contacts__institution_id UNIQUE (institution_id, id),
    CONSTRAINT fk_elder_contacts__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_elder_contacts__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_elder_contacts__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_elder_contacts__elder FOREIGN KEY (institution_id, elder_id)
        REFERENCES elders(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_elder_contacts__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(elder_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_elder_contacts__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_elder_contacts__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_elder_contacts__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_elder_contacts__full_name CHECK (length(trim(full_name)) > 0),
    CONSTRAINT ck_elder_contacts__relationship CHECK (
        relationship_to_elder IN (
            'self', 'spouse', 'child', 'sibling', 'relative', 'friend', 'organization', 'other'
        )
    ),
    CONSTRAINT ck_elder_contacts__contact_channels CHECK (
        (mobile IS NOT NULL AND length(trim(mobile)) > 0)
        OR (phone IS NOT NULL AND length(trim(phone)) > 0)
    ),
    CONSTRAINT ck_elder_contacts__contact_projections CHECK (
        (mobile_normalized IS NULL OR mobile IS NOT NULL)
        AND (phone_normalized IS NULL OR phone IS NOT NULL)
    ),
    CONSTRAINT ck_elder_contacts__identity CHECK (
        (id_type IS NULL AND id_number IS NULL AND id_number_normalized IS NULL)
        OR (
            id_type IN ('national_id', 'passport', 'residence_permit', 'other')
            AND id_number IS NOT NULL AND length(trim(id_number)) > 0
        )
    ),
    CONSTRAINT ck_elder_contacts__address_json CHECK (
        address_json IS NULL OR (
            json_valid(address_json)
            AND json_type(address_json) = 'object'
            AND json_type(address_json, '$.schema_version') = 'integer'
            AND json_extract(address_json, '$.schema_version') > 0
        )
    ),
    CONSTRAINT ck_elder_contacts__preferred_contact_method CHECK (
        preferred_contact_method IS NULL OR preferred_contact_method IN (
            'mobile', 'phone', 'wechat', 'in_person', 'other'
        )
    ),
    CONSTRAINT ck_elder_contacts__status CHECK (status IN ('active', 'inactive'))
) STRICT;

CREATE TABLE contact_role_assignments (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    elder_contact_id TEXT NOT NULL,
    role_type TEXT NOT NULL,
    is_primary_for_role INTEGER NOT NULL,
    effective_from_date TEXT NOT NULL,
    effective_to_date TEXT,
    basis_note TEXT,

    CONSTRAINT uq_contact_role_assignments__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_contact_role_assignments__contact_role_start UNIQUE (
        institution_id, elder_contact_id, role_type, effective_from_date
    ),
    CONSTRAINT fk_contact_role_assignments__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_contact_role_assignments__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_contact_role_assignments__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_contact_role_assignments__elder_contact FOREIGN KEY (
        institution_id, elder_contact_id
    ) REFERENCES elder_contacts(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_contact_role_assignments__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(elder_contact_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_contact_role_assignments__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_contact_role_assignments__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_contact_role_assignments__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_contact_role_assignments__role_type CHECK (
        role_type IN ('primary', 'emergency', 'payer', 'signer', 'guardian_claim')
    ),
    CONSTRAINT ck_contact_role_assignments__is_primary CHECK (is_primary_for_role IN (0, 1)),
    CONSTRAINT ck_contact_role_assignments__dates CHECK (
        length(effective_from_date) = 10
        AND effective_from_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
        AND date(effective_from_date) = effective_from_date
        AND (effective_to_date IS NULL OR (
            length(effective_to_date) = 10
            AND effective_to_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(effective_to_date) = effective_to_date
            AND effective_to_date >= effective_from_date
        ))
    )
) STRICT;

CREATE TABLE elder_addresses (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    elder_id TEXT NOT NULL,
    address_type TEXT NOT NULL,
    province_code TEXT NOT NULL,
    city_code TEXT NOT NULL,
    district_code TEXT NOT NULL,
    address_detail TEXT NOT NULL,
    contact_at_address TEXT,
    phone_at_address TEXT,
    access_note TEXT,
    effective_from_date TEXT NOT NULL,
    effective_to_date TEXT,

    CONSTRAINT uq_elder_addresses__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_elder_addresses__elder_type_start UNIQUE (
        institution_id, elder_id, address_type, effective_from_date
    ),
    CONSTRAINT fk_elder_addresses__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_elder_addresses__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_elder_addresses__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_elder_addresses__elder FOREIGN KEY (institution_id, elder_id)
        REFERENCES elders(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_elder_addresses__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(elder_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_elder_addresses__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_elder_addresses__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_elder_addresses__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_elder_addresses__address_type CHECK (
        address_type IN ('residence', 'contact', 'service_candidate', 'other')
    ),
    CONSTRAINT ck_elder_addresses__address CHECK (
        length(province_code) = 2 AND province_code NOT GLOB '*[^0-9]*'
        AND length(city_code) = 4 AND city_code NOT GLOB '*[^0-9]*'
        AND length(district_code) = 6 AND district_code NOT GLOB '*[^0-9]*'
        AND length(trim(address_detail)) > 0
    ),
    CONSTRAINT ck_elder_addresses__dates CHECK (
        length(effective_from_date) = 10
        AND effective_from_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
        AND date(effective_from_date) = effective_from_date
        AND (effective_to_date IS NULL OR (
            length(effective_to_date) = 10
            AND effective_to_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(effective_to_date) = effective_to_date
            AND effective_to_date >= effective_from_date
        ))
    )
) STRICT;

CREATE TABLE external_assessment_records (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    elder_id TEXT NOT NULL,
    assessment_type TEXT NOT NULL,
    assessment_level TEXT,
    assessed_date TEXT,
    assessor_name TEXT,
    valid_to_date TEXT,
    report_attachment_id TEXT,
    source_note TEXT,

    CONSTRAINT uq_external_assessment_records__institution_id UNIQUE (institution_id, id),
    CONSTRAINT fk_external_assessment_records__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_external_assessment_records__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_external_assessment_records__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_external_assessment_records__elder FOREIGN KEY (institution_id, elder_id)
        REFERENCES elders(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_external_assessment_records__report_attachment FOREIGN KEY (
        institution_id, report_attachment_id
    ) REFERENCES attachments(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_external_assessment_records__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(elder_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (report_attachment_id IS NULL OR length(report_attachment_id) = 26)
    ),
    CONSTRAINT ck_external_assessment_records__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_external_assessment_records__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_external_assessment_records__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_external_assessment_records__assessment_type CHECK (
        length(trim(assessment_type)) > 0
    ),
    CONSTRAINT ck_external_assessment_records__dates CHECK (
        (assessed_date IS NULL OR (
            length(assessed_date) = 10
            AND assessed_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(assessed_date) = assessed_date
        ))
        AND (valid_to_date IS NULL OR (
            length(valid_to_date) = 10
            AND valid_to_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(valid_to_date) = valid_to_date
        ))
        AND (assessed_date IS NULL OR valid_to_date IS NULL OR valid_to_date >= assessed_date)
    )
) STRICT;

CREATE TABLE service_relationships (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    relationship_code TEXT NOT NULL,
    elder_id TEXT NOT NULL,
    scene TEXT NOT NULL,
    status TEXT NOT NULL,
    planned_start_date TEXT NOT NULL,
    actual_start_at TEXT,
    ended_at TEXT,
    end_reason TEXT,

    CONSTRAINT uq_service_relationships__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_service_relationships__institution_relationship_code UNIQUE (
        institution_id, relationship_code
    ),
    CONSTRAINT fk_service_relationships__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_relationships__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_relationships__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_relationships__elder FOREIGN KEY (institution_id, elder_id)
        REFERENCES elders(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_service_relationships__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(elder_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_service_relationships__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_service_relationships__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
        AND (actual_start_at IS NULL OR (
            length(actual_start_at) = 24
            AND strftime('%Y-%m-%dT%H:%M:%fZ', actual_start_at) = actual_start_at
        ))
        AND (ended_at IS NULL OR (
            length(ended_at) = 24
            AND strftime('%Y-%m-%dT%H:%M:%fZ', ended_at) = ended_at
        ))
        AND (actual_start_at IS NULL OR ended_at IS NULL OR ended_at >= actual_start_at)
    ),
    CONSTRAINT ck_service_relationships__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_service_relationships__relationship_code CHECK (
        length(trim(relationship_code)) > 0
    ),
    CONSTRAINT ck_service_relationships__scene CHECK (
        scene IN ('home', 'day', 'residential', 'respite')
    ),
    CONSTRAINT ck_service_relationships__planned_start_date CHECK (
        length(planned_start_date) = 10
        AND planned_start_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
        AND date(planned_start_date) = planned_start_date
    ),
    CONSTRAINT ck_service_relationships__status CHECK (
        status IN ('draft', 'pending', 'active', 'paused', 'ended', 'cancelled')
        AND (status NOT IN ('active', 'paused', 'ended') OR actual_start_at IS NOT NULL)
        AND (status = 'ended' OR ended_at IS NULL)
        AND (status <> 'ended' OR ended_at IS NOT NULL)
        AND (
            status NOT IN ('ended', 'cancelled')
            OR (end_reason IS NOT NULL AND length(trim(end_reason)) > 0)
        )
        AND (status IN ('ended', 'cancelled') OR end_reason IS NULL)
    )
) STRICT;

CREATE TABLE service_agreements (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    agreement_code TEXT NOT NULL,
    elder_id TEXT NOT NULL,
    service_relationship_id TEXT NOT NULL,
    signer_contact_id TEXT NOT NULL,
    signed_date TEXT,
    effective_from_date TEXT NOT NULL,
    effective_to_date TEXT,
    agreement_attachment_id TEXT,
    status TEXT NOT NULL,
    note TEXT,

    CONSTRAINT uq_service_agreements__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_service_agreements__institution_agreement_code UNIQUE (
        institution_id, agreement_code
    ),
    CONSTRAINT fk_service_agreements__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_agreements__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_agreements__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_agreements__elder FOREIGN KEY (institution_id, elder_id)
        REFERENCES elders(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_agreements__service_relationship FOREIGN KEY (
        institution_id, service_relationship_id
    ) REFERENCES service_relationships(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_agreements__signer_contact FOREIGN KEY (
        institution_id, signer_contact_id
    ) REFERENCES elder_contacts(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_service_agreements__attachment FOREIGN KEY (
        institution_id, agreement_attachment_id
    ) REFERENCES attachments(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_service_agreements__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(elder_id) = 26 AND length(service_relationship_id) = 26
        AND length(signer_contact_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (agreement_attachment_id IS NULL OR length(agreement_attachment_id) = 26)
    ),
    CONSTRAINT ck_service_agreements__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_service_agreements__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_service_agreements__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_service_agreements__agreement_code CHECK (length(trim(agreement_code)) > 0),
    CONSTRAINT ck_service_agreements__dates CHECK (
        (signed_date IS NULL OR (
            length(signed_date) = 10
            AND signed_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(signed_date) = signed_date
        ))
        AND length(effective_from_date) = 10
        AND effective_from_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
        AND date(effective_from_date) = effective_from_date
        AND (effective_to_date IS NULL OR (
            length(effective_to_date) = 10
            AND effective_to_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(effective_to_date) = effective_to_date
            AND effective_to_date >= effective_from_date
        ))
    ),
    CONSTRAINT ck_service_agreements__status CHECK (
        status IN ('draft', 'active', 'expired', 'terminated')
    )
) STRICT;

CREATE TABLE relationship_versions (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    service_relationship_id TEXT NOT NULL,
    version_no INTEGER NOT NULL,
    effective_from_at TEXT NOT NULL,
    effective_to_at TEXT,
    site_id TEXT NOT NULL,
    primary_contact_id TEXT NOT NULL,
    emergency_contact_id TEXT,
    payer_contact_id TEXT NOT NULL,
    agreement_id TEXT,
    change_type TEXT NOT NULL,
    change_reason TEXT,
    activated_by_staff_id TEXT NOT NULL,

    CONSTRAINT uq_relationship_versions__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_relationship_versions__relationship_version UNIQUE (
        institution_id, service_relationship_id, version_no
    ),
    CONSTRAINT fk_relationship_versions__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_versions__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_versions__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_versions__service_relationship FOREIGN KEY (
        institution_id, service_relationship_id
    ) REFERENCES service_relationships(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_versions__site FOREIGN KEY (institution_id, site_id)
        REFERENCES service_sites(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_versions__primary_contact FOREIGN KEY (
        institution_id, primary_contact_id
    ) REFERENCES elder_contacts(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_versions__emergency_contact FOREIGN KEY (
        institution_id, emergency_contact_id
    ) REFERENCES elder_contacts(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_versions__payer_contact FOREIGN KEY (
        institution_id, payer_contact_id
    ) REFERENCES elder_contacts(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_versions__agreement FOREIGN KEY (institution_id, agreement_id)
        REFERENCES service_agreements(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_versions__activated_by_staff FOREIGN KEY (
        institution_id, activated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_relationship_versions__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(service_relationship_id) = 26 AND length(site_id) = 26
        AND length(primary_contact_id) = 26 AND length(payer_contact_id) = 26
        AND length(activated_by_staff_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (emergency_contact_id IS NULL OR length(emergency_contact_id) = 26)
        AND (agreement_id IS NULL OR length(agreement_id) = 26)
    ),
    CONSTRAINT ck_relationship_versions__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_relationship_versions__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND length(effective_from_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', effective_from_at) = effective_from_at
        AND (effective_to_at IS NULL OR (
            length(effective_to_at) = 24
            AND strftime('%Y-%m-%dT%H:%M:%fZ', effective_to_at) = effective_to_at
            AND effective_to_at >= effective_from_at
        ))
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_relationship_versions__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_relationship_versions__version_no CHECK (version_no > 0),
    CONSTRAINT ck_relationship_versions__change_type CHECK (
        change_type IN (
            'initial', 'address', 'site', 'resource', 'package',
            'price', 'contact', 'agreement', 'other'
        )
    ),
    CONSTRAINT ck_relationship_versions__change_reason CHECK (
        version_no = 1 OR (change_reason IS NOT NULL AND length(trim(change_reason)) > 0)
    )
) STRICT;

CREATE TABLE home_relationship_profiles (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    relationship_version_id TEXT NOT NULL,
    home_service_area_id TEXT NOT NULL,
    service_address_id TEXT NOT NULL,
    preferred_visit_windows_json TEXT,
    entry_instruction TEXT,
    travel_note TEXT,

    CONSTRAINT uq_home_relationship_profiles__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_home_relationship_profiles__relationship_version UNIQUE (
        institution_id, relationship_version_id
    ),
    CONSTRAINT fk_home_relationship_profiles__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_relationship_profiles__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_relationship_profiles__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_relationship_profiles__relationship_version FOREIGN KEY (
        institution_id, relationship_version_id
    ) REFERENCES relationship_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_relationship_profiles__home_service_area FOREIGN KEY (
        institution_id, home_service_area_id
    ) REFERENCES home_service_areas(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_home_relationship_profiles__service_address FOREIGN KEY (
        institution_id, service_address_id
    ) REFERENCES elder_addresses(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_home_relationship_profiles__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(relationship_version_id) = 26
        AND length(home_service_area_id) = 26 AND length(service_address_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_home_relationship_profiles__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_home_relationship_profiles__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_home_relationship_profiles__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_home_relationship_profiles__visit_windows_json CHECK (
        preferred_visit_windows_json IS NULL OR (
            json_valid(preferred_visit_windows_json)
            AND json_type(preferred_visit_windows_json) = 'object'
            AND json_type(preferred_visit_windows_json, '$.schema_version') = 'integer'
            AND json_extract(preferred_visit_windows_json, '$.schema_version') > 0
        )
    )
) STRICT;

CREATE TABLE day_relationship_profiles (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    relationship_version_id TEXT NOT NULL,
    day_care_area_id TEXT NOT NULL,
    expected_arrival_time TEXT,
    expected_departure_time TEXT,
    transport_mode TEXT,
    transport_note TEXT,

    CONSTRAINT uq_day_relationship_profiles__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_day_relationship_profiles__relationship_version UNIQUE (
        institution_id, relationship_version_id
    ),
    CONSTRAINT fk_day_relationship_profiles__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_relationship_profiles__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_relationship_profiles__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_relationship_profiles__relationship_version FOREIGN KEY (
        institution_id, relationship_version_id
    ) REFERENCES relationship_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_relationship_profiles__day_care_area FOREIGN KEY (
        institution_id, day_care_area_id
    ) REFERENCES day_care_areas(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_day_relationship_profiles__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(relationship_version_id) = 26 AND length(day_care_area_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_day_relationship_profiles__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_day_relationship_profiles__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_day_relationship_profiles__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_day_relationship_profiles__times CHECK (
        (expected_arrival_time IS NULL OR (
            length(expected_arrival_time) = 8
            AND expected_arrival_time GLOB '[0-2][0-9]:[0-5][0-9]:[0-5][0-9]'
            AND time(expected_arrival_time) = expected_arrival_time
        ))
        AND (expected_departure_time IS NULL OR (
            length(expected_departure_time) = 8
            AND expected_departure_time GLOB '[0-2][0-9]:[0-5][0-9]:[0-5][0-9]'
            AND time(expected_departure_time) = expected_departure_time
        ))
        AND (
            expected_arrival_time IS NULL OR expected_departure_time IS NULL
            OR expected_departure_time >= expected_arrival_time
        )
    ),
    CONSTRAINT ck_day_relationship_profiles__transport_mode CHECK (
        transport_mode IS NULL OR transport_mode IN (
            'self', 'family', 'institution', 'public_transport', 'other'
        )
    )
) STRICT;

CREATE TABLE day_relationship_attendance_days (
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    day_relationship_profile_id TEXT NOT NULL,
    weekday TEXT NOT NULL,

    CONSTRAINT pk_day_relationship_attendance_days PRIMARY KEY (
        institution_id, day_relationship_profile_id, weekday
    ),
    CONSTRAINT fk_day_relationship_attendance_days__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_relationship_attendance_days__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_day_relationship_attendance_days__profile FOREIGN KEY (
        institution_id, day_relationship_profile_id
    ) REFERENCES day_relationship_profiles(institution_id, id)
        ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT ck_day_relationship_attendance_days__ulids CHECK (
        length(institution_id) = 26 AND length(day_relationship_profile_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
    ),
    CONSTRAINT ck_day_relationship_attendance_days__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_day_relationship_attendance_days__created_at CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
    ),
    CONSTRAINT ck_day_relationship_attendance_days__weekday CHECK (
        weekday IN (
            'monday', 'tuesday', 'wednesday', 'thursday',
            'friday', 'saturday', 'sunday'
        )
    )
) STRICT;

CREATE TABLE residential_relationship_profiles (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    relationship_version_id TEXT NOT NULL,
    planned_check_in_at TEXT NOT NULL,
    actual_check_in_at TEXT,
    care_note TEXT,
    dietary_note TEXT,
    risk_note TEXT,

    CONSTRAINT uq_residential_relationship_profiles__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_residential_relationship_profiles__relationship_version UNIQUE (
        institution_id, relationship_version_id
    ),
    CONSTRAINT fk_residential_relationship_profiles__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_residential_relationship_profiles__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_residential_relationship_profiles__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_residential_relationship_profiles__relationship_version FOREIGN KEY (
        institution_id, relationship_version_id
    ) REFERENCES relationship_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_residential_relationship_profiles__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(relationship_version_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_residential_relationship_profiles__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_residential_relationship_profiles__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND length(planned_check_in_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', planned_check_in_at) = planned_check_in_at
        AND (actual_check_in_at IS NULL OR (
            length(actual_check_in_at) = 24
            AND strftime('%Y-%m-%dT%H:%M:%fZ', actual_check_in_at) = actual_check_in_at
        ))
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_residential_relationship_profiles__record_version CHECK (record_version >= 1)
) STRICT;

CREATE TABLE respite_relationship_profiles (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    relationship_version_id TEXT NOT NULL,
    respite_type TEXT NOT NULL,
    planned_start_at TEXT NOT NULL,
    planned_end_at TEXT NOT NULL,
    actual_start_at TEXT,
    actual_end_at TEXT,
    care_note TEXT,

    CONSTRAINT uq_respite_relationship_profiles__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_respite_relationship_profiles__relationship_version UNIQUE (
        institution_id, relationship_version_id
    ),
    CONSTRAINT fk_respite_relationship_profiles__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_respite_relationship_profiles__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_respite_relationship_profiles__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_respite_relationship_profiles__relationship_version FOREIGN KEY (
        institution_id, relationship_version_id
    ) REFERENCES relationship_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_respite_relationship_profiles__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26 AND length(relationship_version_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_respite_relationship_profiles__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_respite_relationship_profiles__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND length(planned_start_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', planned_start_at) = planned_start_at
        AND length(planned_end_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', planned_end_at) = planned_end_at
        AND planned_end_at > planned_start_at
        AND (actual_start_at IS NULL OR (
            length(actual_start_at) = 24
            AND strftime('%Y-%m-%dT%H:%M:%fZ', actual_start_at) = actual_start_at
        ))
        AND (actual_end_at IS NULL OR (
            length(actual_end_at) = 24
            AND strftime('%Y-%m-%dT%H:%M:%fZ', actual_end_at) = actual_end_at
        ))
        AND (actual_end_at IS NULL OR actual_start_at IS NOT NULL)
        AND (actual_start_at IS NULL OR actual_end_at IS NULL OR actual_end_at >= actual_start_at)
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_respite_relationship_profiles__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_respite_relationship_profiles__respite_type CHECK (
        respite_type IN ('overnight', 'daytime', 'short_stay', 'other')
    )
) STRICT;

CREATE TABLE resource_assignments (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    relationship_version_id TEXT NOT NULL,
    accommodation_position_id TEXT NOT NULL,
    assignment_type TEXT NOT NULL,
    start_at TEXT NOT NULL,
    end_at TEXT,
    status TEXT NOT NULL,
    change_reason TEXT,

    CONSTRAINT uq_resource_assignments__institution_id UNIQUE (institution_id, id),
    CONSTRAINT fk_resource_assignments__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_resource_assignments__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_resource_assignments__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_resource_assignments__relationship_version FOREIGN KEY (
        institution_id, relationship_version_id
    ) REFERENCES relationship_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_resource_assignments__accommodation_position FOREIGN KEY (
        institution_id, accommodation_position_id
    ) REFERENCES accommodation_positions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_resource_assignments__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(relationship_version_id) = 26 AND length(accommodation_position_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_resource_assignments__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_resource_assignments__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND length(start_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', start_at) = start_at
        AND (end_at IS NULL OR (
            length(end_at) = 24
            AND strftime('%Y-%m-%dT%H:%M:%fZ', end_at) = end_at
            AND end_at >= start_at
        ))
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_resource_assignments__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_resource_assignments__assignment_type CHECK (
        assignment_type IN ('residential', 'respite_dedicated', 'respite_shared')
        AND (assignment_type = 'residential' OR end_at IS NOT NULL)
    ),
    CONSTRAINT ck_resource_assignments__status CHECK (
        status IN ('reserved', 'active', 'ended', 'cancelled')
        AND (status <> 'ended' OR end_at IS NOT NULL)
        AND (
            status NOT IN ('ended', 'cancelled')
            OR (change_reason IS NOT NULL AND length(trim(change_reason)) > 0)
        )
    )
) STRICT;

CREATE TABLE relationship_package_snapshots (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    relationship_version_id TEXT NOT NULL,
    source_package_version_id TEXT NOT NULL,
    package_code_snapshot TEXT NOT NULL,
    package_name_snapshot TEXT NOT NULL,
    billing_cycle_snapshot TEXT NOT NULL,
    package_price_snapshot_cents INTEGER NOT NULL,
    adjustment_reason TEXT,

    CONSTRAINT uq_relationship_package_snapshots__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_relationship_package_snapshots__relationship_version UNIQUE (
        institution_id, relationship_version_id
    ),
    CONSTRAINT fk_relationship_package_snapshots__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_package_snapshots__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_package_snapshots__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_package_snapshots__relationship_version FOREIGN KEY (
        institution_id, relationship_version_id
    ) REFERENCES relationship_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_package_snapshots__source_package_version FOREIGN KEY (
        institution_id, source_package_version_id
    ) REFERENCES package_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_relationship_package_snapshots__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(relationship_version_id) = 26 AND length(source_package_version_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_relationship_package_snapshots__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_relationship_package_snapshots__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_relationship_package_snapshots__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_relationship_package_snapshots__required_text CHECK (
        length(trim(package_code_snapshot)) > 0 AND length(trim(package_name_snapshot)) > 0
    ),
    CONSTRAINT ck_relationship_package_snapshots__billing_cycle CHECK (
        billing_cycle_snapshot IN ('week', 'month', 'agreed', 'one_time')
    ),
    CONSTRAINT ck_relationship_package_snapshots__package_price CHECK (
        package_price_snapshot_cents >= 0
    )
) STRICT;

CREATE TABLE relationship_entitlement_snapshots (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    relationship_package_snapshot_id TEXT NOT NULL,
    source_service_item_id TEXT NOT NULL,
    service_code_snapshot TEXT NOT NULL,
    service_name_snapshot TEXT NOT NULL,
    entitlement_type TEXT NOT NULL,
    quota_quantity_milli INTEGER,
    quota_unit TEXT,
    quota_cycle TEXT,
    overage_policy TEXT NOT NULL,

    CONSTRAINT uq_relationship_entitlement_snapshots__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_relationship_entitlement_snapshots__package_service UNIQUE (
        institution_id, relationship_package_snapshot_id, source_service_item_id
    ),
    CONSTRAINT fk_relationship_entitlement_snapshots__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_entitlement_snapshots__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_entitlement_snapshots__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_entitlement_snapshots__package_snapshot FOREIGN KEY (
        institution_id, relationship_package_snapshot_id
    ) REFERENCES relationship_package_snapshots(institution_id, id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_entitlement_snapshots__source_service_item FOREIGN KEY (
        institution_id, source_service_item_id
    ) REFERENCES service_items(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_relationship_entitlement_snapshots__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(relationship_package_snapshot_id) = 26 AND length(source_service_item_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_relationship_entitlement_snapshots__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_relationship_entitlement_snapshots__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_relationship_entitlement_snapshots__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_relationship_entitlement_snapshots__required_text CHECK (
        length(trim(service_code_snapshot)) > 0 AND length(trim(service_name_snapshot)) > 0
    ),
    CONSTRAINT ck_relationship_entitlement_snapshots__quota_group CHECK (
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
    CONSTRAINT ck_relationship_entitlement_snapshots__overage_policy CHECK (
        overage_policy IN ('prompt_extra', 'gift', 'allow_overuse', 'manual')
    )
) STRICT;

CREATE TABLE relationship_pricing_snapshots (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    relationship_version_id TEXT NOT NULL,
    source_charge_item_id TEXT NOT NULL,
    source_price_version_id TEXT,
    charge_code_snapshot TEXT NOT NULL,
    charge_name_snapshot TEXT NOT NULL,
    charge_unit_snapshot TEXT NOT NULL,
    standard_amount_snapshot_cents INTEGER,
    actual_amount_cents INTEGER NOT NULL,
    pricing_basis TEXT NOT NULL,
    adjustment_reason TEXT,

    CONSTRAINT uq_relationship_pricing_snapshots__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_relationship_pricing_snapshots__relationship_charge UNIQUE (
        institution_id, relationship_version_id, source_charge_item_id
    ),
    CONSTRAINT fk_relationship_pricing_snapshots__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_pricing_snapshots__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_pricing_snapshots__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_pricing_snapshots__relationship_version FOREIGN KEY (
        institution_id, relationship_version_id
    ) REFERENCES relationship_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_pricing_snapshots__source_charge_item FOREIGN KEY (
        institution_id, source_charge_item_id
    ) REFERENCES charge_items(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_relationship_pricing_snapshots__source_price_version FOREIGN KEY (
        institution_id, source_price_version_id
    ) REFERENCES price_versions(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_relationship_pricing_snapshots__ulids CHECK (
        length(id) = 26 AND length(institution_id) = 26
        AND length(relationship_version_id) = 26 AND length(source_charge_item_id) = 26
        AND (source_price_version_id IS NULL OR length(source_price_version_id) = 26)
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_relationship_pricing_snapshots__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_relationship_pricing_snapshots__timestamps CHECK (
        length(created_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24 AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_relationship_pricing_snapshots__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_relationship_pricing_snapshots__required_text CHECK (
        length(trim(charge_code_snapshot)) > 0 AND length(trim(charge_name_snapshot)) > 0
    ),
    CONSTRAINT ck_relationship_pricing_snapshots__charge_unit CHECK (
        charge_unit_snapshot IN (
            'per_time', 'per_minute', 'per_hour', 'per_item', 'per_portion',
            'per_day', 'per_week', 'per_month', 'one_time', 'package_fixed'
        )
    ),
    CONSTRAINT ck_relationship_pricing_snapshots__amounts CHECK (
        (standard_amount_snapshot_cents IS NULL OR standard_amount_snapshot_cents >= 0)
        AND actual_amount_cents >= 0
    ),
    CONSTRAINT ck_relationship_pricing_snapshots__pricing_basis CHECK (
        pricing_basis IN ('standard', 'package', 'agreement', 'manual')
        AND (pricing_basis <> 'standard' OR source_price_version_id IS NOT NULL)
    ),
    CONSTRAINT ck_relationship_pricing_snapshots__adjustment_reason CHECK (
        (
            pricing_basis = 'standard'
            AND standard_amount_snapshot_cents IS NOT NULL
            AND actual_amount_cents = standard_amount_snapshot_cents
        )
        OR (adjustment_reason IS NOT NULL AND length(trim(adjustment_reason)) > 0)
    )
) STRICT;
