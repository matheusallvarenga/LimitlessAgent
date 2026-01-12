-- ============================================================================
-- DO ANYTHING AGENT (DAA) - Supabase Schema
-- Version: 1.0.0
-- Database: PostgreSQL + pgvector
-- ============================================================================

-- Enable pgvector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Executions: Track each DAA run
CREATE TABLE IF NOT EXISTS daa_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- Status: pending, running, completed, failed, cancelled

    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_ms INTEGER,

    iteration_count INTEGER DEFAULT 0,
    max_iterations INTEGER DEFAULT 100,

    result JSONB,
    error TEXT,

    metadata JSONB DEFAULT '{}',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for status queries
CREATE INDEX idx_executions_status ON daa_executions(status);
CREATE INDEX idx_executions_created ON daa_executions(created_at DESC);

-- Tasks: Individual subtasks within an execution
CREATE TABLE IF NOT EXISTS daa_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    execution_id UUID REFERENCES daa_executions(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- Status: pending, running, completed, failed, skipped

    agent_name VARCHAR(100),
    model_used VARCHAR(100),

    input JSONB,
    output JSONB,
    error TEXT,

    tokens_input INTEGER DEFAULT 0,
    tokens_output INTEGER DEFAULT 0,
    cost_usd DECIMAL(10, 6) DEFAULT 0,

    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_ms INTEGER,

    parent_task_id UUID REFERENCES daa_tasks(id),
    sequence_order INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for task queries
CREATE INDEX idx_tasks_execution ON daa_tasks(execution_id);
CREATE INDEX idx_tasks_status ON daa_tasks(status);
CREATE INDEX idx_tasks_agent ON daa_tasks(agent_name);

-- Memory: Persistent memory for context across sessions
CREATE TABLE IF NOT EXISTS daa_memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    key VARCHAR(255) NOT NULL UNIQUE,
    value JSONB NOT NULL,

    memory_type VARCHAR(50) DEFAULT 'general',
    -- Types: general, session, user_preference, learned_pattern

    importance DECIMAL(3, 2) DEFAULT 0.5,
    -- 0.0 to 1.0, used for pruning

    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMP WITH TIME ZONE,

    expires_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for memory lookups
CREATE INDEX idx_memory_key ON daa_memory(key);
CREATE INDEX idx_memory_type ON daa_memory(memory_type);

-- Documents: Vector store for RAG (from template)
CREATE TABLE IF NOT EXISTS daa_documents (
    id BIGSERIAL PRIMARY KEY,

    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',

    -- Vector embedding (768 dimensions for Gemini, 1536 for OpenAI)
    embedding vector(768),

    doc_id VARCHAR(255),
    doc_title VARCHAR(500),
    doc_type VARCHAR(100),
    source VARCHAR(255),

    processed BOOLEAN DEFAULT FALSE,
    enricher_version VARCHAR(50),
    enriched_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create vector index for similarity search
CREATE INDEX idx_documents_embedding ON daa_documents
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE INDEX idx_documents_metadata ON daa_documents USING GIN (metadata);

-- ============================================================================
-- MONITORING TABLES
-- ============================================================================

-- Agent Runs: Track agent performance
CREATE TABLE IF NOT EXISTS daa_agent_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES daa_tasks(id) ON DELETE CASCADE,

    agent_name VARCHAR(100) NOT NULL,
    model_name VARCHAR(100),

    success BOOLEAN,
    execution_time_ms INTEGER,

    tokens_input INTEGER DEFAULT 0,
    tokens_output INTEGER DEFAULT 0,

    error TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_agent_runs_agent ON daa_agent_runs(agent_name);
CREATE INDEX idx_agent_runs_created ON daa_agent_runs(created_at DESC);

-- Metrics: Aggregated metrics for dashboard
CREATE TABLE IF NOT EXISTS daa_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(20, 6) NOT NULL,

    dimension VARCHAR(100),
    dimension_value VARCHAR(255),

    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_metrics_name ON daa_metrics(metric_name);
CREATE INDEX idx_metrics_period ON daa_metrics(period_start, period_end);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function for vector similarity search (from RAG template)
CREATE OR REPLACE FUNCTION match_documents(
    query_embedding vector(768),
    match_count INT,
    filter JSONB DEFAULT '{}'::JSONB
)
RETURNS TABLE (
    id BIGINT,
    content TEXT,
    metadata JSONB,
    embedding vector(768),
    similarity FLOAT
)
LANGUAGE SQL STABLE
AS $$
    SELECT
        id,
        content,
        metadata,
        embedding,
        1 - (embedding <#> query_embedding) AS similarity
    FROM daa_documents
    WHERE (filter IS NULL OR filter = '{}'::JSONB OR metadata @> filter)
    ORDER BY embedding <#> query_embedding
    LIMIT match_count;
$$;

-- Function to update execution timestamps
CREATE OR REPLACE FUNCTION update_execution_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    IF NEW.status = 'completed' OR NEW.status = 'failed' THEN
        NEW.completed_at = NOW();
        NEW.duration_ms = EXTRACT(EPOCH FROM (NOW() - NEW.started_at)) * 1000;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_execution_timestamp
    BEFORE UPDATE ON daa_executions
    FOR EACH ROW
    EXECUTE FUNCTION update_execution_timestamp();

-- Function to calculate task duration
CREATE OR REPLACE FUNCTION update_task_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IN ('completed', 'failed') AND NEW.started_at IS NOT NULL THEN
        NEW.completed_at = NOW();
        NEW.duration_ms = EXTRACT(EPOCH FROM (NOW() - NEW.started_at)) * 1000;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_task_duration
    BEFORE UPDATE ON daa_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_task_duration();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View for execution summary
CREATE OR REPLACE VIEW daa_execution_summary AS
SELECT
    e.id,
    e.goal,
    e.status,
    e.started_at,
    e.completed_at,
    e.duration_ms,
    e.iteration_count,
    COUNT(t.id) AS total_tasks,
    COUNT(CASE WHEN t.status = 'completed' THEN 1 END) AS completed_tasks,
    COUNT(CASE WHEN t.status = 'failed' THEN 1 END) AS failed_tasks,
    SUM(t.tokens_input) AS total_tokens_input,
    SUM(t.tokens_output) AS total_tokens_output,
    SUM(t.cost_usd) AS total_cost_usd
FROM daa_executions e
LEFT JOIN daa_tasks t ON e.id = t.execution_id
GROUP BY e.id;

-- View for agent performance
CREATE OR REPLACE VIEW daa_agent_performance AS
SELECT
    agent_name,
    COUNT(*) AS total_runs,
    COUNT(CASE WHEN success THEN 1 END) AS successful_runs,
    ROUND(COUNT(CASE WHEN success THEN 1 END)::DECIMAL / COUNT(*) * 100, 2) AS success_rate,
    AVG(execution_time_ms) AS avg_execution_time_ms,
    SUM(tokens_input) AS total_tokens_input,
    SUM(tokens_output) AS total_tokens_output
FROM daa_agent_runs
GROUP BY agent_name
ORDER BY total_runs DESC;

-- View for daily metrics
CREATE OR REPLACE VIEW daa_daily_metrics AS
SELECT
    DATE(created_at) AS date,
    COUNT(*) AS total_executions,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) AS failed,
    ROUND(COUNT(CASE WHEN status = 'completed' THEN 1 END)::DECIMAL /
          NULLIF(COUNT(*), 0) * 100, 2) AS success_rate,
    AVG(duration_ms) AS avg_duration_ms,
    AVG(iteration_count) AS avg_iterations
FROM daa_executions
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- ============================================================================
-- ROW LEVEL SECURITY (Optional)
-- ============================================================================

-- Enable RLS on tables (uncomment if needed)
-- ALTER TABLE daa_executions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE daa_tasks ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE daa_memory ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE daa_documents ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Insert initial memory entries
INSERT INTO daa_memory (key, value, memory_type, importance) VALUES
('system_version', '"1.0.0"', 'general', 1.0),
('agents_available', '27', 'general', 1.0),
('skills_available', '27', 'general', 1.0),
('mcps_available', '14', 'general', 1.0)
ON CONFLICT (key) DO NOTHING;

-- ============================================================================
-- GRANTS (adjust as needed for your Supabase setup)
-- ============================================================================

-- Grant permissions to authenticated users (Supabase default)
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
