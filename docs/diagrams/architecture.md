# Limitless Agent - Architecture Diagrams

This document contains all architecture diagrams for the Limitless Agent system.

---

## System Overview

```mermaid
flowchart TB
    subgraph User["USER LAYER"]
        U1["Developer"]
        U2["Webhook Client"]
        U3["Scheduled Job"]
    end

    subgraph Interface["INTERFACE LAYER"]
        CLI["CLI<br/>limitless.sh"]
        N8N["n8n Webhooks<br/>limitless-trigger"]
        CRON["Cron Jobs"]
    end

    subgraph Core["LIMITLESS CORE"]
        direction TB
        RL["Ralph Loop Engine"]
        GD["Goal Decomposer"]
        AR["Agent Router"]
        MR["Model Router"]
        CC["Completion Checker"]
        SM["State Manager"]
    end

    subgraph Agents["SPECIALIZED AGENTS (27)"]
        direction LR
        subgraph Dev["Development"]
            A1["fullstack-developer"]
            A2["frontend-developer"]
            A3["backend-architect"]
            A4["code-reviewer"]
            A5["task-decomposition"]
            A6["prompt-engineer"]
        end
        subgraph Research["Research"]
            A7["competitive-intel"]
            A8["market-research"]
            A9["seo-analyzer"]
            A10["sales-automator"]
        end
        subgraph Content["Content"]
            A11["podcast-*"]
            A12["social-media"]
            A13["content-curator"]
            A14["video-editor"]
        end
        subgraph PKM["PKM"]
            A15["connection-agent"]
            A16["moc-agent"]
            A17["metadata-agent"]
            A18["tag-agent"]
            A19["review-agent"]
        end
    end

    subgraph LLMs["LLM PROVIDERS"]
        direction LR
        CL["Claude MAX<br/>Primary"]
        OL["Ollama<br/>Secondary"]
        GM["Gemini<br/>Tertiary"]
        GP["ChatGPT<br/>Quaternary"]
    end

    subgraph Storage["PERSISTENCE LAYER"]
        direction LR
        SB["Supabase<br/>PostgreSQL"]
        PG["pgvector<br/>Embeddings"]
        MEM["Memory MCP<br/>Context"]
    end

    subgraph Monitor["MONITORING & ALERTS"]
        direction LR
        MON["n8n Monitor"]
        MET["Metrics"]
        SLK["Slack"]
        TG["Telegram"]
    end

    User --> Interface
    Interface --> Core
    Core --> Agents
    Agents --> LLMs
    Core --> Storage
    Core --> Monitor

    CL -.->|fallback| OL
    OL -.->|fallback| GM
    GM -.->|fallback| GP
```

---

## Core Engine Detail

```mermaid
flowchart TB
    subgraph RalphLoop["RALPH LOOP ENGINE"]
        START["Start"] --> INIT["Initialize State"]
        INIT --> LOAD["Load Context"]
        LOAD --> DECOMPOSE["Decompose Goal"]
        DECOMPOSE --> SELECT["Select Agents"]
        SELECT --> ROUTE["Route to Model"]
        ROUTE --> EXECUTE["Execute Task"]
        EXECUTE --> CHECK{"Goal<br/>Complete?"}
        CHECK -->|No| UPDATE["Update State"]
        UPDATE --> LOAD
        CHECK -->|Yes| FINISH["Finish"]

        subgraph Guards["SAFETY GUARDS"]
            G1["Max Iterations"]
            G2["Cost Limit"]
            G3["Token Limit"]
            G4["Timeout"]
        end

        CHECK --> Guards
        Guards -->|Triggered| ABORT["Abort"]
    end
```

---

## Agent Categories

```mermaid
mindmap
    root((Limitless<br/>Agent))
        Development
            fullstack-developer
            frontend-developer
            backend-architect
            code-reviewer
            task-decomposition
            prompt-engineer
        Research
            competitive-intel
            market-research
            seo-analyzer
            sales-automator
        Content
            podcast-analyzer
            podcast-metadata
            social-media
            content-curator
            video-editor
            timestamp-specialist
        PKM
            connection-agent
            moc-agent
            metadata-agent
            tag-agent
            review-agent
        Utility
            context-manager
            cli-ui-designer
            ui-ux-designer
            visual-analysis-ocr
```

---

## Database Schema

