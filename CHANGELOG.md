# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2026-01-18

### Added

**Real Life OS Integration**
- Integrated as domain within Real Life OS architecture
- Deployed to shared Supabase project `intentum`
- Full security parity with other domains

**Security Migrations**
- `001_enable_rls.sql` - RLS on all 6 tables with owner_id
- `002_add_constraints.sql` - CHECK constraints, soft delete
- `003_secure_functions.sql` - SECURITY DEFINER functions
- `004_lgpd_integration.sql` - LGPD compliance (anonymize, export, retention)

**Database Tables (limitless_)**
- `limitless_executions` - Agent execution tracking with owner_id
- `limitless_tasks` - Subtask management with constraints
- `limitless_memory` - Persistent memory with importance scoring
- `limitless_documents` - RAG vector store with pgvector
- `limitless_agent_runs` - Agent performance metrics
- `limitless_metrics` - Aggregated dashboard metrics

**Functions**
- `match_limitless_documents()` - Semantic search with RLS
- `update_limitless_execution_timestamp()` - Auto-update on status change
- `update_limitless_task_duration()` - Auto-calculate duration
- `increment_memory_access()` - Track memory usage

**Views**
- `v_limitless_execution_summary` - Execution overview with task stats
- `v_limitless_agent_performance` - Agent success rates
- `v_limitless_daily_metrics` - 30-day metrics dashboard

**Enums**
- `execution_status` - pending, running, completed, failed, cancelled
- `task_status` - pending, running, completed, failed, skipped
- `memory_type` - general, session, user_preference, learned_pattern

### Changed

- All tables now have `owner_id` column
- All tables now have `deleted_at` for soft delete
- RLS policies use `(SELECT auth.uid())` for performance
- Renamed from `daa_*` to `limitless_*` (single source of truth)

### Security

- RLS enabled on 100% of tables (6/6)
- 6 RLS policies for user data isolation
- SECURITY DEFINER on all functions
- Fixed search_path (public, pg_temp)
- LGPD compliance via shared_ infrastructure

### Deployment

- Supabase Project: `intentum` (lqevhazsgtxsiqcdchfq)
- Domain Status: Ready (v2.0.0)
- Table Count: 6

---

## [1.0.0] - 2026-01-11

### Added

**Initial Commit**
- Project structure and documentation
- NZT Protocol specification
- Ralph Loop engine design
- Database schema (sql/schema.sql)
- n8n workflow templates
- Multi-LLM fallback chain design

**Documentation**
- SPECIFICATION.md - Technical PRD/RFC
- ARCHITECTURE.md - System design
- QUICKSTART.md - Getting started
- API.md - Endpoint reference
- Mermaid diagrams

**Database Schema**
- `limitless_executions` - Execution tracking
- `limitless_tasks` - Task management
- `limitless_memory` - Persistent memory
- `limitless_documents` - Vector store
- `limitless_agent_runs` - Performance tracking
- `limitless_metrics` - Aggregated metrics

---

## [0.1.0] - 2026-01-11

### Added

- Initial project scaffolding
- README with vision and roadmap
- MIT License

---

## Links

- [Real Life OS Architecture](../intentum/docs/architecture/DATABASE-DESIGN-v2.md)
- [INTENTUM Repository](https://github.com/matheusallvarenga/intentum)
