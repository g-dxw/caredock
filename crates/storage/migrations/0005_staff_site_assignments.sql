CREATE TABLE site_assignments (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    staff_id TEXT NOT NULL,
    site_id TEXT NOT NULL,
    is_primary INTEGER NOT NULL,
    effective_from_date TEXT NOT NULL,
    effective_to_date TEXT,

    CONSTRAINT uq_site_assignments__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_site_assignments__staff_site_start UNIQUE (
        institution_id, staff_id, site_id, effective_from_date
    ),
    CONSTRAINT fk_site_assignments__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_site_assignments__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_site_assignments__updated_by_staff FOREIGN KEY (
        institution_id, updated_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_site_assignments__staff FOREIGN KEY (institution_id, staff_id)
        REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_site_assignments__site FOREIGN KEY (institution_id, site_id)
        REFERENCES service_sites(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_site_assignments__ulids CHECK (
        length(id) = 26
        AND length(institution_id) = 26
        AND length(staff_id) = 26
        AND length(site_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_site_assignments__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_site_assignments__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND updated_at >= created_at
    ),
    CONSTRAINT ck_site_assignments__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_site_assignments__is_primary CHECK (is_primary IN (0, 1)),
    CONSTRAINT ck_site_assignments__dates CHECK (
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

CREATE TABLE site_assignment_scenes (
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    site_assignment_id TEXT NOT NULL,
    scene TEXT NOT NULL,

    CONSTRAINT pk_site_assignment_scenes PRIMARY KEY (
        institution_id, site_assignment_id, scene
    ),
    CONSTRAINT fk_site_assignment_scenes__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_site_assignment_scenes__created_by_staff FOREIGN KEY (
        institution_id, created_by_staff_id
    ) REFERENCES staff_members(institution_id, id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_site_assignment_scenes__site_assignment FOREIGN KEY (
        institution_id, site_assignment_id
    ) REFERENCES site_assignments(institution_id, id) ON UPDATE RESTRICT ON DELETE CASCADE,
    CONSTRAINT ck_site_assignment_scenes__ulids CHECK (
        length(institution_id) = 26
        AND length(site_assignment_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
    ),
    CONSTRAINT ck_site_assignment_scenes__record_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_site_assignment_scenes__created_at CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
    ),
    CONSTRAINT ck_site_assignment_scenes__scene CHECK (
        scene IN ('home', 'day', 'residential', 'respite')
    )
) STRICT;
