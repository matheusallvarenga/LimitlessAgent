# Limitless Agent - Architecture Reference

*"I see everything. I understand everything."*

**Document Type**: Architecture Decision Record (ADR)
**Version**: 1.0.0
**Status**: IMPLEMENTATION IN PROGRESS - Phase 1 Started
**Author**: Matheus Allvarenga
**Date**: 2026-01-11
**Last Updated**: 2026-01-11
**Companion Doc**: `docs/SPECIFICATION.md`

---

## Executive Summary

Este documento consolida a pesquisa extensiva realizada sobre as melhores praticas, frameworks, e arquiteturas para construir o **Limitless Agent** - inspirado no filme Limitless (2011) e NZT-48 - que seja:

- **Completo**: Aproveita todo o ecossistema (27 agentes, 27 skills, 14 MCPs)
- **Confiavel**: Guardrails, observability, human-in-the-loop
- **Poderoso**: Multi-LLM, paralelo, autonomo
- **Economico**: Token routing, caching, batch processing

---

## Table of Contents

1. [Research Summary](#1-research-summary)
2. [Recommended Architecture](#2-recommended-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Multi-LLM Strategy](#4-multi-llm-strategy)
5. [Token Optimization](#5-token-optimization)
6. [Database & Memory](#6-database--memory)
7. [Safety & Guardrails](#7-safety--guardrails)
8. [Implementation Blueprint](#8-implementation-blueprint)

---

## 1. Research Summary

### 1.1 Frameworks Analyzed

| Framework | Verdict | Use Case |
|-----------|---------|----------|
| **LangChain/LangGraph** | Most mature | Complex stateful workflows |
| **CrewAI** | Most accessible | Role-based teams, rapid prototyping |
| **AutoGen** | Enterprise-ready | Multi-agent conversations |
| **Claude Agent SDK** | Native & simple | Claude-first development |
| **claude-flow** | Feature-rich | Swarm intelligence, 87 MCP tools |

**Source**: [DataCamp Comparison](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen), [Turing AI Frameworks](https://www.turing.com/resources/ai-agent-frameworks)

### 1.2 Multi-LLM Options

| Provider | CLI Tool | Best For | Free Tier |
|----------|----------|----------|-----------|
| **Claude** | Claude Code | Primary agent, reasoning | Pro $20/mo |
| **Gemini** | gemini-cli | Fallback, multimodal | 60 RPM, 1K/day |
| **OpenAI Codex** | codex-cli | Coding, automation | API only |
| **Ollama** | ollama | Local, privacy, cost | Unlimited |

**Sources**: [Gemini CLI](https://github.com/google-gemini/gemini-cli), [OpenAI Codex](https://github.com/openai/codex)

### 1.3 Vector Databases

| Database | Verdict | Use Case |
|----------|---------|----------|
| **ChromaDB** | Development/MVP | Prototyping, small datasets |
| **Qdrant** | Production OSS | Cost-sensitive, edge deployment |
| **Pinecone** | Enterprise SaaS | Zero-ops, managed |

**Source**: [Firecrawl Vector DB Guide](https://www.firecrawl.dev/blog/best-vector-databases-2025)

### 1.4 Token Optimization Strategies

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| Prompt Caching | 90% reads | `cache_control: ephemeral` |
| Token-efficient tools | 14-70% | Beta header |
| Model routing | 60-80% | Haiku for simple tasks |
| Batch API | 50% | Non-urgent processing |

**Source**: [Claude Prompt Caching Docs](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)

---

## 2. Recommended Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          DO ANYTHING AGENT (DAA) v1.0                               │
│                     "The Most Complete, Reliable, and Economical"                   │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                           LAYER 0: INTERFACE                                  │ │
│  │                                                                               │ │
│  │   /do-anything "goal"          do-anything.sh            REST API (future)   │ │
│  │   └── Claude Code CLI          └── Bash Wrapper          └── HTTP Server     │ │
│  │                                                                               │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                        │                                            │
│                                        ▼                                            │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                        LAYER 1: ORCHESTRATION CORE                            │ │
│  │                                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                         RALPH LOOP ENGINE                               │ │ │
│  │  │                                                                         │ │ │
│  │  │   while (!goal_complete && iteration < max) {                          │ │ │
│  │  │       context = load_state() + previous_results                        │ │ │
│  │  │       plan = decompose_goal(goal, context)                             │ │ │
│  │  │       agents = select_agents(plan)                                     │ │ │
│  │  │       model = route_model(complexity)                                  │ │ │
│  │  │       result = execute(agents, model)                                  │ │ │
│  │  │       save_state(result)                                               │ │ │
│  │  │       goal_complete = check_completion(result)                         │ │ │
│  │  │   }                                                                     │ │ │
│  │  │                                                                         │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                               │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │ │
│  │  │   GOAL      │  │   AGENT     │  │   MODEL     │  │  PARALLEL   │         │ │
│  │  │ DECOMPOSER  │  │   ROUTER    │  │   ROUTER    │  │   ENGINE    │         │ │
│  │  │             │  │             │  │             │  │             │         │ │
│  │  │ task-decomp │  │ 27 agents   │  │ Haiku/Son/  │  │ tmux +      │         │ │
│  │  │ expert      │  │ selection   │  │ Opus/Gemini │  │ worktrees   │         │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘         │ │
│  │                                                                               │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │ │
│  │  │   STATE     │  │   CACHE     │  │  GUARDRAILS │  │ OBSERVABIL- │         │ │
│  │  │   MANAGER   │  │   MANAGER   │  │   ENGINE    │  │    ITY      │         │ │
│  │  │             │  │             │  │             │  │             │         │ │
│  │  │ SQLite +    │  │ Prompt      │  │ Circuit     │  │ Logs +      │         │ │
│  │  │ Memory MCP  │  │ caching     │  │ breaker     │  │ Metrics     │         │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘         │ │
│  │                                                                               │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                        │                                            │
│                                        ▼                                            │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                         LAYER 2: AGENT POOL (27)                              │ │
│  │                                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  DEVELOPMENT (6)              RESEARCH (4)              CONTENT (6)     │ │ │
│  │  │  ├─ fullstack-developer       ├─ competitive-intel     ├─ podcast-*    │ │ │
│  │  │  ├─ frontend-developer        ├─ market-research       ├─ social-media │ │ │
│  │  │  ├─ backend-architect         ├─ seo-analyzer          ├─ content-cur  │ │ │
│  │  │  ├─ code-reviewer             └─ sales-automator       └─ video-editor │ │ │
│  │  │  ├─ task-decomposition                                                  │ │ │
│  │  │  └─ prompt-engineer                                                     │ │ │
│  │  ├─────────────────────────────────────────────────────────────────────────┤ │ │
│  │  │  PKM (5)                      DESIGN (4)                UTILITY (2)     │ │ │
│  │  │  ├─ connection-agent          ├─ cli-ui-designer       ├─ context-mgr  │ │ │
│  │  │  ├─ moc-agent                 ├─ ui-ux-designer        └─ visual-ocr   │ │ │
│  │  │  ├─ metadata-agent            ├─ timestamp-prec                        │ │ │
│  │  │  ├─ tag-agent                 └─ ...                                   │ │ │
│  │  │  └─ review-agent                                                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                               │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                        │                                            │
│                                        ▼                                            │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                      LAYER 3: LLM GATEWAY (LiteLLM)                           │ │
│  │                                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                     INTELLIGENT MODEL ROUTING                           │ │ │
│  │  │                                                                         │ │ │
│  │  │   Request ──▶ Complexity Analysis ──▶ Rate Limit Check ──▶ Model Select │ │ │
│  │  │                                                                         │ │ │
│  │  │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │ │ │
│  │  │   │ Claude  │  │ Claude  │  │ Claude  │  │ Gemini  │  │ Codex   │      │ │ │
│  │  │   │ Haiku   │  │ Sonnet  │  │  Opus   │  │  Flash  │  │  Mini   │      │ │ │
│  │  │   │         │  │         │  │         │  │         │  │         │      │ │ │
│  │  │   │ Simple  │  │ Medium  │  │ Complex │  │Fallback │  │ Coding  │      │ │ │
│  │  │   │ $0.25/M │  │ $3/M    │  │ $15/M   │  │ Free    │  │ $1.5/M  │      │ │ │
│  │  │   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘      │ │ │
│  │  │                                                                         │ │ │
│  │  │   Fallback Chain: Claude ──▶ Gemini ──▶ Codex ──▶ Ollama (local)       │ │ │
│  │  │                                                                         │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                               │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                        │                                            │
│                                        ▼                                            │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │                       LAYER 4: INTEGRATION & STORAGE                          │ │
│  │                                                                               │ │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐ │ │
│  │  │   MCPs (14)   │  │  Skills (27)  │  │   Database    │  │    GitHub     │ │ │
│  │  │               │  │               │  │               │  │               │ │ │
│  │  │ Cloud:        │  │ Documents:    │  │ SQLite:       │  │ Issues:       │ │ │
│  │  │ ├─ notion     │  │ ├─ docx/pdf  │  │ ├─ executions │  │ ├─ create     │ │ │
│  │  │ ├─ supabase   │  │ ├─ pptx/xlsx │  │ ├─ subgoals   │  │ ├─ update     │ │ │
│  │  │ ├─ vercel     │  │               │  │ ├─ agent_runs│  │ └─ close      │ │ │
│  │  │ ├─ shadcn     │  │ Notion:       │  │ └─ metrics   │  │               │ │ │
│  │  │ └─ context7   │  │ ├─ spec-impl │  │               │  │ PRs:          │ │ │
│  │  │               │  │ ├─ meeting   │  │ ChromaDB:     │  │ ├─ create     │ │ │
│  │  │ Built-in:     │  │ └─ research  │  │ └─ embeddings │  │ ├─ review     │ │ │
│  │  │ ├─ memory     │  │               │  │               │  │ └─ merge     │ │ │
│  │  │ ├─ filesystem │  │ Creative:     │  │ Redis:        │  │               │ │ │
│  │  │ ├─ github     │  │ ├─ art       │  │ └─ hot cache  │  │ Actions:      │ │ │
│  │  │ ├─ fetch      │  │ ├─ canvas    │  │               │  │ └─ trigger    │ │ │
│  │  │ └─ markitdown │  │ └─ themes    │  │               │  │               │ │ │
│  │  │               │  │               │  │               │  │               │ │ │
│  │  └───────────────┘  └───────────────┘  └───────────────┘  └───────────────┘ │ │
│  │                                                                               │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow Diagram

```
                                    USER
                                      │
                                      │ "/do-anything Build a REST API with auth"
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                   ENTRY POINT                                        │
│                                                                                      │
│    ┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐     │
│    │  Claude Code    │  ──▶    │   do-anything   │  ──▶    │   State Init    │     │
│    │  CLI Command    │         │   Bash Script   │         │   (SQLite)      │     │
│    └─────────────────┘         └─────────────────┘         └─────────────────┘     │
│                                                                                      │
└──────────────────────────────────────┬──────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                               ITERATION 1                                            │
│                                                                                      │
│  1. DECOMPOSE                                                                        │
│     ┌──────────────────────────────────────────────────────────────────────────┐    │
│     │  Goal: "Build a REST API with auth"                                      │    │
│     │                                                                          │    │
│     │  ──▶ task-decomposition-expert (Haiku - simple planning)                │    │
│     │                                                                          │    │
│     │  Subgoals:                                                               │    │
│     │  ├── 1. Set up project structure                                        │    │
│     │  ├── 2. Create database schema                                          │    │
│     │  ├── 3. Implement auth endpoints (JWT)                                  │    │
│     │  ├── 4. Implement CRUD endpoints                                        │    │
│     │  ├── 5. Add tests                                                       │    │
│     │  └── 6. Documentation                                                   │    │
│     └──────────────────────────────────────────────────────────────────────────┘    │
│                                                                                      │
│  2. ROUTE AGENTS                                                                     │
│     ┌──────────────────────────────────────────────────────────────────────────┐    │
│     │  Subgoal 1-4 ──▶ backend-architect (Opus - complex architecture)        │    │
│     │  Subgoal 5   ──▶ code-reviewer (Sonnet - testing)                       │    │
│     │  Subgoal 6   ──▶ frontend-developer (Haiku - simple docs)               │    │
│     └──────────────────────────────────────────────────────────────────────────┘    │
│                                                                                      │
│  3. EXECUTE (Parallel where possible)                                                │
│     ┌──────────────────────────────────────────────────────────────────────────┐    │
│     │                                                                          │    │
│     │  tmux session: daa-1736617200                                            │    │
│     │  ┌──────────┐  ┌──────────┐  ┌──────────┐                               │    │
│     │  │ Pane 0   │  │ Pane 1   │  │ Pane 2   │                               │    │
│     │  │ backend  │  │ backend  │  │ backend  │                               │    │
│     │  │ (1-2)    │  │ (3)      │  │ (4)      │                               │    │
│     │  └──────────┘  └──────────┘  └──────────┘                               │    │
│     │                                                                          │    │
│     │  Git worktrees:                                                          │    │
│     │  ├── /tmp/daa/worktree-1 (branch: daa/setup)                            │    │
│     │  ├── /tmp/daa/worktree-2 (branch: daa/auth)                             │    │
│     │  └── /tmp/daa/worktree-3 (branch: daa/crud)                             │    │
│     │                                                                          │    │
│     └──────────────────────────────────────────────────────────────────────────┘    │
│                                                                                      │
│  4. CHECK COMPLETION                                                                 │
│     ┌──────────────────────────────────────────────────────────────────────────┐    │
│     │  ✅ Subgoal 1: Complete                                                  │    │
│     │  ✅ Subgoal 2: Complete                                                  │    │
│     │  ✅ Subgoal 3: Complete                                                  │    │
│     │  ✅ Subgoal 4: Complete                                                  │    │
│     │  ⏳ Subgoal 5: Pending (depends on 1-4)                                  │    │
│     │  ⏳ Subgoal 6: Pending (depends on 1-4)                                  │    │
│     │                                                                          │    │
│     │  Status: NOT COMPLETE ──▶ Continue to Iteration 2                       │    │
│     └──────────────────────────────────────────────────────────────────────────┘    │
│                                                                                      │
└──────────────────────────────────────┬──────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                               ITERATION 2                                            │
│                                                                                      │
│  Merge worktrees ──▶ Run tests (code-reviewer) ──▶ Generate docs                    │
│                                                                                      │
│  Result: All subgoals complete                                                       │
│                                                                                      │
│  Output: "DONE"                                                                      │
│                                                                                      │
└──────────────────────────────────────┬──────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                   OUTPUT                                             │
│                                                                                      │
│  ## Summary                                                                          │
│  - Created REST API with JWT authentication                                          │
│  - Implemented CRUD endpoints for users and resources                                │
│  - Added comprehensive test suite (95% coverage)                                     │
│  - Generated API documentation                                                       │
│                                                                                      │
│  ## Artifacts                                                                        │
│  - src/                                                                              │
│  - tests/                                                                            │
│  - docs/API.md                                                                       │
│                                                                                      │
│  ## Metrics                                                                          │
│  - Iterations: 2                                                                     │
│  - Tokens used: 45,000                                                               │
│  - Cost: $0.38                                                                       │
│  - Duration: 4m 32s                                                                  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Technology Stack

### 3.1 Core Stack (Implemented)

| Layer | Technology | Reason |
|-------|------------|--------|
| **Core Loop** | Bash + Claude Code | Native, simple, proven (Ralph Loop) |
| **Agent Framework** | None (native subagents) | Avoid overhead, use built-in Task tool |
| **LLM Fallback** | Claude → Ollama → Gemini → ChatGPT | Multi-provider resilience |
| **State DB** | **Supabase (PostgreSQL)** | Remote access, pgvector, backup |
| **Vector DB** | **pgvector (Supabase)** | 768-dim embeddings, match_documents() |
| **Monitoring** | **n8n (Phase 1)** | Visual workflows, webhooks |
| **Notifications** | **Slack + Telegram** | Primary/backup channels |
| **Cache** | Prompt Caching (native) | 90% cost reduction |
| **Parallel Engine** | tmux + git worktrees | Isolation, proven pattern |
| **Observability** | n8n + Supabase views | Metrics, KPIs, dashboards |

**Ollama Models Installed**:
- `llama3.2:3b` - Quick tasks, fallback
- `codellama:13b` - Code generation/review
- `mistral:7b` - General reasoning

### 3.2 Why NOT Use Heavy Frameworks

| Framework | Why Skip |
|-----------|----------|
| LangChain | Overhead, complexity, abstractions |
| CrewAI | Not needed - we have 27 native agents |
| AutoGen | Enterprise overkill |
| Semantic Kernel | Wrong paradigm |

**Principle**: Use the **simplest tool** that gets the job done. Claude Code's native subagent system + Task tool is sufficient.

---

## 4. Multi-LLM Strategy

### 4.1 Provider Configuration

```yaml
# ~/.daa/llm-config.yaml

providers:
  # Primary: Claude (Anthropic)
  claude:
    api_key: ${ANTHROPIC_API_KEY}
    models:
      haiku:
        id: claude-3-5-haiku-latest
        cost_per_1m_input: 0.25
        cost_per_1m_output: 1.25
        max_tokens: 8192
        use_for: ["planning", "formatting", "validation", "simple_queries"]
      sonnet:
        id: claude-sonnet-4-20250514
        cost_per_1m_input: 3.00
        cost_per_1m_output: 15.00
        max_tokens: 64000
        use_for: ["coding", "analysis", "research", "medium_complexity"]
      opus:
        id: claude-opus-4-5-20251101
        cost_per_1m_input: 15.00
        cost_per_1m_output: 75.00
        max_tokens: 32000
        use_for: ["architecture", "creative", "complex_reasoning"]
    caching:
      enabled: true
      ttl: 300  # 5 minutes
      min_tokens: 1024

  # Secondary: Gemini (Google)
  gemini:
    api_key: ${GOOGLE_AI_API_KEY}
    models:
      flash:
        id: gemini-2.0-flash
        cost_per_1m_input: 0.00  # Free tier
        cost_per_1m_output: 0.00
        max_tokens: 8192
        use_for: ["fallback", "multimodal", "quick_tasks"]
      pro:
        id: gemini-2.0-pro
        cost_per_1m_input: 1.25
        cost_per_1m_output: 5.00
        max_tokens: 32000
        use_for: ["fallback_complex", "long_context"]
    rate_limits:
      rpm: 60
      daily: 1000

  # Tertiary: OpenAI Codex
  codex:
    api_key: ${OPENAI_API_KEY}
    models:
      mini:
        id: codex-mini
        cost_per_1m_input: 1.50
        cost_per_1m_output: 6.00
        max_tokens: 32000
        use_for: ["coding_specific", "autonomous_tasks"]

  # Local: Ollama
  ollama:
    base_url: http://localhost:11434
    models:
      llama:
        id: llama3.2
        cost: 0  # Free
        use_for: ["offline", "privacy", "cost_savings"]
      codellama:
        id: codellama
        cost: 0
        use_for: ["local_coding"]

routing:
  strategy: complexity_based
  fallback_chain:
    - claude
    - gemini
    - codex
    - ollama

  complexity_thresholds:
    simple: 0.3    # Route to Haiku
    medium: 0.7    # Route to Sonnet
    complex: 1.0   # Route to Opus

rate_limiting:
  global_rpm: 100
  cooldown_seconds: 60
  retry_attempts: 3
```

### 4.2 Model Routing Logic

```javascript
// model-router.js

const COMPLEXITY_INDICATORS = {
  simple: [
    /format|validate|check|list|count/i,
    /simple|quick|basic/i,
    /planning|outline/i
  ],
  complex: [
    /architect|design|system/i,
    /analyze deeply|comprehensive/i,
    /creative|innovative/i,
    /refactor entire|rewrite/i
  ]
};

function estimateComplexity(goal, context) {
  let score = 0.5; // Default medium

  // Check goal patterns
  for (const pattern of COMPLEXITY_INDICATORS.simple) {
    if (pattern.test(goal)) score -= 0.2;
  }
  for (const pattern of COMPLEXITY_INDICATORS.complex) {
    if (pattern.test(goal)) score += 0.2;
  }

  // Check context size
  const contextTokens = estimateTokens(context);
  if (contextTokens > 50000) score += 0.1;
  if (contextTokens > 100000) score += 0.2;

  // Clamp to [0, 1]
  return Math.max(0, Math.min(1, score));
}

function selectModel(complexity, rateStatus) {
  // Check rate limits first
  if (!rateStatus.claude.available) {
    if (rateStatus.gemini.available) return 'gemini/flash';
    if (rateStatus.codex.available) return 'codex/mini';
    return 'ollama/llama';
  }

  // Route by complexity
  if (complexity < 0.3) return 'claude/haiku';
  if (complexity < 0.7) return 'claude/sonnet';
  return 'claude/opus';
}
```

---

## 5. Token Optimization

### 5.1 Strategy Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         TOKEN OPTIMIZATION STRATEGIES                                │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  1. PROMPT CACHING (90% savings on reads)                                   │   │
│  │                                                                             │   │
│  │  Structure prompts with static content first:                               │   │
│  │  ┌────────────────────────────────────────────────────────────────────┐    │   │
│  │  │  [System Prompt]     ← CACHE (1024+ tokens, stable)               │    │   │
│  │  │  [Agent Definition]  ← CACHE                                       │    │   │
│  │  │  [Tool Definitions]  ← CACHE                                       │    │   │
│  │  │  [Context/Docs]      ← CACHE                                       │    │   │
│  │  │  ─────────────────────────────────────────────────────────────────│    │   │
│  │  │  [Dynamic Content]   ← NOT CACHED (changes each request)          │    │   │
│  │  │  [User Goal]         ← NOT CACHED                                  │    │   │
│  │  └────────────────────────────────────────────────────────────────────┘    │   │
│  │                                                                             │   │
│  │  cache_control: { type: "ephemeral" }  # 5-minute TTL                      │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  2. MODEL ROUTING (60-80% savings)                                          │   │
│  │                                                                             │   │
│  │  Task Type            Model          Cost/1M        Savings vs Opus        │   │
│  │  ──────────────────   ─────────────  ─────────────  ─────────────────────  │   │
│  │  Planning, validation  Haiku          $0.25/$1.25    98%                    │   │
│  │  Coding, analysis      Sonnet         $3/$15         80%                    │   │
│  │  Architecture          Opus           $15/$75        Baseline               │   │
│  │  Fallback              Gemini Flash   Free           100%                   │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  3. TOKEN-EFFICIENT TOOLS (14-70% savings)                                  │   │
│  │                                                                             │   │
│  │  Header: anthropic-beta: token-efficient-tools-2025-02-19                  │   │
│  │                                                                             │   │
│  │  Reduces tool call output tokens by using optimized representations.       │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  4. BATCH API (50% savings)                                                 │   │
│  │                                                                             │   │
│  │  For non-urgent tasks (reports, analysis, batch processing):               │   │
│  │  - Queue tasks                                                              │   │
│  │  - Process overnight                                                        │   │
│  │  - 50% discount on all tokens                                               │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  5. CONTEXT COMPRESSION                                                     │   │
│  │                                                                             │   │
│  │  - Summarize long conversations before feeding back                        │   │
│  │  - Use context7 MCP for intelligent context management                     │   │
│  │  - Remove redundant information                                            │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ESTIMATED TOTAL SAVINGS: 70-85% compared to naive usage                            │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Cost Estimation

| Scenario | Without Optimization | With Optimization | Savings |
|----------|---------------------|-------------------|---------|
| Simple goal | $0.50 | $0.08 | 84% |
| Medium goal | $2.00 | $0.40 | 80% |
| Complex goal | $8.00 | $1.50 | 81% |
| **Monthly (100 goals)** | **$150** | **$30** | **80%** |

---

## 6. Database & Memory

### 6.1 SQLite Schema (State Management)

```sql
-- Primary state database: ~/.daa/state.db

-- Execution sessions
CREATE TABLE executions (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    goal TEXT NOT NULL,
    status TEXT CHECK(status IN ('running','completed','failed','cancelled')) DEFAULT 'running',
    started_at TEXT DEFAULT (datetime('now')),
    completed_at TEXT,
    iterations INTEGER DEFAULT 0,
    max_iterations INTEGER DEFAULT 10,
    tokens_input INTEGER DEFAULT 0,
    tokens_output INTEGER DEFAULT 0,
    cost_usd REAL DEFAULT 0,
    metadata TEXT  -- JSON
);

-- Goal decomposition
CREATE TABLE subgoals (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    execution_id TEXT NOT NULL REFERENCES executions(id) ON DELETE CASCADE,
    parent_id TEXT REFERENCES subgoals(id),
    sequence INTEGER NOT NULL,
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('pending','in_progress','completed','failed','skipped')) DEFAULT 'pending',
    assigned_agent TEXT,
    assigned_model TEXT,
    depends_on TEXT,  -- JSON array of subgoal IDs
    result TEXT,      -- JSON
    created_at TEXT DEFAULT (datetime('now')),
    completed_at TEXT
);

-- Individual agent runs
CREATE TABLE agent_runs (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    execution_id TEXT NOT NULL REFERENCES executions(id) ON DELETE CASCADE,
    subgoal_id TEXT REFERENCES subgoals(id),
    agent_type TEXT NOT NULL,
    model TEXT NOT NULL,
    iteration INTEGER NOT NULL,
    tokens_input INTEGER DEFAULT 0,
    tokens_output INTEGER DEFAULT 0,
    tokens_cached INTEGER DEFAULT 0,
    duration_ms INTEGER,
    status TEXT CHECK(status IN ('success','failed','timeout','cancelled')) DEFAULT 'success',
    error TEXT,
    started_at TEXT DEFAULT (datetime('now')),
    completed_at TEXT
);

-- Metrics for analytics
CREATE TABLE metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    value REAL NOT NULL,
    labels TEXT,  -- JSON
    recorded_at TEXT DEFAULT (datetime('now'))
);

-- Context store for short-term memory
CREATE TABLE context (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,  -- JSON
    execution_id TEXT REFERENCES executions(id),
    ttl_seconds INTEGER DEFAULT 3600,
    created_at TEXT DEFAULT (datetime('now')),
    expires_at TEXT GENERATED ALWAYS AS (datetime(created_at, '+' || ttl_seconds || ' seconds')) STORED
);

-- Indexes
CREATE INDEX idx_executions_status ON executions(status);
CREATE INDEX idx_subgoals_exec ON subgoals(execution_id, sequence);
CREATE INDEX idx_agent_runs_exec ON agent_runs(execution_id, iteration);
CREATE INDEX idx_context_expiry ON context(expires_at);

-- Auto-cleanup expired context
CREATE TRIGGER cleanup_expired_context
AFTER INSERT ON context
BEGIN
    DELETE FROM context WHERE expires_at < datetime('now');
END;
```

### 6.2 ChromaDB for Semantic Memory

```python
# memory.py - Semantic memory with ChromaDB

import chromadb
from chromadb.config import Settings

class SemanticMemory:
    def __init__(self, path="~/.daa/memory"):
        self.client = chromadb.PersistentClient(
            path=path,
            settings=Settings(anonymized_telemetry=False)
        )

        # Collections
        self.goals = self.client.get_or_create_collection("goals")
        self.solutions = self.client.get_or_create_collection("solutions")
        self.errors = self.client.get_or_create_collection("errors")

    def remember_goal(self, goal: str, solution: str, metadata: dict):
        """Store a goal-solution pair for future reference."""
        self.goals.add(
            documents=[goal],
            metadatas=[{**metadata, "solution_ref": solution[:500]}],
            ids=[metadata.get("execution_id")]
        )
        self.solutions.add(
            documents=[solution],
            metadatas=[metadata],
            ids=[f"sol_{metadata.get('execution_id')}"]
        )

    def recall_similar(self, goal: str, n_results: int = 3):
        """Find similar past goals and their solutions."""
        results = self.goals.query(
            query_texts=[goal],
            n_results=n_results
        )
        return results

    def remember_error(self, error: str, solution: str, context: dict):
        """Store error patterns and their fixes."""
        self.errors.add(
            documents=[error],
            metadatas=[{"solution": solution, **context}],
            ids=[f"err_{hash(error)}"]
        )
```

---

## 7. Safety & Guardrails

### 7.1 Guardrails Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            SAFETY & GUARDRAILS                                       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  LAYER 1: INPUT VALIDATION                                                  │   │
│  │                                                                             │   │
│  │  ├─ Sanitize goal input (remove injection patterns)                        │   │
│  │  ├─ Validate against blocked patterns (rm -rf, sudo, etc.)                 │   │
│  │  ├─ Check goal complexity (reject overly broad goals)                      │   │
│  │  └─ Rate limit by user/session                                             │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  LAYER 2: EXECUTION CONTROLS                                                │   │
│  │                                                                             │   │
│  │  ├─ Max iterations: 10 (configurable)                                      │   │
│  │  ├─ Max tokens per execution: 500,000                                      │   │
│  │  ├─ Max cost per execution: $10                                            │   │
│  │  ├─ Timeout per iteration: 5 minutes                                       │   │
│  │  └─ Sandbox mode for untrusted operations                                  │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  LAYER 3: CIRCUIT BREAKER                                                   │   │
│  │                                                                             │   │
│  │  Triggers:                                                                  │   │
│  │  ├─ 3 consecutive failures → PAUSE, require human approval                │   │
│  │  ├─ Same error 2x → STOP, don't retry                                      │   │
│  │  ├─ Cost > budget → STOP                                                   │   │
│  │  ├─ Rate limit hit → WAIT, use fallback provider                          │   │
│  │  └─ Output seems harmful → STOP, log for review                           │   │
│  │                                                                             │   │
│  │  States:                                                                    │   │
│  │  ├─ CLOSED: Normal operation                                               │   │
│  │  ├─ OPEN: All requests fail fast                                          │   │
│  │  └─ HALF-OPEN: Testing recovery                                            │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  LAYER 4: HUMAN-IN-THE-LOOP                                                 │   │
│  │                                                                             │   │
│  │  Risk Tiers:                                                                │   │
│  │  ├─ LOW: Auto-execute (read files, search, plan)                          │   │
│  │  ├─ MEDIUM: Notify (write files, run tests)                               │   │
│  │  └─ HIGH: Require approval (delete, deploy, external APIs)                │   │
│  │                                                                             │   │
│  │  Approval Channels:                                                         │   │
│  │  ├─ CLI prompt (interactive mode)                                          │   │
│  │  ├─ File-based (.daa-approve)                                              │   │
│  │  └─ Webhook (Slack, email - future)                                        │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  LAYER 5: OBSERVABILITY                                                     │   │
│  │                                                                             │   │
│  │  ├─ Structured JSON logs (every action)                                    │   │
│  │  ├─ Metrics (tokens, cost, duration, success rate)                         │   │
│  │  ├─ Traces (OpenTelemetry compatible)                                      │   │
│  │  ├─ Alerts (failure rate > 20%, cost spike, long duration)                 │   │
│  │  └─ Audit log (tamper-evident, signed)                                     │   │
│  │                                                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Implementation

```bash
#!/bin/bash
# guardrails.sh - Safety controls for DAA

# Configuration
MAX_ITERATIONS=10
MAX_COST_USD=10
MAX_TOKENS=500000
TIMEOUT_SECONDS=300
CIRCUIT_BREAKER_THRESHOLD=3

# State
CONSECUTIVE_FAILURES=0
TOTAL_COST=0
TOTAL_TOKENS=0

check_input_safety() {
    local goal="$1"

    # Blocked patterns
    local blocked_patterns=(
        "rm -rf /"
        "sudo"
        "format"
        "delete all"
        "DROP TABLE"
        "eval("
    )

    for pattern in "${blocked_patterns[@]}"; do
        if echo "$goal" | grep -qi "$pattern"; then
            log_security "Blocked dangerous pattern: $pattern"
            return 1
        fi
    done

    return 0
}

check_circuit_breaker() {
    if [[ $CONSECUTIVE_FAILURES -ge $CIRCUIT_BREAKER_THRESHOLD ]]; then
        log_error "Circuit breaker OPEN: $CONSECUTIVE_FAILURES consecutive failures"
        return 1
    fi

    if (( $(echo "$TOTAL_COST > $MAX_COST_USD" | bc -l) )); then
        log_error "Circuit breaker OPEN: Cost limit exceeded ($TOTAL_COST)"
        return 1
    fi

    if [[ $TOTAL_TOKENS -gt $MAX_TOKENS ]]; then
        log_error "Circuit breaker OPEN: Token limit exceeded ($TOTAL_TOKENS)"
        return 1
    fi

    return 0
}

require_approval() {
    local action="$1"
    local risk_level="$2"

    case $risk_level in
        LOW)
            return 0  # Auto-approve
            ;;
        MEDIUM)
            log_warn "Action requires attention: $action"
            # Could send notification here
            return 0
            ;;
        HIGH)
            log_warn "HIGH RISK action requires approval: $action"
            read -p "Approve? (y/N): " response
            [[ "$response" =~ ^[Yy]$ ]] && return 0
            return 1
            ;;
    esac
}

classify_risk() {
    local action="$1"

    # High risk actions
    if echo "$action" | grep -qiE "delete|deploy|push|publish|rm|DROP"; then
        echo "HIGH"
        return
    fi

    # Medium risk actions
    if echo "$action" | grep -qiE "write|edit|create|modify"; then
        echo "MEDIUM"
        return
    fi

    # Low risk by default
    echo "LOW"
}
```

---

## 8. Implementation Blueprint

### 8.1 File Structure (Implemented)

```
Projects/DoAnythingAgent/            # Main DAA project directory
├── README.md                        # [CREATED] Project documentation
├── DO-ANYTHING-AGENT-SPECIFICATION.md  # PRD/RFC
├── DO-ANYTHING-AGENT-ARCHITECTURE.md   # This document
│
├── config/                          # [CREATED] Configuration files
│   ├── settings.json                # Main DAA configuration
│   ├── ollama.json                  # Ollama models config
│   └── notifications.json           # Slack/Telegram config
│
├── n8n/                             # [CREATED] n8n workflows
│   └── workflows/
│       ├── daa-monitor.json         # Monitoring workflow
│       └── daa-notify.json          # Notification workflow
│
├── sql/                             # [CREATED] Database
│   └── schema.sql                   # Supabase/pgvector schema
│
├── scripts/                         # [CREATED] Executables
│   └── do-anything.sh               # Main entry point (chmod +x)
│
├── src/                             # [PENDING] Implementation code
│   ├── lib/                         # Core libraries
│   │   ├── goal-decomposer.js       # Goal analysis
│   │   ├── agent-router.js          # Agent selection
│   │   └── token-optimizer.js       # Cost optimization
│   └── utils/                       # Utilities
│
├── docs/                            # [PENDING] Additional docs
│   └── examples/                    # Usage examples
│
└── logs/                            # Execution logs
    └── YYYY-MM-DD/
```

**n8n Endpoints**:
- Monitor: `https://n8n.intentum.pro/webhook/daa-monitor`
- Notify: `https://n8n.intentum.pro/webhook/daa-notify`

**Supabase**: Cloud instance (schema in `sql/schema.sql`)

**Ollama**: `https://ollama.intentum.ai`

### 8.2 Implementation Phases

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         IMPLEMENTATION ROADMAP                                       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  PHASE 1: FOUNDATION                                                                 │
│  ────────────────────                                                               │
│  Priority: P0 (Must have for MVP)                                                   │
│                                                                                      │
│  ☐ 1.1 Create do-anything.md command                                               │
│  ☐ 1.2 Implement ralph-loop.sh (core engine)                                       │
│  ☐ 1.3 Implement completion detection                                              │
│  ☐ 1.4 Set up SQLite state.db                                                      │
│  ☐ 1.5 Basic logging                                                               │
│  ☐ 1.6 Test with simple goal                                                       │
│                                                                                      │
│  Exit Criteria: Complete a simple goal in <5 iterations                             │
│                                                                                      │
│  ───────────────────────────────────────────────────────────────────────────────── │
│                                                                                      │
│  PHASE 2: AGENT INTEGRATION                                                         │
│  ──────────────────────────                                                         │
│  Priority: P0                                                                        │
│                                                                                      │
│  ☐ 2.1 Create do-anything-agent.md                                                 │
│  ☐ 2.2 Implement goal-decomposer.js                                                │
│  ☐ 2.3 Implement agent-router.js                                                   │
│  ☐ 2.4 Integrate Task tool for subagent invocation                                 │
│  ☐ 2.5 Test multi-agent workflow                                                   │
│                                                                                      │
│  Exit Criteria: Orchestrate 3+ agents for complex goal                              │
│                                                                                      │
│  ───────────────────────────────────────────────────────────────────────────────── │
│                                                                                      │
│  PHASE 3: TOKEN OPTIMIZATION                                                        │
│  ───────────────────────────                                                        │
│  Priority: P1                                                                        │
│                                                                                      │
│  ☐ 3.1 Implement model-router.sh                                                   │
│  ☐ 3.2 Add prompt caching support                                                  │
│  ☐ 3.3 Implement token-optimizer.js                                                │
│  ☐ 3.4 Add cost tracking to state.db                                               │
│  ☐ 3.5 Test cost reduction                                                         │
│                                                                                      │
│  Exit Criteria: Demonstrate 50%+ cost reduction                                     │
│                                                                                      │
│  ───────────────────────────────────────────────────────────────────────────────── │
│                                                                                      │
│  PHASE 4: MULTI-LLM & FALLBACK                                                      │
│  ─────────────────────────────                                                      │
│  Priority: P1                                                                        │
│                                                                                      │
│  ☐ 4.1 Configure LiteLLM proxy                                                     │
│  ☐ 4.2 Add Gemini CLI integration                                                  │
│  ☐ 4.3 Add Codex CLI integration                                                   │
│  ☐ 4.4 Implement fallback chain                                                    │
│  ☐ 4.5 Add rate limit detection                                                    │
│  ☐ 4.6 Test failover scenarios                                                     │
│                                                                                      │
│  Exit Criteria: Seamless failover when primary provider rate-limited                │
│                                                                                      │
│  ───────────────────────────────────────────────────────────────────────────────── │
│                                                                                      │
│  PHASE 5: PARALLEL EXECUTION                                                        │
│  ───────────────────────────                                                        │
│  Priority: P2                                                                        │
│                                                                                      │
│  ☐ 5.1 Implement parallel-engine.sh (tmux)                                         │
│  ☐ 5.2 Add git worktree isolation                                                  │
│  ☐ 5.3 Implement result aggregation                                                │
│  ☐ 5.4 Add conflict resolution                                                     │
│  ☐ 5.5 Test parallel workflows                                                     │
│                                                                                      │
│  Exit Criteria: 2x speed improvement for parallelizable tasks                       │
│                                                                                      │
│  ───────────────────────────────────────────────────────────────────────────────── │
│                                                                                      │
│  PHASE 6: MEMORY & PERSISTENCE                                                      │
│  ─────────────────────────────                                                      │
│  Priority: P2                                                                        │
│                                                                                      │
│  ☐ 6.1 Integrate Memory MCP                                                        │
│  ☐ 6.2 Set up ChromaDB for semantic memory                                         │
│  ☐ 6.3 Implement memory.py                                                         │
│  ☐ 6.4 Add "recall similar goals" feature                                          │
│  ☐ 6.5 Test cross-session continuity                                               │
│                                                                                      │
│  Exit Criteria: DAA learns from past executions                                     │
│                                                                                      │
│  ───────────────────────────────────────────────────────────────────────────────── │
│                                                                                      │
│  PHASE 7: SAFETY & GUARDRAILS                                                       │
│  ────────────────────────────                                                       │
│  Priority: P0 (parallel with Phase 1)                                               │
│                                                                                      │
│  ☐ 7.1 Implement guardrails.sh                                                     │
│  ☐ 7.2 Add circuit breaker                                                         │
│  ☐ 7.3 Implement risk classification                                               │
│  ☐ 7.4 Add human-in-the-loop for high-risk                                         │
│  ☐ 7.5 Test safety controls                                                        │
│                                                                                      │
│  Exit Criteria: No runaway loops, all high-risk actions require approval            │
│                                                                                      │
│  ───────────────────────────────────────────────────────────────────────────────── │
│                                                                                      │
│  PHASE 8: DOCUMENTATION & RELEASE                                                   │
│  ────────────────────────────────                                                   │
│  Priority: P1                                                                        │
│                                                                                      │
│  ☐ 8.1 Write user documentation                                                    │
│  ☐ 8.2 Create examples                                                             │
│  ☐ 8.3 Update CLAUDE.md                                                            │
│  ☐ 8.4 Create video demo                                                           │
│  ☐ 8.5 GitHub release v1.0.0                                                       │
│                                                                                      │
│  Exit Criteria: Complete docs, ready for external use                               │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### 8.3 Quick Start (After Implementation)

```bash
# Install dependencies
npm install -g @google/gemini-cli
pip install chromadb litellm

# Configure API keys
export ANTHROPIC_API_KEY="sk-..."
export GOOGLE_AI_API_KEY="..."
export OPENAI_API_KEY="sk-..."

# Initialize DAA
./Automation/scripts/do-anything.sh init

# Run your first goal
/do-anything "Create a Python CLI tool that fetches weather data"

# Run with options
/do-anything "Refactor auth module to use JWT" --max-iterations 5 --parallel

# Monitor execution
/do-anything status

# View metrics
/do-anything metrics --last 7d
```

---

## References

### Core Patterns
- [Ralph Wiggum Loops](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/) - Geoffrey Huntley
- [Claude Code Agent Loop](https://blog.promptlayer.com/claude-code-behind-the-scenes-of-the-master-agent-loop/) - PromptLayer
- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) - Anthropic

### Frameworks
- [LangChain/LangGraph](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen) - DataCamp
- [AI Agent Frameworks 2025](https://www.turing.com/resources/ai-agent-frameworks) - Turing
- [claude-flow](https://github.com/ruvnet/claude-flow) - ruvnet

### Token Optimization
- [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching) - Anthropic
- [Token-Efficient Tools](https://www.anthropic.com/news/token-saving-updates) - Anthropic
- [Cost Optimization](https://www.finout.io/blog/anthropic-api-pricing) - Finout

### Multi-LLM
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) - Google
- [OpenAI Codex](https://github.com/openai/codex) - OpenAI
- [LiteLLM](https://docs.litellm.ai/) - BerriAI
- [Multi-Provider Orchestration](https://dev.to/ash_dubai/multi-provider-llm-orchestration-in-production-a-2026-guide-1g10) - DEV

### Storage
- [Vector Databases 2025](https://www.firecrawl.dev/blog/best-vector-databases-2025) - Firecrawl
- [AI Agent State Management](https://dev.to/inboryn_99399f96579fcd705/state-management-patterns-for-long-running-ai-agents-redis-vs-statefulsets-vs-external-databases-39c5) - DEV

### Safety
- [Agentic AI Safety 2025](https://skywork.ai/blog/agentic-ai-safety-best-practices-2025-enterprise/) - Skywork
- [LLM Guardrails](https://www.datadoghq.com/blog/llm-guardrails-best-practices/) - Datadog
- [AI Guardrails](https://www.guardrailsai.com/) - Guardrails AI

---

**Document Status**: IN PROGRESS
**Current Phase**: Phase 1 - Foundation (Structure Created)
**Last Updated**: 2026-01-11

### Phase 1 Progress

| Task | Status |
|------|--------|
| Project structure | DONE |
| config/settings.json | DONE |
| config/ollama.json | DONE |
| config/notifications.json | DONE |
| sql/schema.sql | DONE |
| n8n/workflows/daa-monitor.json | DONE |
| n8n/workflows/daa-notify.json | DONE |
| scripts/do-anything.sh | DONE |
| Execute schema in Supabase | PENDING |
| Import workflows in n8n | PENDING |
| Configure Slack credentials | PENDING |
| Configure Telegram bot | PENDING |
| Test script | PENDING |

### Next Steps

1. **Execute SQL schema** in Supabase dashboard
2. **Import workflows** in n8n (https://n8n.intentum.pro)
3. **Configure credentials** (Slack, Telegram)
4. **Test do-anything.sh** with simple goal
5. **Begin Phase 2**: Agent Integration

**Estimated Remaining Time**: 3-4 focused sessions

---

*Architecture research complete. Phase 1 implementation in progress.*
