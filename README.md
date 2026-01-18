# Limitless Agent

<div align="center">

```
 ██╗     ██╗███╗   ███╗██╗████████╗██╗     ███████╗███████╗███████╗
 ██║     ██║████╗ ████║██║╚══██╔══╝██║     ██╔════╝██╔════╝██╔════╝
 ██║     ██║██╔████╔██║██║   ██║   ██║     █████╗  ███████╗███████╗
 ██║     ██║██║╚██╔╝██║██║   ██║   ██║     ██╔══╝  ╚════██║╚════██║
 ███████╗██║██║ ╚═╝ ██║██║   ██║   ███████╗███████╗███████║███████║
 ╚══════╝╚═╝╚═╝     ╚═╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚══════╝
```

**"What if you could access 100% of your brain?"**

*Inspired by the film Limitless (2011) and the NZT-48 pill*

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-integrated-green.svg)]()
[![Supabase](https://img.shields.io/badge/Supabase-Ready-3ECF8E.svg)](https://supabase.com)

</div>

---

## Real Life OS Integration

LimitlessAgent is now integrated into the **Real Life OS** architecture as a domain (`limitless_`):

| Resource | Value |
|----------|-------|
| **Supabase Project** | intentum |
| **Tables** | 6 (limitless_*) |
| **RLS** | 100% enabled |
| **Status** | Ready v2.0.0 |

```sql
-- Tables deployed
limitless_executions    -- Agent runs/goals
limitless_tasks         -- Subtasks per execution
limitless_memory        -- Persistent memory
limitless_documents     -- RAG vector store
limitless_agent_runs    -- Performance tracking
limitless_metrics       -- Aggregated metrics
```

See [CHANGELOG.md](CHANGELOG.md) for security migrations and v2.0.0 details.

---

## Overview

**Limitless Agent** is an autonomous AI system that unlocks the full potential of the claude-code ecosystem:

- **27 Specialized Agents** - Your army of experts
- **27 Skills** - Instant capabilities
- **14 MCPs** - External integrations
- **Multi-LLM Fallback** - Never hit a wall

Like NZT-48, Limitless Agent removes the barriers between you and accomplishment.

> *"I wasn't high. I wasn't wired. Just clear. I knew what I needed to do and how to do it."*
> — Eddie Morra, Limitless

---

## Architecture

```mermaid
flowchart TB
    subgraph Interface["INTERFACE LAYER"]
        CLI["CLI Command"]
        N8N["n8n Webhooks"]
        API["REST API (Future)"]
    end

    subgraph Core["LIMITLESS CORE"]
        RL["Ralph Loop Engine"]
        GD["Goal Decomposer"]
        AR["Agent Router"]
        MR["Model Router"]
    end

    subgraph Agents["AGENT POOL (27)"]
        DEV["Development (6)"]
        RES["Research (4)"]
        CON["Content (6)"]
        PKM["PKM (5)"]
        UTL["Utility (6)"]
    end

    subgraph LLMs["LLM GATEWAY"]
        CL["Claude MAX"]
        OL["Ollama"]
        GM["Gemini"]
        GP["ChatGPT"]
    end

    subgraph Storage["PERSISTENCE"]
        SB["Supabase"]
        PG["pgvector"]
        MEM["Memory MCP"]
    end

    subgraph Monitor["MONITORING"]
        MON["n8n Monitor"]
        SLK["Slack"]
        TG["Telegram"]
    end

    Interface --> Core
    Core --> Agents
    Agents --> LLMs
    LLMs --> Storage
    Core --> Monitor

    CL -->|"fallback"| OL
    OL -->|"fallback"| GM
    GM -->|"fallback"| GP
```

---

## The NZT Protocol

Just like NZT-48 enhances cognitive function, the Limitless Agent follows the **NZT Protocol**:

```mermaid
flowchart LR
    subgraph NZT["NZT PROTOCOL"]
        N["N: Navigate"]
        Z["Z: Zero-in"]
        T["T: Transform"]
    end

    GOAL["Goal"] --> N
    N -->|"Decompose"| Z
    Z -->|"Execute"| T
    T -->|"Complete?"| CHECK{Done?}
    CHECK -->|"No"| N
    CHECK -->|"Yes"| SUCCESS["Success"]
```

| Phase | Action | Component |
|-------|--------|-----------|
| **N**avigate | Understand and decompose the goal | Goal Decomposer |
| **Z**ero-in | Select optimal agents and models | Agent/Model Router |
| **T**ransform | Execute and iterate until complete | Ralph Loop Engine |

---

## Project Structure

```
LimitlessAgent/
├── README.md                              # You are here
├── LICENSE                                # MIT License
├── .gitignore                             # Git ignore rules
│
├── docs/                                  # Documentation
│   ├── SPECIFICATION.md                   # Technical spec (PRD/RFC)
│   ├── ARCHITECTURE.md                    # Architecture reference
│   ├── QUICKSTART.md                      # Getting started guide
│   ├── API.md                             # API reference
│   ├── diagrams/                          # Visual diagrams
│   │   ├── architecture.md                # Mermaid diagrams
│   │   ├── data-flow.md                   # Data flow diagrams
│   │   └── llm-routing.md                 # LLM routing logic
│   └── examples/                          # Usage examples
│       ├── simple-goal.md
│       ├── complex-goal.md
│       └── parallel-execution.md
│
├── config/                                # Configuration
│   ├── settings.json                      # Main configuration
│   ├── ollama.json                        # Ollama models
│   ├── notifications.json                 # Slack/Telegram
│   └── limits.json                        # Safety limits
│
├── n8n/                                   # n8n Workflows
│   └── workflows/
│       ├── limitless-monitor.json         # Monitoring workflow
│       ├── limitless-notify.json          # Notification workflow
│       └── limitless-trigger.json         # External trigger
│
├── sql/                                   # Database
│   ├── schema.sql                         # Main schema
│   ├── migrations/                        # Schema migrations
│   └── seeds/                             # Initial data
│
├── scripts/                               # Executables
│   ├── limitless.sh                       # Main entry point
│   ├── install.sh                         # Installation script
│   └── health-check.sh                    # Health verification
│
├── src/                                   # Source code
│   ├── core/                              # Core engine
│   │   ├── ralph-loop.js                  # Main loop
│   │   ├── goal-decomposer.js             # Goal analysis
│   │   └── completion-checker.js          # Success detection
│   ├── routing/                           # Routing logic
│   │   ├── agent-router.js                # Agent selection
│   │   ├── model-router.js                # LLM selection
│   │   └── fallback-chain.js              # Fallback handling
│   ├── integrations/                      # External integrations
│   │   ├── supabase.js                    # Database client
│   │   ├── ollama.js                      # Ollama client
│   │   └── notifications.js               # Slack/Telegram
│   └── utils/                             # Utilities
│       ├── logger.js                      # Logging
│       ├── metrics.js                     # Metrics collection
│       └── token-counter.js               # Token estimation
│
├── tests/                                 # Tests
│   ├── unit/                              # Unit tests
│   ├── integration/                       # Integration tests
│   └── e2e/                               # End-to-end tests
│
└── logs/                                  # Execution logs
    └── .gitkeep
```

---

## Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Primary LLM** | Claude MAX | Main reasoning engine |
| **Fallback LLMs** | Ollama, Gemini, ChatGPT | Multi-provider resilience |
| **Database** | Supabase (PostgreSQL + pgvector) | State & vector storage |
| **Orchestration** | n8n | Visual workflow automation |
| **Notifications** | Slack, Telegram | Real-time alerts |
| **Core Pattern** | Ralph Loop | Autonomous iteration |

### Ollama Models

| Model | Parameters | Use Case | Priority |
|-------|------------|----------|----------|
| `llama3.2:3b` | 3B | Quick tasks, validation | 1 (fastest) |
| `codellama:13b` | 13B | Code generation/review | 2 (code) |
| `mistral:7b` | 7B | General reasoning | 3 (fallback) |

### LLM Fallback Chain

```mermaid
flowchart LR
    subgraph Primary
        CLAUDE["Claude MAX"]
    end

    subgraph Secondary
        OLLAMA["Ollama<br/>(self-hosted)"]
    end

    subgraph Tertiary
        GEMINI["Gemini Pro"]
    end

    subgraph Quaternary
        GPT["ChatGPT"]
    end

    CLAUDE -->|"rate limited"| OLLAMA
    OLLAMA -->|"unavailable"| GEMINI
    GEMINI -->|"quota exceeded"| GPT

    style CLAUDE fill:#6366f1
    style OLLAMA fill:#22c55e
    style GEMINI fill:#3b82f6
    style GPT fill:#10b981
```

**Cost**: $0 additional (all services already available)

---

## Quick Start

### Prerequisites

- Claude Code CLI installed
- Supabase account (free tier works)
- n8n instance (self-hosted or cloud)
- Ollama running (optional but recommended)

### Installation

```bash
# Clone the repository
git clone https://github.com/matheusallvarenga/limitless-agent.git
cd limitless-agent

# Run installation script
./scripts/install.sh

# Or manual setup:

# 1. Execute SQL schema in Supabase
psql $DATABASE_URL -f sql/schema.sql

# 2. Import n8n workflows
# Upload n8n/workflows/*.json to your n8n instance

# 3. Configure environment
cp config/settings.example.json config/settings.json
# Edit with your credentials

# 4. Make script executable
chmod +x scripts/limitless.sh
```

### Usage

```bash
# Basic usage
./scripts/limitless.sh "Create a REST API with authentication"

# With options
./scripts/limitless.sh run "Build a landing page" --max-iterations 10

# Check status
./scripts/limitless.sh status

# Health check
./scripts/limitless.sh health

# View help
./scripts/limitless.sh help
```

---

## n8n Integration

### Webhooks

| Endpoint | Purpose |
|----------|---------|
| `POST /webhook/limitless-monitor` | Query execution status, KPIs |
| `POST /webhook/limitless-notify` | Receive notifications |
| `POST /webhook/limitless-trigger` | Trigger new executions |

### Workflows

```mermaid
flowchart TB
    subgraph Trigger["limitless-trigger"]
        T1["Webhook"] --> T2["Validate"]
        T2 --> T3["Start Execution"]
    end

    subgraph Monitor["limitless-monitor"]
        M1["Webhook"] --> M2["Get Status"]
        M2 --> M3["Calculate KPIs"]
        M3 --> M4["Return JSON"]
    end

    subgraph Notify["limitless-notify"]
        N1["Webhook"] --> N2["Route Event"]
        N2 --> N3["Slack"]
        N2 --> N4["Telegram"]
    end
```

---

## Roadmap

```mermaid
gantt
    title Limitless Agent Roadmap
    dateFormat  YYYY-MM-DD
    section Phase 1
    Foundation + n8n           :active, p1, 2026-01-11, 7d
    section Phase 2
    Agent Integration          :p2, after p1, 7d
    section Phase 3
    Token Optimization         :p3, after p2, 5d
    section Phase 4
    Parallel Execution         :p4, after p3, 7d
    section Phase 5
    Memory & Learning          :p5, after p4, 7d
    section Phase 6
    Safety & Polish            :p6, after p5, 5d
```

| Phase | Focus | Status |
|-------|-------|--------|
| **Phase 1** | Foundation + n8n | ✅ Complete |
| **Phase 1.5** | Database Security + Real Life OS | ✅ Complete |
| **Phase 2** | Agent Integration | In Progress |
| **Phase 3** | Token Optimization | Pending |
| **Phase 4** | Parallel Execution | Pending |
| **Phase 5** | Memory & Learning | Pending |
| **Phase 6** | Safety & Polish | Pending |

---

## Documentation

- [Technical Specification](docs/SPECIFICATION.md) - Complete PRD/RFC
- [Architecture Reference](docs/ARCHITECTURE.md) - System design
- [Quick Start Guide](docs/QUICKSTART.md) - Get running fast
- [API Reference](docs/API.md) - Endpoints and schemas
- [Examples](docs/examples/) - Usage examples

---

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- **Limitless (2011)** - For the inspiration
- **Geoffrey Huntley** - For the Ralph Loop pattern
- **Anthropic** - For Claude and the Agent SDK
- **The AI Community** - For countless open-source contributions

---

<div align="center">

**"I see everything. I understand everything."**

*— Eddie Morra*

---

Made with NZT-48 by [Matheus Allvarenga](https://github.com/matheusallvarenga)

</div>
