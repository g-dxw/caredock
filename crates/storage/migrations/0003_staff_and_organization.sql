CREATE TABLE staff_members (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    staff_code TEXT NOT NULL,
    full_name TEXT NOT NULL,
    gender TEXT,
    birth_date TEXT,
    id_type TEXT,
    id_number TEXT,
    id_number_normalized TEXT,
    mobile TEXT,
    mobile_normalized TEXT,
    email TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    avatar_attachment_id TEXT,
    profile_note TEXT,

    CONSTRAINT uq_staff_members__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_staff_members__institution_staff_code UNIQUE (institution_id, staff_code),
    CONSTRAINT fk_staff_members__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_staff_members__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_staff_members__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_staff_members__avatar_attachment FOREIGN KEY (
        institution_id, avatar_attachment_id
    ) REFERENCES attachments(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_staff_members__ulids CHECK (
        length(id) = 26
        AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (avatar_attachment_id IS NULL OR length(avatar_attachment_id) = 26)
    ),
    CONSTRAINT ck_staff_members__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_staff_members__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_staff_members__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_staff_members__required_text CHECK (
        length(trim(staff_code)) > 0 AND length(trim(full_name)) > 0
    ),
    CONSTRAINT ck_staff_members__gender CHECK (
        gender IS NULL OR gender IN ('male', 'female', 'unknown')
    ),
    CONSTRAINT ck_staff_members__birth_date CHECK (
        birth_date IS NULL OR (
            length(birth_date) = 10
            AND birth_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(birth_date) = birth_date
        )
    ),
    CONSTRAINT ck_staff_members__identity CHECK (
        (id_type IS NULL AND id_number IS NULL AND id_number_normalized IS NULL)
        OR (
            id_type IN ('national_id', 'passport', 'residence_permit', 'other')
            AND id_number IS NOT NULL
            AND length(trim(id_number)) > 0
        )
    ),
    CONSTRAINT ck_staff_members__mobile_projection CHECK (
        mobile_normalized IS NULL OR mobile IS NOT NULL
    )
) STRICT;

CREATE TABLE departments (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    parent_id TEXT,
    department_code TEXT NOT NULL,
    name TEXT NOT NULL,
    manager_staff_id TEXT,
    sort_order INTEGER NOT NULL,
    status TEXT NOT NULL,

    CONSTRAINT uq_departments__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_departments__institution_department_code UNIQUE (
        institution_id, department_code
    ),
    CONSTRAINT fk_departments__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_departments__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_departments__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_departments__parent FOREIGN KEY (institution_id, parent_id)
        REFERENCES departments(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_departments__manager_staff FOREIGN KEY (
        institution_id, manager_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_departments__ulids CHECK (
        length(id) = 26
        AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (parent_id IS NULL OR length(parent_id) = 26)
        AND (manager_staff_id IS NULL OR length(manager_staff_id) = 26)
        AND parent_id IS NOT id
    ),
    CONSTRAINT ck_departments__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_departments__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_departments__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_departments__required_text CHECK (
        length(trim(department_code)) > 0 AND length(trim(name)) > 0
    ),
    CONSTRAINT ck_departments__sort_order CHECK (sort_order >= 0),
    CONSTRAINT ck_departments__status CHECK (status IN ('active', 'inactive'))
) STRICT;

CREATE TABLE employment_periods (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    staff_id TEXT NOT NULL,
    employment_type TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT,
    status TEXT NOT NULL,
    employer_name TEXT,
    personnel_note TEXT,

    CONSTRAINT uq_employment_periods__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_employment_periods__staff_type_start UNIQUE (
        institution_id, staff_id, employment_type, start_date
    ),
    CONSTRAINT fk_employment_periods__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_employment_periods__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_employment_periods__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_employment_periods__staff FOREIGN KEY (institution_id, staff_id)
        REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_employment_periods__ulids CHECK (
        length(id) = 26
        AND length(institution_id) = 26
        AND length(staff_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_employment_periods__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_employment_periods__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_employment_periods__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_employment_periods__employment_type CHECK (
        employment_type IN ('formal', 'part_time', 'dispatched', 'outsourced', 'volunteer')
    ),
    CONSTRAINT ck_employment_periods__dates CHECK (
        length(start_date) = 10
        AND start_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
        AND date(start_date) = start_date
        AND (end_date IS NULL OR (
            length(end_date) = 10
            AND end_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(end_date) = end_date
            AND end_date >= start_date
        ))
    ),
    CONSTRAINT ck_employment_periods__status CHECK (
        status IN ('planned', 'active', 'ended')
        AND (status <> 'ended' OR end_date IS NOT NULL)
    ),
    CONSTRAINT ck_employment_periods__employer CHECK (
        employer_name IS NULL OR length(trim(employer_name)) > 0
    )
) STRICT;

CREATE TABLE position_assignments (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    staff_id TEXT NOT NULL,
    position_code TEXT NOT NULL,
    position_name_snapshot TEXT NOT NULL,
    department_id TEXT,
    is_primary INTEGER NOT NULL,
    effective_from_date TEXT NOT NULL,
    effective_to_date TEXT,

    CONSTRAINT uq_position_assignments__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_position_assignments__staff_position_start UNIQUE (
        institution_id, staff_id, position_code, effective_from_date
    ),
    CONSTRAINT fk_position_assignments__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_position_assignments__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_position_assignments__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_position_assignments__staff FOREIGN KEY (institution_id, staff_id)
        REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_position_assignments__department FOREIGN KEY (
        institution_id, department_id
    ) REFERENCES departments(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_position_assignments__ulids CHECK (
        length(id) = 26
        AND length(institution_id) = 26
        AND length(staff_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (department_id IS NULL OR length(department_id) = 26)
    ),
    CONSTRAINT ck_position_assignments__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_position_assignments__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_position_assignments__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_position_assignments__position CHECK (
        position_code IN (
            'admin', 'manager', 'caregiver', 'nurse', 'social_worker',
            'rehabilitation', 'kitchen', 'finance', 'driver', 'other'
        )
        AND length(trim(position_name_snapshot)) > 0
    ),
    CONSTRAINT ck_position_assignments__is_primary CHECK (is_primary IN (0, 1)),
    CONSTRAINT ck_position_assignments__dates CHECK (
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

CREATE TABLE staff_qualifications (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    staff_id TEXT NOT NULL,
    qualification_type TEXT NOT NULL,
    certificate_name TEXT NOT NULL,
    certificate_number TEXT,
    certificate_number_normalized TEXT,
    issuing_authority TEXT,
    valid_from_date TEXT,
    valid_to_date TEXT,
    certificate_attachment_id TEXT,
    verification_status TEXT NOT NULL,
    note TEXT,

    CONSTRAINT uq_staff_qualifications__institution_id UNIQUE (institution_id, id),
    CONSTRAINT fk_staff_qualifications__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_staff_qualifications__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_staff_qualifications__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_staff_qualifications__staff FOREIGN KEY (institution_id, staff_id)
        REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_staff_qualifications__certificate_attachment FOREIGN KEY (
        institution_id, certificate_attachment_id
    ) REFERENCES attachments(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_staff_qualifications__ulids CHECK (
        length(id) = 26
        AND length(institution_id) = 26
        AND length(staff_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
        AND (certificate_attachment_id IS NULL OR length(certificate_attachment_id) = 26)
    ),
    CONSTRAINT ck_staff_qualifications__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_staff_qualifications__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_staff_qualifications__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_staff_qualifications__qualification_type CHECK (
        qualification_type IN (
            'elderly_care', 'nursing', 'rehabilitation', 'social_work',
            'first_aid', 'food_safety', 'driver', 'other'
        )
    ),
    CONSTRAINT ck_staff_qualifications__certificate CHECK (
        length(trim(certificate_name)) > 0
        AND (certificate_number_normalized IS NULL OR certificate_number IS NOT NULL)
    ),
    CONSTRAINT ck_staff_qualifications__dates CHECK (
        (valid_from_date IS NULL OR (
            length(valid_from_date) = 10
            AND valid_from_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(valid_from_date) = valid_from_date
        ))
        AND (valid_to_date IS NULL OR (
            length(valid_to_date) = 10
            AND valid_to_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
            AND date(valid_to_date) = valid_to_date
        ))
        AND (valid_from_date IS NULL OR valid_to_date IS NULL OR valid_to_date >= valid_from_date)
    ),
    CONSTRAINT ck_staff_qualifications__verification_status CHECK (
        verification_status IN ('unverified', 'verified', 'rejected')
    )
) STRICT;

CREATE TABLE operator_eligibilities (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    staff_id TEXT NOT NULL,
    eligible INTEGER NOT NULL,
    effective_from_date TEXT NOT NULL,
    effective_to_date TEXT,
    granted_reason TEXT,

    CONSTRAINT uq_operator_eligibilities__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_operator_eligibilities__staff_start UNIQUE (
        institution_id, staff_id, effective_from_date
    ),
    CONSTRAINT fk_operator_eligibilities__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_operator_eligibilities__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_operator_eligibilities__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_operator_eligibilities__staff FOREIGN KEY (institution_id, staff_id)
        REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_operator_eligibilities__ulids CHECK (
        length(id) = 26
        AND length(institution_id) = 26
        AND length(staff_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_operator_eligibilities__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_operator_eligibilities__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_operator_eligibilities__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_operator_eligibilities__eligible CHECK (eligible IN (0, 1)),
    CONSTRAINT ck_operator_eligibilities__dates CHECK (
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
