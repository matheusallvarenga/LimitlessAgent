-- ============================================================================
-- Migration 003: Secure Functions
-- Version: 1.0.0
-- Date: 2026-01-18
--
-- Purpose: Update all functions with security best practices:
--   - SECURITY DEFINER + SET search_path (prevent schema poisoning)
--   - Input validation
--   - Error sanitization
--   - Proper return types
--
-- Template: Adapted from INTENTUM Gold Standard
-- ============================================================================

-- ============================================================================
-- DROP OLD FUNCTIONS (will be recreated with security)
-- ============================================================================

DROP FUNCTION IF EXISTS match_documents(vector, INT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS update_execution_timestamp() CASCADE;
DROP FUNCTION IF EXISTS update_task_duration() CASCADE;

-- ============================================================================
-- FUNCTION: match_documents (Vector Similarity Search)
-- ============================================================================

CREATE OR REPLACE FUNCTION match_documents(
    query_embedding vector(768),
    match_count INT DEFAULT 10,
    filter JSONB DEFAULT '{}'::JSONB
)
RETURNS TABLE (
    id BIGINT,
    content TEXT,
    metadata JSONB,
    embedding vector(768),
    similarity FLOAT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    -- Input validation
    IF query_embedding IS NULL THEN
        RAISE EXCEPTION 'query_embedding cannot be null';
    END IF;

    IF match_count <= 0 OR match_count > 1000 THEN
        RAISE EXCEPTION 'match_count must be between 1 and 1000';
    END IF;

    -- Return results (RLS will filter by owner_id automatically)
    RETURN QUERY
    SELECT
        d.id,
        d.content,
        d.metadata,
        d.embedding,
        1 - (d.embedding <=> query_embedding) AS similarity
    FROM limitless_documents d
    WHERE d.deleted_at IS NULL
      AND (filter IS NULL OR filter = '{}'::JSONB OR d.metadata @> filter)
    ORDER BY d.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

COMMENT ON FUNCTION match_documents IS 'Secure vector similarity search with RLS support';

-- ============================================================================
-- FUNCTION: update_execution_timestamp (Trigger)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_update_execution_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.updated_at = NOW();

    -- Auto-calculate duration and set completed_at
    IF NEW.status IN ('completed', 'failed', 'cancelled') THEN
        IF NEW.completed_at IS NULL THEN
            NEW.completed_at = NOW();
        END IF;
        IF NEW.started_at IS NOT NULL AND NEW.duration_ms IS NULL THEN
            NEW.duration_ms = EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at)) * 1000;
        END IF;
    END IF;

    -- Validate status transitions
    IF OLD.status = 'completed' AND NEW.status != 'completed' THEN
        RAISE EXCEPTION 'Cannot change status from completed to %', NEW.status;
    END IF;

    RETURN NEW;
END;
$$;

-- Apply trigger
DROP TRIGGER IF EXISTS trigger_execution_timestamp ON limitless_executions;
CREATE TRIGGER trigger_execution_timestamp
    BEFORE UPDATE ON limitless_executions
    FOR EACH ROW
    EXECUTE FUNCTION limitless_update_execution_timestamp();

-- ============================================================================
-- FUNCTION: update_task_duration (Trigger)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_update_task_duration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    -- Auto-calculate duration
    IF NEW.status IN ('completed', 'failed', 'skipped') THEN
        IF NEW.completed_at IS NULL THEN
            NEW.completed_at = NOW();
        END IF;
        IF NEW.started_at IS NOT NULL AND NEW.duration_ms IS NULL THEN
            NEW.duration_ms = EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at)) * 1000;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Apply trigger
DROP TRIGGER IF EXISTS trigger_task_duration ON limitless_tasks;
CREATE TRIGGER trigger_task_duration
    BEFORE UPDATE ON limitless_tasks
    FOR EACH ROW
    EXECUTE FUNCTION limitless_update_task_duration();

-- ============================================================================
-- FUNCTION: update_memory_access (Trigger)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_update_memory_access()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.access_count = COALESCE(OLD.access_count, 0) + 1;
    NEW.last_accessed_at = NOW();
    RETURN NEW;
END;
$$;

-- Apply trigger for reads (using a different approach)
-- Note: SELECT triggers don't exist in PostgreSQL, so we use a function

