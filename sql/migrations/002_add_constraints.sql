-- ============================================================================
-- Migration 002: Add Constraints
-- Version: 1.0.0
-- Date: 2026-01-18
--
-- Purpose: Add CHECK constraints, NOT NULL constraints, and data validation
--          to ensure data integrity at the database level.
--
-- Template: Adapted from INTENTUM Gold Standard
-- ============================================================================

-- ============================================================================
-- ENUMS (type safety)
-- ============================================================================

-- Create ENUMs if they don't exist
DO $$ BEGIN
    CREATE TYPE limitless_execution_status AS ENUM (
        'pending',
        'running',
        'completed',
        'failed',
        'cancelled'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE limitless_task_status AS ENUM (
        'pending',
        'running',
        'completed',
        'failed',
        'skipped'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE limitless_memory_type AS ENUM (
        'general',
        'session',
        'user_preference',
        'learned_pattern',
        'system',
        'context'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE limitless_severity AS ENUM (
        'debug',
        'info',
        'warning',
        'error',
        'critical'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- TABLE: limitless_executions
-- ============================================================================

-- Status validation
ALTER TABLE limitless_executions
    DROP CONSTRAINT IF EXISTS chk_executions_status;
ALTER TABLE limitless_executions
    ADD CONSTRAINT chk_executions_status
    CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled'));

-- Iteration count must be non-negative
ALTER TABLE limitless_executions
    DROP CONSTRAINT IF EXISTS chk_executions_iteration_count;
ALTER TABLE limitless_executions
    ADD CONSTRAINT chk_executions_iteration_count
    CHECK (iteration_count >= 0);

-- Max iterations must be positive
ALTER TABLE limitless_executions
    DROP CONSTRAINT IF EXISTS chk_executions_max_iterations;
ALTER TABLE limitless_executions
    ADD CONSTRAINT chk_executions_max_iterations
    CHECK (max_iterations > 0 AND max_iterations <= 10000);

-- Duration must be non-negative when set
ALTER TABLE limitless_executions
    DROP CONSTRAINT IF EXISTS chk_executions_duration;
ALTER TABLE limitless_executions
    ADD CONSTRAINT chk_executions_duration
    CHECK (duration_ms IS NULL OR duration_ms >= 0);

-- Completed_at must be after started_at
ALTER TABLE limitless_executions
    DROP CONSTRAINT IF EXISTS chk_executions_dates;
ALTER TABLE limitless_executions
    ADD CONSTRAINT chk_executions_dates
    CHECK (completed_at IS NULL OR completed_at >= started_at);

-- Goal must not be empty
ALTER TABLE limitless_executions
    DROP CONSTRAINT IF EXISTS chk_executions_goal;
ALTER TABLE limitless_executions
    ADD CONSTRAINT chk_executions_goal
    CHECK (length(trim(goal)) > 0);

-- ============================================================================
-- TABLE: limitless_tasks
-- ============================================================================

-- Status validation
ALTER TABLE limitless_tasks
    DROP CONSTRAINT IF EXISTS chk_tasks_status;
ALTER TABLE limitless_tasks
    ADD CONSTRAINT chk_tasks_status
    CHECK (status IN ('pending', 'running', 'completed', 'failed', 'skipped'));

-- Token counts must be non-negative
ALTER TABLE limitless_tasks
    DROP CONSTRAINT IF EXISTS chk_tasks_tokens_input;
ALTER TABLE limitless_tasks
    ADD CONSTRAINT chk_tasks_tokens_input
    CHECK (tokens_input >= 0);

ALTER TABLE limitless_tasks
    DROP CONSTRAINT IF EXISTS chk_tasks_tokens_output;
ALTER TABLE limitless_tasks
    ADD CONSTRAINT chk_tasks_tokens_output
    CHECK (tokens_output >= 0);

-- Cost must be non-negative
ALTER TABLE limitless_tasks
    DROP CONSTRAINT IF EXISTS chk_tasks_cost;
ALTER TABLE limitless_tasks
    ADD CONSTRAINT chk_tasks_cost
    CHECK (cost_usd >= 0);

-- Duration must be non-negative when set
ALTER TABLE limitless_tasks
    DROP CONSTRAINT IF EXISTS chk_tasks_duration;
ALTER TABLE limitless_tasks
    ADD CONSTRAINT chk_tasks_duration
    CHECK (duration_ms IS NULL OR duration_ms >= 0);

-- Sequence order must be non-negative
ALTER TABLE limitless_tasks
    DROP CONSTRAINT IF EXISTS chk_tasks_sequence;
ALTER TABLE limitless_tasks
    ADD CONSTRAINT chk_tasks_sequence
    CHECK (sequence_order >= 0);

-- Name must not be empty
ALTER TABLE limitless_tasks
    DROP CONSTRAINT IF EXISTS chk_tasks_name;
ALTER TABLE limitless_tasks
    ADD CONSTRAINT chk_tasks_name
    CHECK (length(trim(name)) > 0);

-- Completed_at must be after started_at
ALTER TABLE limitless_tasks
    DROP CONSTRAINT IF EXISTS chk_tasks_dates;
ALTER TABLE limitless_tasks
    ADD CONSTRAINT chk_tasks_dates
    CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at);

-- ============================================================================
-- TABLE: limitless_memory
-- ============================================================================

-- Importance must be between 0 and 1
ALTER TABLE limitless_memory
    DROP CONSTRAINT IF EXISTS chk_memory_importance;
ALTER TABLE limitless_memory
    ADD CONSTRAINT chk_memory_importance
    CHECK (importance >= 0 AND importance <= 1);

-- Access count must be non-negative
ALTER TABLE limitless_memory
    DROP CONSTRAINT IF EXISTS chk_memory_access_count;
ALTER TABLE limitless_memory
    ADD CONSTRAINT chk_memory_access_count
    CHECK (access_count >= 0);

-- Key must not be empty
ALTER TABLE limitless_memory
    DROP CONSTRAINT IF EXISTS chk_memory_key;
ALTER TABLE limitless_memory
    ADD CONSTRAINT chk_memory_key
    CHECK (length(trim(key)) > 0);

-- Expires_at must be in the future when set
ALTER TABLE limitless_memory
    DROP CONSTRAINT IF EXISTS chk_memory_expires;
ALTER TABLE limitless_memory
    ADD CONSTRAINT chk_memory_expires
    CHECK (expires_at IS NULL OR expires_at > created_at);

-- Memory type validation
ALTER TABLE limitless_memory
    DROP CONSTRAINT IF EXISTS chk_memory_type;
ALTER TABLE limitless_memory
    ADD CONSTRAINT chk_memory_type
    CHECK (memory_type IN ('general', 'session', 'user_preference', 'learned_pattern', 'system', 'context'));

-- ============================================================================
-- TABLE: limitless_documents
-- ============================================================================

-- Content must not be empty
ALTER TABLE limitless_documents
    DROP CONSTRAINT IF EXISTS chk_documents_content;
ALTER TABLE limitless_documents
    ADD CONSTRAINT chk_documents_content
    CHECK (length(trim(content)) > 0);

-- Embedding dimension check (768 for Gemini)
-- Note: This is enforced by the vector(768) type definition

-- ============================================================================
-- TABLE: limitless_agent_runs
-- ============================================================================

-- Execution time must be non-negative
ALTER TABLE limitless_agent_runs
    DROP CONSTRAINT IF EXISTS chk_agent_runs_execution_time;
ALTER TABLE limitless_agent_runs
    ADD CONSTRAINT chk_agent_runs_execution_time
    CHECK (execution_time_ms IS NULL OR execution_time_ms >= 0);

-- Token counts must be non-negative
ALTER TABLE limitless_agent_runs
    DROP CONSTRAINT IF EXISTS chk_agent_runs_tokens_input;
ALTER TABLE limitless_agent_runs
    ADD CONSTRAINT chk_agent_runs_tokens_input
    CHECK (tokens_input >= 0);

ALTER TABLE limitless_agent_runs
    DROP CONSTRAINT IF EXISTS chk_agent_runs_tokens_output;
ALTER TABLE limitless_agent_runs
    ADD CONSTRAINT chk_agent_runs_tokens_output
    CHECK (tokens_output >= 0);

-- Agent name must not be empty
ALTER TABLE limitless_agent_runs
    DROP CONSTRAINT IF EXISTS chk_agent_runs_agent_name;
ALTER TABLE limitless_agent_runs
    ADD CONSTRAINT chk_agent_runs_agent_name
    CHECK (length(trim(agent_name)) > 0);

-- ============================================================================
-- TABLE: limitless_metrics
-- ============================================================================

-- Metric name must not be empty
ALTER TABLE limitless_metrics
    DROP CONSTRAINT IF EXISTS chk_metrics_name;
ALTER TABLE limitless_metrics
    ADD CONSTRAINT chk_metrics_name
    CHECK (length(trim(metric_name)) > 0);

-- Period end must be after period start
ALTER TABLE limitless_metrics
    DROP CONSTRAINT IF EXISTS chk_metrics_period;
ALTER TABLE limitless_metrics
    ADD CONSTRAINT chk_metrics_period
    CHECK (period_end > period_start);

-- ============================================================================
-- SOFT DELETE: Add deleted_at column to all tables
-- ============================================================================

ALTER TABLE limitless_executions
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE limitless_tasks
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE limitless_memory
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE limitless_documents
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE limitless_agent_runs
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE limitless_metrics
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- ============================================================================
-- INDEXES for soft delete queries
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_limitless_executions_active
    ON limitless_executions(id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_limitless_tasks_active
    ON limitless_tasks(id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_limitless_memory_active
    ON limitless_memory(id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_limitless_documents_active
    ON limitless_documents(id) WHERE deleted_at IS NULL;

-- ============================================================================
-- UPDATE RLS POLICIES to exclude soft-deleted records
-- ============================================================================

-- Update policies to filter out deleted records
DROP POLICY IF EXISTS "Users can view own executions" ON limitless_executions;
CREATE POLICY "Users can view own executions"
    ON limitless_executions FOR SELECT
    USING (owner_id = (SELECT auth.uid()) AND deleted_at IS NULL);

DROP POLICY IF EXISTS "Users can view own tasks" ON limitless_tasks;
CREATE POLICY "Users can view own tasks"
    ON limitless_tasks FOR SELECT
    USING (owner_id = (SELECT auth.uid()) AND deleted_at IS NULL);

DROP POLICY IF EXISTS "Users can view own memory" ON limitless_memory;
CREATE POLICY "Users can view own memory"
    ON limitless_memory FOR SELECT
    USING (owner_id = (SELECT auth.uid()) AND deleted_at IS NULL);

DROP POLICY IF EXISTS "Users can view own documents" ON limitless_documents;
CREATE POLICY "Users can view own documents"
    ON limitless_documents FOR SELECT
    USING (owner_id = (SELECT auth.uid()) AND deleted_at IS NULL);

DROP POLICY IF EXISTS "Users can view own agent runs" ON limitless_agent_runs;
CREATE POLICY "Users can view own agent runs"
    ON limitless_agent_runs FOR SELECT
    USING (owner_id = (SELECT auth.uid()) AND deleted_at IS NULL);

DROP POLICY IF EXISTS "Users can view own metrics" ON limitless_metrics;
CREATE POLICY "Users can view own metrics"
    ON limitless_metrics FOR SELECT
    USING (owner_id = (SELECT auth.uid()) AND deleted_at IS NULL);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    constraint_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO constraint_count
    FROM information_schema.table_constraints
    WHERE constraint_schema = 'public'
      AND table_name LIKE 'limitless_%'
      AND constraint_type = 'CHECK';

    RAISE NOTICE '=== Migration 002 Complete ===';
    RAISE NOTICE 'Added % CHECK constraints', constraint_count;
    RAISE NOTICE 'Added soft delete (deleted_at) to all tables';
    RAISE NOTICE 'Updated RLS policies to exclude deleted records';
END $$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