```mermaid
erDiagram
    limitless_executions ||--o{ limitless_tasks : contains
    limitless_executions {
        uuid id PK
        text goal
        varchar status "pending|running|completed|failed|cancelled"
        timestamp started_at
        timestamp completed_at
        int duration_ms
        int iteration_count
        int max_iterations "default: 100"
        jsonb result
        text error
        jsonb metadata
    }

    limitless_tasks ||--o{ limitless_agent_runs : has
    limitless_tasks ||--o| limitless_tasks : subtask_of
    limitless_tasks {
        uuid id PK
        uuid execution_id FK
        uuid parent_task_id FK "self-reference for subtasks"
        varchar name
        text description
        varchar status "pending|running|completed|failed|skipped"
        varchar agent_name "e.g. fullstack-developer"
        varchar model_used "e.g. claude-opus-4-5"
        jsonb input
        jsonb output
        int tokens_input
        int tokens_output
        decimal cost_usd
        int duration_ms
        int sequence_order
    }

    limitless_agent_runs {
        uuid id PK
        uuid task_id FK
        varchar agent_name
        varchar model_name
        boolean success
        int execution_time_ms
        int tokens_input
        int tokens_output
        text error
    }

    limitless_memory {
        uuid id PK
        varchar key UK "unique key for lookup"
        jsonb value
        varchar memory_type "general|session|user_preference|learned_pattern"
        decimal importance "0.0-1.0 for pruning"
        int access_count
        timestamp last_accessed_at
        timestamp expires_at
    }

    limitless_documents {
        bigint id PK
        text content
        jsonb metadata
        vector embedding "768 dims (Gemini) or 1536 (OpenAI)"
        varchar doc_id
        varchar doc_title
        varchar doc_type
        varchar source
        boolean processed
        varchar enricher_version
        timestamp enriched_at
    }

    limitless_metrics {
        uuid id PK
        varchar metric_name
        decimal metric_value
        varchar dimension
        varchar dimension_value
        timestamp period_start
        timestamp period_end
    }
```

---

## Deployment Architecture

```mermaid
flowchart TB
    subgraph Local["LOCAL MACHINE"]
        CLI["Claude Code CLI"]
        SCRIPT["limitless.sh"]
        OLLAMA["Ollama Server"]
    end

    subgraph Cloud["CLOUD SERVICES"]
        subgraph Anthropic["Anthropic"]
            CLAUDE["Claude API"]
        end

        subgraph Google["Google"]
            GEMINI["Gemini API"]
        end

        subgraph OpenAI["OpenAI"]
            GPT["ChatGPT API"]
        end

        subgraph Supabase["Supabase"]
            POSTGRES["PostgreSQL"]
            PGVECTOR["pgvector"]
        end
    end

    subgraph SelfHosted["SELF-HOSTED"]
        N8N["n8n<br/>n8n.intentum.pro"]
        OLLAMA_REMOTE["Ollama<br/>ollama.intentum.ai"]
    end

    subgraph Notifications["NOTIFICATIONS"]
        SLACK["Slack"]
        TELEGRAM["Telegram"]
    end

    CLI --> SCRIPT
    SCRIPT --> CLAUDE
    SCRIPT --> OLLAMA
    SCRIPT --> OLLAMA_REMOTE
    OLLAMA_REMOTE --> GEMINI
    GEMINI --> GPT

    SCRIPT --> POSTGRES
    N8N --> SLACK
    N8N --> TELEGRAM
    N8N --> POSTGRES
```

---

## Security Architecture

```mermaid
flowchart TB
    subgraph Input["INPUT VALIDATION"]
        IV1["Goal Sanitization"]
        IV2["Pattern Blocking"]
        IV3["Rate Limiting"]
    end

    subgraph Execution["EXECUTION CONTROLS"]
        EC1["Max Iterations: 100"]
        EC2["Cost Limit: $10"]
        EC3["Token Limit: 500K"]
        EC4["Timeout: 5min/iter"]
    end

    subgraph Circuit["CIRCUIT BREAKER"]
        CB1["3 failures → PAUSE"]
        CB2["Same error 2x → STOP"]
        CB3["Cost exceeded → STOP"]
    end

    subgraph Human["HUMAN-IN-THE-LOOP"]
        HI1["LOW: Auto-execute"]
        HI2["MEDIUM: Notify"]
        HI3["HIGH: Require approval"]
    end

    subgraph Audit["AUDIT & LOGGING"]
        AU1["Structured JSON logs"]
        AU2["Metrics collection"]
        AU3["Alert system"]
    end

    Input --> Execution
    Execution --> Circuit
    Circuit --> Human
    Human --> Audit
```

---

## Integration Points

```mermaid
flowchart LR
    subgraph Limitless["LIMITLESS AGENT"]
        CORE["Core Engine"]
    end

    subgraph MCPs["MCP SERVERS (14)"]
        M1["memory"]
        M2["notion"]
        M3["supabase"]
        M4["github"]
        M5["vercel"]
        M6["filesystem"]
        M7["fetch"]
        M8["markitdown"]
        M9["shadcn"]
        M10["context7"]
        M11["figma"]
        M12["n8n"]
        M13["obsidian"]
        M14["genkit"]
    end

    subgraph Skills["SKILLS (27)"]
        S1["docx/pdf/pptx/xlsx"]
        S2["notion-*"]
        S3["algorithmic-art"]
        S4["webapp-testing"]
        S5["mcp-builder"]
        S6["..."]
    end

    CORE <--> MCPs
    CORE <--> Skills
```