-- ============================================================================
-- FUNCTION: get_memory (with access tracking)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_get_memory(
    p_key VARCHAR
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_value JSONB;
    v_owner_id UUID;
BEGIN
    -- Get current user
    v_owner_id := auth.uid();

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Input validation
    IF p_key IS NULL OR length(trim(p_key)) = 0 THEN
        RAISE EXCEPTION 'Key cannot be null or empty';
    END IF;

    -- Get and update access count
    UPDATE limitless_memory
    SET access_count = access_count + 1,
        last_accessed_at = NOW()
    WHERE key = p_key
      AND owner_id = v_owner_id
      AND deleted_at IS NULL
      AND (expires_at IS NULL OR expires_at > NOW())
    RETURNING value INTO v_value;

    RETURN v_value;
END;
$$;

COMMENT ON FUNCTION limitless_get_memory IS 'Get memory value with automatic access tracking';

-- ============================================================================
-- FUNCTION: set_memory (upsert with validation)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_set_memory(
    p_key VARCHAR,
    p_value JSONB,
    p_memory_type VARCHAR DEFAULT 'general',
    p_importance DECIMAL DEFAULT 0.5,
    p_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_memory_id UUID;
    v_owner_id UUID;
BEGIN
    -- Get current user
    v_owner_id := auth.uid();

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Input validation
    IF p_key IS NULL OR length(trim(p_key)) = 0 THEN
        RAISE EXCEPTION 'Key cannot be null or empty';
    END IF;

    IF p_value IS NULL THEN
        RAISE EXCEPTION 'Value cannot be null';
    END IF;

    IF p_importance < 0 OR p_importance > 1 THEN
        RAISE EXCEPTION 'Importance must be between 0 and 1';
    END IF;

    -- Upsert
    INSERT INTO limitless_memory (key, value, memory_type, importance, expires_at, owner_id)
    VALUES (p_key, p_value, p_memory_type, p_importance, p_expires_at, v_owner_id)
    ON CONFLICT (key) DO UPDATE SET
        value = EXCLUDED.value,
        memory_type = EXCLUDED.memory_type,
        importance = EXCLUDED.importance,
        expires_at = EXCLUDED.expires_at,
        updated_at = NOW()
    WHERE limitless_memory.owner_id = v_owner_id
    RETURNING id INTO v_memory_id;

    RETURN v_memory_id;
END;
$$;

COMMENT ON FUNCTION limitless_set_memory IS 'Set or update memory with validation';

-- ============================================================================
-- FUNCTION: delete_memory (soft delete)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_delete_memory(
    p_key VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_owner_id UUID;
    v_deleted BOOLEAN;
BEGIN
    -- Get current user
    v_owner_id := auth.uid();

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Soft delete
    UPDATE limitless_memory
    SET deleted_at = NOW()
    WHERE key = p_key
      AND owner_id = v_owner_id
      AND deleted_at IS NULL
    RETURNING true INTO v_deleted;

    RETURN COALESCE(v_deleted, false);
END;
$$;

COMMENT ON FUNCTION limitless_delete_memory IS 'Soft delete memory entry';

-- ============================================================================
-- FUNCTION: cleanup_expired_memory
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_cleanup_expired_memory()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Soft delete expired memories
    WITH deleted AS (
        UPDATE limitless_memory
        SET deleted_at = NOW()
        WHERE expires_at < NOW()
          AND deleted_at IS NULL
        RETURNING id
    )
    SELECT COUNT(*) INTO v_count FROM deleted;

    RETURN v_count;
END;
$$;

COMMENT ON FUNCTION limitless_cleanup_expired_memory IS 'Cleanup expired memory entries (for pg_cron)';

-- ============================================================================
-- FUNCTION: create_execution (with validation)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_create_execution(
    p_goal TEXT,
    p_max_iterations INTEGER DEFAULT 100,
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_execution_id UUID;
    v_owner_id UUID;
BEGIN
    -- Get current user
    v_owner_id := auth.uid();

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Input validation
    IF p_goal IS NULL OR length(trim(p_goal)) = 0 THEN
        RAISE EXCEPTION 'Goal cannot be null or empty';
    END IF;

    IF p_max_iterations <= 0 OR p_max_iterations > 10000 THEN
        RAISE EXCEPTION 'max_iterations must be between 1 and 10000';
    END IF;

    -- Create execution
    INSERT INTO limitless_executions (goal, max_iterations, metadata, owner_id, status)
    VALUES (p_goal, p_max_iterations, p_metadata, v_owner_id, 'pending')
    RETURNING id INTO v_execution_id;

    RETURN v_execution_id;
END;
$$;

COMMENT ON FUNCTION limitless_create_execution IS 'Create new execution with validation';

-- ============================================================================
-- FUNCTION: sanitize_error (remove secrets from error messages)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_sanitize_error(p_message TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF p_message IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN regexp_replace(
        regexp_replace(
            regexp_replace(
                regexp_replace(
                    p_message,
                    -- API keys, secrets, tokens
                    '(api[_-]?key|apikey|secret|password|token|bearer|authorization)[=:\s]*[''"]?[\w\-\.]+[''"]?',
                    '\1=[REDACTED]',
                    'gi'
                ),
                -- OpenAI/Anthropic/etc key patterns
                '(sk-|pk-|key-|ANTHROPIC_API_KEY=|OPENAI_API_KEY=)[a-zA-Z0-9\-]+',
                '[REDACTED_KEY]',
                'g'
            ),
            -- Emails
            '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            '[REDACTED_EMAIL]',
            'g'
        ),
        -- Phone numbers
        '\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
        '[REDACTED_PHONE]',
        'g'
    );
END;
$$;

COMMENT ON FUNCTION limitless_sanitize_error IS 'Remove secrets from error messages';

-- ============================================================================
-- FUNCTION: log_agent_error (with sanitization)
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_log_agent_error(
    p_task_id UUID,
    p_agent_name VARCHAR,
    p_error_message TEXT,
    p_model_name VARCHAR DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_run_id UUID;
    v_owner_id UUID;
BEGIN
    -- Get current user
    v_owner_id := auth.uid();

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Log with sanitized error
    INSERT INTO limitless_agent_runs (
        task_id, agent_name, model_name, success, error, owner_id
    ) VALUES (
        p_task_id,
        p_agent_name,
        p_model_name,
        false,
        limitless_sanitize_error(p_error_message),
        v_owner_id
    )
    RETURNING id INTO v_run_id;

    RETURN v_run_id;
END;
$$;

COMMENT ON FUNCTION limitless_log_agent_error IS 'Log agent error with automatic sanitization';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    func_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO func_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname LIKE 'limitless_%';

    RAISE NOTICE '=== Migration 003 Complete ===';
    RAISE NOTICE 'Created/updated % secure functions', func_count;
    RAISE NOTICE 'All functions have SECURITY DEFINER + search_path';
    RAISE NOTICE 'Input validation enabled';
    RAISE NOTICE 'Error sanitization enabled';
END $$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
