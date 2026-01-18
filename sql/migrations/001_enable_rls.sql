-- ============================================================================
-- Migration 001: Enable Row Level Security
-- Version: 1.0.0
-- Date: 2026-01-18
--
-- Purpose: Enable RLS on all Limitless Agent tables and create policies
--          that ensure users can only access their own data.
--
-- Security Model:
--   - owner_id column added to all tables
--   - RLS policies use (SELECT auth.uid()) pattern for performance
--   - Service role bypasses RLS for admin operations
--
-- Template: Adapted from INTENTUM Gold Standard (score 9.47/10)
-- ============================================================================

-- ============================================================================
-- STEP 1: Add owner_id to all tables
-- ============================================================================

-- Add owner_id to limitless_executions
ALTER TABLE limitless_executions
    ADD COLUMN IF NOT EXISTS owner_id UUID;

-- Add owner_id to limitless_tasks
ALTER TABLE limitless_tasks
    ADD COLUMN IF NOT EXISTS owner_id UUID;

-- Add owner_id to limitless_memory
ALTER TABLE limitless_memory
    ADD COLUMN IF NOT EXISTS owner_id UUID;

-- Add owner_id to limitless_documents
ALTER TABLE limitless_documents
    ADD COLUMN IF NOT EXISTS owner_id UUID;

-- Add owner_id to limitless_agent_runs
ALTER TABLE limitless_agent_runs
    ADD COLUMN IF NOT EXISTS owner_id UUID;

-- Add owner_id to limitless_metrics
ALTER TABLE limitless_metrics
    ADD COLUMN IF NOT EXISTS owner_id UUID;

-- ============================================================================
-- STEP 2: Create indexes on owner_id for performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_limitless_executions_owner
    ON limitless_executions(owner_id);

CREATE INDEX IF NOT EXISTS idx_limitless_tasks_owner
    ON limitless_tasks(owner_id);

CREATE INDEX IF NOT EXISTS idx_limitless_memory_owner
    ON limitless_memory(owner_id);

CREATE INDEX IF NOT EXISTS idx_limitless_documents_owner
    ON limitless_documents(owner_id);

CREATE INDEX IF NOT EXISTS idx_limitless_agent_runs_owner
    ON limitless_agent_runs(owner_id);

CREATE INDEX IF NOT EXISTS idx_limitless_metrics_owner
    ON limitless_metrics(owner_id);

-- ============================================================================
-- STEP 3: Enable RLS on all tables
-- ============================================================================

ALTER TABLE limitless_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE limitless_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE limitless_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE limitless_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE limitless_agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE limitless_metrics ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 4: Create RLS Policies
-- ============================================================================

-- Note: Using (SELECT auth.uid()) pattern for 94-99% performance improvement
-- vs direct auth.uid() call

