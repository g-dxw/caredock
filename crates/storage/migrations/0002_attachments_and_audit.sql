CREATE TABLE attachments (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    created_by_staff_id TEXT,
    created_source TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    updated_by_staff_id TEXT,
    record_version INTEGER NOT NULL,
    attachment_code TEXT NOT NULL,
    original_file_name TEXT NOT NULL,
    media_type TEXT NOT NULL,
    file_size_bytes INTEGER NOT NULL,
    content_hash_sha256 TEXT NOT NULL,
    local_storage_key TEXT NOT NULL,
    sensitivity_level TEXT NOT NULL,
    captured_at TEXT,
    uploaded_at TEXT NOT NULL,
    status TEXT NOT NULL,

    CONSTRAINT uq_attachments__institution_id UNIQUE (institution_id, id),
    CONSTRAINT uq_attachments__institution_attachment_code UNIQUE (
        institution_id, attachment_code
    ),
    CONSTRAINT uq_attachments__institution_local_storage_key UNIQUE (
        institution_id, local_storage_key
    ),
    CONSTRAINT fk_attachments__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_attachments__ulids CHECK (
        length(id) = 26
        AND length(institution_id) = 26
        AND (created_by_staff_id IS NULL OR length(created_by_staff_id) = 26)
        AND (updated_by_staff_id IS NULL OR length(updated_by_staff_id) = 26)
    ),
    CONSTRAINT ck_attachments__created_source CHECK (
        created_source IN ('manual', 'import', 'system', 'demo')
    ),
    CONSTRAINT ck_attachments__timestamps CHECK (
        length(created_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at) = created_at
        AND length(updated_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at) = updated_at
        AND length(uploaded_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', uploaded_at) = uploaded_at
        AND (captured_at IS NULL OR (
            length(captured_at) = 24
            AND strftime('%Y-%m-%dT%H:%M:%fZ', captured_at) = captured_at
        ))
        AND updated_at >= created_at
        AND uploaded_at >= created_at
    ),
    CONSTRAINT ck_attachments__record_version CHECK (record_version >= 1),
    CONSTRAINT ck_attachments__required_text CHECK (
        length(trim(attachment_code)) > 0
        AND length(trim(original_file_name)) > 0
        AND length(trim(media_type)) > 0
        AND length(trim(local_storage_key)) > 0
    ),
    CONSTRAINT ck_attachments__file_size_nonnegative CHECK (file_size_bytes >= 0),
    CONSTRAINT ck_attachments__content_hash_sha256 CHECK (
        length(content_hash_sha256) = 64
        AND content_hash_sha256 NOT GLOB '*[^0-9a-f]*'
    ),
    CONSTRAINT ck_attachments__local_storage_key_relative CHECK (
        substr(local_storage_key, 1, 1) <> '/'
        AND instr(local_storage_key, '\\') = 0
        AND local_storage_key <> '..'
        AND local_storage_key NOT LIKE '../%'
        AND local_storage_key NOT LIKE '%/../%'
        AND local_storage_key NOT LIKE '%/..'
    ),
    CONSTRAINT ck_attachments__sensitivity_level CHECK (
        sensitivity_level IN ('L0', 'L1', 'L2', 'L3', 'L4')
    ),
    CONSTRAINT ck_attachments__status CHECK (
        status IN ('active', 'orphaned', 'archived')
    )
) STRICT;

CREATE TABLE audit_events (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL,
    occurred_at TEXT NOT NULL,
    operator_staff_id TEXT,
    event_source TEXT NOT NULL,
    action TEXT NOT NULL,
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    summary TEXT NOT NULL,
    before_digest TEXT,
    after_digest TEXT,
    reason TEXT,

    CONSTRAINT uq_audit_events__institution_id UNIQUE (institution_id, id),
    CONSTRAINT fk_audit_events__institution FOREIGN KEY (institution_id)
        REFERENCES institutions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_audit_events__ulids CHECK (
        length(id) = 26
        AND length(institution_id) = 26
        AND length(target_id) = 26
        AND (operator_staff_id IS NULL OR length(operator_staff_id) = 26)
    ),
    CONSTRAINT ck_audit_events__occurred_at CHECK (
        length(occurred_at) = 24
        AND strftime('%Y-%m-%dT%H:%M:%fZ', occurred_at) = occurred_at
    ),
    CONSTRAINT ck_audit_events__event_source CHECK (
        event_source IN ('user', 'system', 'import', 'demo')
    ),
    CONSTRAINT ck_audit_events__action CHECK (
        action IN (
            'create', 'update', 'activate', 'pause', 'resume', 'end', 'confirm',
            'assign', 'execute', 'correct', 'void', 'import', 'export', 'backup',
            'restore', 'reset'
        )
    ),
    CONSTRAINT ck_audit_events__required_text CHECK (
        length(trim(target_type)) > 0
        AND length(trim(summary)) > 0
    )
) STRICT;
