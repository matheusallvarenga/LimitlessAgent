-- ============================================================================
-- Migration 004: LGPD Integration
-- Version: 1.0.0
-- Date: 2026-01-18
--
-- Purpose: Integrate Limitless Agent with the shared_ LGPD infrastructure
--          (consent, data requests, deletion log, anonymization)
--
-- Note: Core LGPD tables are in shared_ schema (migration 006)
--       This migration adds domain-specific functions for Limitless
--
-- Template: Adapted from INTENTUM Gold Standard
-- ============================================================================

-- ============================================================================
-- FUNCTION: Export user data (LGPD Right to Portability)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_export_user_data(
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_owner_id UUID;
    v_result JSONB;
BEGIN
    -- Use provided user_id or current auth user
    v_owner_id := COALESCE(p_user_id, auth.uid());

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'User ID required';
    END IF;

    -- Compile all user data
    SELECT jsonb_build_object(
        'exported_at', NOW(),
        'domain', 'limitless',
        'user_id', v_owner_id,
        'executions', (
            SELECT COALESCE(jsonb_agg(row_to_json(e.*)), '[]'::jsonb)
            FROM limitless_executions e
            WHERE e.owner_id = v_owner_id AND e.deleted_at IS NULL
        ),
        'tasks', (
            SELECT COALESCE(jsonb_agg(row_to_json(t.*)), '[]'::jsonb)
            FROM limitless_tasks t
            WHERE t.owner_id = v_owner_id AND t.deleted_at IS NULL
        ),
        'memory', (
            SELECT COALESCE(jsonb_agg(row_to_json(m.*)), '[]'::jsonb)
            FROM limitless_memory m
            WHERE m.owner_id = v_owner_id AND m.deleted_at IS NULL
        ),
        'documents', (
            SELECT COALESCE(jsonb_agg(
                jsonb_build_object(
                    'id', d.id,
                    'doc_id', d.doc_id,
                    'doc_title', d.doc_title,
                    'doc_type', d.doc_type,
                    'source', d.source,
                    'created_at', d.created_at
                    -- Note: content and embedding excluded for size
                )
            ), '[]'::jsonb)
            FROM limitless_documents d
            WHERE d.owner_id = v_owner_id AND d.deleted_at IS NULL
        ),
        'agent_runs', (
            SELECT COALESCE(jsonb_agg(row_to_json(r.*)), '[]'::jsonb)
            FROM limitless_agent_runs r
            WHERE r.owner_id = v_owner_id AND r.deleted_at IS NULL
        ),
        'metrics', (
            SELECT COALESCE(jsonb_agg(row_to_json(m.*)), '[]'::jsonb)
            FROM limitless_metrics m
            WHERE m.owner_id = v_owner_id AND m.deleted_at IS NULL
        )
    ) INTO v_result;

    -- Log the export (for audit)
    PERFORM shared_log_audit(
        'limitless'::domain_type,
        'user_data',
        v_owner_id,
        'export'::audit_action,
        v_owner_id,
        NULL,
        'LGPD data export requested'
    );

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION limitless_export_user_data IS 'LGPD: Export all user data for portability';

-- ============================================================================
-- FUNCTION: Anonymize user data (LGPD Right to Erasure)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_anonymize_user_data(
    p_user_id UUID,
    p_reason TEXT DEFAULT 'LGPD erasure request'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_counts JSONB;
    v_executions_count INTEGER;
    v_tasks_count INTEGER;
    v_memory_count INTEGER;
    v_documents_count INTEGER;
    v_agent_runs_count INTEGER;
    v_metrics_count INTEGER;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID required';
    END IF;

    -- Anonymize executions (keep structure for analytics, remove PII)
    WITH updated AS (
        UPDATE limitless_executions
        SET goal = '[ANONYMIZED]',
            result = '{"anonymized": true}'::jsonb,
            error = CASE WHEN error IS NOT NULL THEN '[ANONYMIZED]' ELSE NULL END,
            metadata = '{"anonymized": true}'::jsonb,
            deleted_at = NOW()
        WHERE owner_id = p_user_id AND deleted_at IS NULL
        RETURNING id
    )
    SELECT COUNT(*) INTO v_executions_count FROM updated;

    -- Log deletions
    INSERT INTO shared_deletion_log (domain, table_name, record_id, deleted_by, deletion_reason, record_summary)
    SELECT 'limitless', 'limitless_executions', id, p_user_id, p_reason,
           jsonb_build_object('anonymized_at', NOW())
    FROM limitless_executions WHERE owner_id = p_user_id;

    -- Anonymize tasks
    WITH updated AS (
        UPDATE limitless_tasks
        SET name = '[ANONYMIZED]',
            description = NULL,
            input = '{"anonymized": true}'::jsonb,
            output = '{"anonymized": true}'::jsonb,
            error = CASE WHEN error IS NOT NULL THEN '[ANONYMIZED]' ELSE NULL END,
            deleted_at = NOW()
        WHERE owner_id = p_user_id AND deleted_at IS NULL
        RETURNING id
    )
    SELECT COUNT(*) INTO v_tasks_count FROM updated;

    -- Anonymize memory (completely remove - contains user context)
    WITH updated AS (
        UPDATE limitless_memory
        SET key = 'anonymized_' || id::text,
            value = '{"anonymized": true}'::jsonb,
            deleted_at = NOW()
        WHERE owner_id = p_user_id AND deleted_at IS NULL
        RETURNING id
    )
    SELECT COUNT(*) INTO v_memory_count FROM updated;

    -- Anonymize documents (remove content, keep metadata for analytics)
    WITH updated AS (
        UPDATE limitless_documents
        SET content = '[ANONYMIZED]',
            embedding = NULL,
            metadata = '{"anonymized": true}'::jsonb,
            deleted_at = NOW()
        WHERE owner_id = p_user_id AND deleted_at IS NULL
        RETURNING id
    )
    SELECT COUNT(*) INTO v_documents_count FROM updated;

    -- Anonymize agent runs
    WITH updated AS (
        UPDATE limitless_agent_runs
        SET error = CASE WHEN error IS NOT NULL THEN '[ANONYMIZED]' ELSE NULL END,
            deleted_at = NOW()
        WHERE owner_id = p_user_id AND deleted_at IS NULL
        RETURNING id
    )
    SELECT COUNT(*) INTO v_agent_runs_count FROM updated;

    -- Keep metrics (anonymized aggregate data, useful for analytics)
    WITH updated AS (
        UPDATE limitless_metrics
        SET deleted_at = NOW()
        WHERE owner_id = p_user_id AND deleted_at IS NULL
        RETURNING id
    )
    SELECT COUNT(*) INTO v_metrics_count FROM updated;

    -- Build result
    v_counts := jsonb_build_object(
        'anonymized_at', NOW(),
        'user_id', p_user_id,
        'reason', p_reason,
        'counts', jsonb_build_object(
            'executions', v_executions_count,
            'tasks', v_tasks_count,
            'memory', v_memory_count,
            'documents', v_documents_count,
            'agent_runs', v_agent_runs_count,
            'metrics', v_metrics_count
        )
    );

    -- Log the anonymization
    PERFORM shared_log_audit(
        'limitless'::domain_type,
        'user_data',
        p_user_id,
        'delete'::audit_action,
        p_user_id,
        v_counts,
        'LGPD data anonymization completed'
    );

    RETURN v_counts;
END;
$$;

COMMENT ON FUNCTION limitless_anonymize_user_data IS 'LGPD: Anonymize all user data (right to erasure)';

-- ============================================================================
-- FUNCTION: Get user data summary (for transparency)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_get_data_summary(
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_owner_id UUID;
BEGIN
    v_owner_id := COALESCE(p_user_id, auth.uid());

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'User ID required';
    END IF;

    RETURN jsonb_build_object(
        'domain', 'limitless',
        'user_id', v_owner_id,
        'generated_at', NOW(),
        'data_summary', jsonb_build_object(
            'executions', jsonb_build_object(
                'total', (SELECT COUNT(*) FROM limitless_executions WHERE owner_id = v_owner_id AND deleted_at IS NULL),
                'completed', (SELECT COUNT(*) FROM limitless_executions WHERE owner_id = v_owner_id AND status = 'completed' AND deleted_at IS NULL),
                'failed', (SELECT COUNT(*) FROM limitless_executions WHERE owner_id = v_owner_id AND status = 'failed' AND deleted_at IS NULL)
            ),
            'tasks', jsonb_build_object(
                'total', (SELECT COUNT(*) FROM limitless_tasks WHERE owner_id = v_owner_id AND deleted_at IS NULL)
            ),
            'memory', jsonb_build_object(
                'total', (SELECT COUNT(*) FROM limitless_memory WHERE owner_id = v_owner_id AND deleted_at IS NULL),
                'types', (
                    SELECT COALESCE(jsonb_object_agg(memory_type, cnt), '{}'::jsonb)
                    FROM (
                        SELECT memory_type, COUNT(*) as cnt
                        FROM limitless_memory
                        WHERE owner_id = v_owner_id AND deleted_at IS NULL
                        GROUP BY memory_type
                    ) t
                )
            ),
            'documents', jsonb_build_object(
                'total', (SELECT COUNT(*) FROM limitless_documents WHERE owner_id = v_owner_id AND deleted_at IS NULL)
            ),
            'agent_runs', jsonb_build_object(
                'total', (SELECT COUNT(*) FROM limitless_agent_runs WHERE owner_id = v_owner_id AND deleted_at IS NULL),
                'success_rate', (
                    SELECT ROUND(
                        COUNT(CASE WHEN success THEN 1 END)::DECIMAL /
                        NULLIF(COUNT(*), 0) * 100, 2
                    )
                    FROM limitless_agent_runs
                    WHERE owner_id = v_owner_id AND deleted_at IS NULL
                )
            ),
            'first_activity', (
                SELECT MIN(created_at)
                FROM limitless_executions
                WHERE owner_id = v_owner_id
            ),
            'last_activity', (
                SELECT MAX(created_at)
                FROM limitless_executions
                WHERE owner_id = v_owner_id
            )
        )
    );
END;
$$;

COMMENT ON FUNCTION limitless_get_data_summary IS 'LGPD: Get summary of user data (transparency)';

-- ============================================================================
-- FUNCTION: Apply data retention policy
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_apply_retention_policy(
    p_retention_days INTEGER DEFAULT 365
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_cutoff_date TIMESTAMP WITH TIME ZONE;
    v_counts JSONB;
    v_executions_count INTEGER;
    v_tasks_count INTEGER;
    v_memory_count INTEGER;
    v_documents_count INTEGER;
BEGIN
    v_cutoff_date := NOW() - (p_retention_days || ' days')::INTERVAL;

    -- Archive/delete old executions (already soft-deleted)
    WITH deleted AS (
        DELETE FROM limitless_executions
        WHERE deleted_at IS NOT NULL
          AND deleted_at < v_cutoff_date
        RETURNING id
    )
    SELECT COUNT(*) INTO v_executions_count FROM deleted;

    -- Archive/delete old tasks
    WITH deleted AS (
        DELETE FROM limitless_tasks
        WHERE deleted_at IS NOT NULL
          AND deleted_at < v_cutoff_date
        RETURNING id
    )
    SELECT COUNT(*) INTO v_tasks_count FROM deleted;

    -- Archive/delete expired memory
    WITH deleted AS (
        DELETE FROM limitless_memory
        WHERE (deleted_at IS NOT NULL AND deleted_at < v_cutoff_date)
           OR (expires_at IS NOT NULL AND expires_at < v_cutoff_date)
        RETURNING id
    )
    SELECT COUNT(*) INTO v_memory_count FROM deleted;

    -- Archive/delete old documents
    WITH deleted AS (
        DELETE FROM limitless_documents
        WHERE deleted_at IS NOT NULL
          AND deleted_at < v_cutoff_date
        RETURNING id
    )
    SELECT COUNT(*) INTO v_documents_count FROM deleted;

    v_counts := jsonb_build_object(
        'retention_days', p_retention_days,
        'cutoff_date', v_cutoff_date,
        'deleted', jsonb_build_object(
            'executions', v_executions_count,
            'tasks', v_tasks_count,
            'memory', v_memory_count,
            'documents', v_documents_count
        )
    );

    -- Log the retention run
    PERFORM shared_log_audit(
        'limitless'::domain_type,
        'retention_policy',
        NULL,
        'delete'::audit_action,
        NULL,
        v_counts,
        'Data retention policy applied'
    );

    RETURN v_counts;
END;
$$;

COMMENT ON FUNCTION limitless_apply_retention_policy IS 'LGPD: Apply data retention policy (for pg_cron)';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== Migration 004 Complete ===';
    RAISE NOTICE 'LGPD functions created:';
    RAISE NOTICE '  - limitless_export_user_data() - Right to portability';
    RAISE NOTICE '  - limitless_anonymize_user_data() - Right to erasure';
    RAISE NOTICE '  - limitless_get_data_summary() - Transparency';
    RAISE NOTICE '  - limitless_apply_retention_policy() - Data retention';
    RAISE NOTICE '';
    RAISE NOTICE 'Note: Core LGPD tables are in shared_ schema';
    RAISE NOTICE '      Configure pg_cron for retention_policy execution';
END $$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