-- ---------------------------------------------------------------------------
-- Policies for limitless_executions
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view own executions" ON limitless_executions;
CREATE POLICY "Users can view own executions"
    ON limitless_executions FOR SELECT
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create own executions" ON limitless_executions;
CREATE POLICY "Users can create own executions"
    ON limitless_executions FOR INSERT
    WITH CHECK (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own executions" ON limitless_executions;
CREATE POLICY "Users can update own executions"
    ON limitless_executions FOR UPDATE
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete own executions" ON limitless_executions;
CREATE POLICY "Users can delete own executions"
    ON limitless_executions FOR DELETE
    USING (owner_id = (SELECT auth.uid()));

-- ---------------------------------------------------------------------------
-- Policies for limitless_tasks
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view own tasks" ON limitless_tasks;
CREATE POLICY "Users can view own tasks"
    ON limitless_tasks FOR SELECT
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create own tasks" ON limitless_tasks;
CREATE POLICY "Users can create own tasks"
    ON limitless_tasks FOR INSERT
    WITH CHECK (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own tasks" ON limitless_tasks;
CREATE POLICY "Users can update own tasks"
    ON limitless_tasks FOR UPDATE
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete own tasks" ON limitless_tasks;
CREATE POLICY "Users can delete own tasks"
    ON limitless_tasks FOR DELETE
    USING (owner_id = (SELECT auth.uid()));

-- ---------------------------------------------------------------------------
-- Policies for limitless_memory
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view own memory" ON limitless_memory;
CREATE POLICY "Users can view own memory"
    ON limitless_memory FOR SELECT
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create own memory" ON limitless_memory;
CREATE POLICY "Users can create own memory"
    ON limitless_memory FOR INSERT
    WITH CHECK (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own memory" ON limitless_memory;
CREATE POLICY "Users can update own memory"
    ON limitless_memory FOR UPDATE
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete own memory" ON limitless_memory;
CREATE POLICY "Users can delete own memory"
    ON limitless_memory FOR DELETE
    USING (owner_id = (SELECT auth.uid()));

-- ---------------------------------------------------------------------------
-- Policies for limitless_documents
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view own documents" ON limitless_documents;
CREATE POLICY "Users can view own documents"
    ON limitless_documents FOR SELECT
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create own documents" ON limitless_documents;
CREATE POLICY "Users can create own documents"
    ON limitless_documents FOR INSERT
    WITH CHECK (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own documents" ON limitless_documents;
CREATE POLICY "Users can update own documents"
    ON limitless_documents FOR UPDATE
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete own documents" ON limitless_documents;
CREATE POLICY "Users can delete own documents"
    ON limitless_documents FOR DELETE
    USING (owner_id = (SELECT auth.uid()));

-- ---------------------------------------------------------------------------
-- Policies for limitless_agent_runs
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view own agent runs" ON limitless_agent_runs;
CREATE POLICY "Users can view own agent runs"
    ON limitless_agent_runs FOR SELECT
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create own agent runs" ON limitless_agent_runs;
CREATE POLICY "Users can create own agent runs"
    ON limitless_agent_runs FOR INSERT
    WITH CHECK (owner_id = (SELECT auth.uid()));

-- Agent runs are typically read-only after creation (no update/delete policies)

-- ---------------------------------------------------------------------------
-- Policies for limitless_metrics
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view own metrics" ON limitless_metrics;
CREATE POLICY "Users can view own metrics"
    ON limitless_metrics FOR SELECT
    USING (owner_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create own metrics" ON limitless_metrics;
CREATE POLICY "Users can create own metrics"
    ON limitless_metrics FOR INSERT
    WITH CHECK (owner_id = (SELECT auth.uid()));

-- Metrics are typically read-only after creation (no update/delete policies)

-- ============================================================================
-- STEP 5: Create helper function to get current user's owner_id
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_get_owner_id()
RETURNS UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT auth.uid();
$$;

-- ============================================================================
-- STEP 6: Create trigger to auto-populate owner_id
-- ============================================================================

CREATE OR REPLACE FUNCTION limitless_set_owner_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.owner_id IS NULL THEN
        NEW.owner_id := auth.uid();
    END IF;
    RETURN NEW;
END;
$$;

-- Apply trigger to all tables
DROP TRIGGER IF EXISTS tr_limitless_executions_owner ON limitless_executions;
CREATE TRIGGER tr_limitless_executions_owner
    BEFORE INSERT ON limitless_executions
    FOR EACH ROW EXECUTE FUNCTION limitless_set_owner_id();

DROP TRIGGER IF EXISTS tr_limitless_tasks_owner ON limitless_tasks;
CREATE TRIGGER tr_limitless_tasks_owner
    BEFORE INSERT ON limitless_tasks
    FOR EACH ROW EXECUTE FUNCTION limitless_set_owner_id();

DROP TRIGGER IF EXISTS tr_limitless_memory_owner ON limitless_memory;
CREATE TRIGGER tr_limitless_memory_owner
    BEFORE INSERT ON limitless_memory
    FOR EACH ROW EXECUTE FUNCTION limitless_set_owner_id();

DROP TRIGGER IF EXISTS tr_limitless_documents_owner ON limitless_documents;
CREATE TRIGGER tr_limitless_documents_owner
    BEFORE INSERT ON limitless_documents
    FOR EACH ROW EXECUTE FUNCTION limitless_set_owner_id();

DROP TRIGGER IF EXISTS tr_limitless_agent_runs_owner ON limitless_agent_runs;
CREATE TRIGGER tr_limitless_agent_runs_owner
    BEFORE INSERT ON limitless_agent_runs
    FOR EACH ROW EXECUTE FUNCTION limitless_set_owner_id();

DROP TRIGGER IF EXISTS tr_limitless_metrics_owner ON limitless_metrics;
CREATE TRIGGER tr_limitless_metrics_owner
    BEFORE INSERT ON limitless_metrics
    FOR EACH ROW EXECUTE FUNCTION limitless_set_owner_id();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    rls_disabled INTEGER;
BEGIN
    SELECT COUNT(*) INTO rls_disabled
    FROM pg_tables t
    JOIN pg_class c ON t.tablename = c.relname
    WHERE t.schemaname = 'public'
      AND t.tablename LIKE 'limitless_%'
      AND NOT c.relrowsecurity;

    IF rls_disabled > 0 THEN
        RAISE EXCEPTION 'Migration failed: % tables do not have RLS enabled', rls_disabled;
    END IF;

    RAISE NOTICE '=== Migration 001 Complete ===';
    RAISE NOTICE 'RLS enabled on all limitless_* tables';
    RAISE NOTICE 'owner_id column added to all tables';
    RAISE NOTICE 'Auto-populate trigger installed';
END $$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
