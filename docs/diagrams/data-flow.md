# Limitless Agent - Data Flow Diagrams

This document details all data flows in the Limitless Agent system.

---

## Main Execution Flow

```mermaid
sequenceDiagram
    participant U as User
    participant CLI as limitless.sh
    participant RL as Ralph Loop
    participant GD as Goal Decomposer
    participant AR as Agent Router
    participant MR as Model Router
    participant AG as Agent (Task)
    participant LLM as LLM Provider
    participant DB as Supabase
    participant N8N as n8n

    U->>CLI: ./limitless.sh "Create REST API"
    CLI->>DB: Create execution record
    CLI->>N8N: Notify task_started
    CLI->>RL: Start loop(goal, max_iter)

    loop Until goal complete or max iterations
        RL->>GD: Decompose goal
        GD->>LLM: Analyze goal
        LLM-->>GD: Subgoals[]
        GD-->>RL: Task plan

        RL->>AR: Select agents(tasks)
        AR-->>RL: Agent assignments

        RL->>MR: Route model(complexity)
        MR-->>RL: Selected model

        RL->>AG: Execute(task, model)
        AG->>LLM: Process task
        LLM-->>AG: Result
        AG-->>RL: Task result

        RL->>DB: Update state
        RL->>RL: Check completion
    end

    RL-->>CLI: Final result
    CLI->>DB: Update execution status
    CLI->>N8N: Notify task_completed
    N8N->>N8N: Route to Slack/Telegram
    CLI-->>U: Summary + artifacts
```

---

## Goal Decomposition Flow

```mermaid
flowchart TB
    subgraph Input
        GOAL["Goal: Create REST API with auth"]
    end

    subgraph Analysis
        A1["Identify domain<br/>(Development)"]
        A2["Estimate complexity<br/>(Medium-High)"]
        A3["List requirements<br/>(Auth, CRUD, Tests)"]
    end

    subgraph Decomposition
        T1["Setup project structure"]
        T2["Create database schema"]
        T3["Implement auth (JWT)"]
        T4["Implement CRUD endpoints"]
        T5["Write tests"]
        T6["Generate documentation"]
    end

    subgraph Dependencies
        D1["T1 → T2 → T3"]
        D2["T3 → T4"]
        D3["T4 → T5"]
        D4["T5 → T6"]
    end

    subgraph AgentAssignment
        AA1["T1: backend-architect"]
        AA2["T2: backend-architect"]
        AA3["T3: fullstack-developer"]
        AA4["T4: fullstack-developer"]
        AA5["T5: code-reviewer"]
        AA6["T6: frontend-developer"]
    end

    GOAL --> Analysis
    Analysis --> Decomposition
    Decomposition --> Dependencies
    Dependencies --> AgentAssignment
```

---

## LLM Routing Flow

```mermaid
flowchart TB
    subgraph Request
        REQ["Task Request"]
        COMP["Complexity Score: 0.0-1.0"]
    end

    subgraph ComplexityCheck
        C1{{"score < 0.3"}}
        C2{{"score < 0.7"}}
        C3{{"score >= 0.7"}}
    end

    subgraph ModelSelection
        M1["Claude Haiku<br/>$0.25/1M"]
        M2["Claude Sonnet<br/>$3/1M"]
        M3["Claude Opus<br/>$15/1M"]
    end

    subgraph RateLimitCheck
        RL1{{"Claude available?"}}
        RL2{{"Ollama available?"}}
        RL3{{"Gemini available?"}}
    end

    subgraph Fallback
        F1["Ollama (llama3.2)"]
        F2["Gemini Pro"]
        F3["ChatGPT"]
    end

    REQ --> COMP
    COMP --> C1
    COMP --> C2
    COMP --> C3

    C1 -->|Yes| M1
    C2 -->|Yes| M2
    C3 -->|Yes| M3

    M1 --> RL1
    M2 --> RL1
    M3 --> RL1

    RL1 -->|No| RL2
    RL2 -->|Yes| F1
    RL2 -->|No| RL3
    RL3 -->|Yes| F2
    RL3 -->|No| F3
```

---

## State Management Flow

```mermaid
stateDiagram-v2
    [*] --> Pending: Create execution
    Pending --> Running: Start
    Running --> Running: Iterate
    Running --> Completed: Goal achieved
    Running --> Failed: Error/Max iterations
    Running --> Cancelled: User cancel
    Completed --> [*]
    Failed --> [*]
    Cancelled --> [*]

    state Running {
        [*] --> Decomposing
        Decomposing --> SelectingAgents
        SelectingAgents --> RoutingModel
        RoutingModel --> Executing
        Executing --> CheckingCompletion
        CheckingCompletion --> Decomposing: Not complete
        CheckingCompletion --> [*]: Complete
    }
```

---

## Notification Flow

```mermaid
flowchart TB
    subgraph Events
        E1["task_started"]
        E2["task_completed"]
        E3["task_failed"]
        E4["approval_required"]
        E5["daily_summary"]
    end

    subgraph N8N["n8n Workflow"]
        WEBHOOK["Webhook Trigger"]
        ROUTER["Event Router"]
    end

    subgraph SlackChannel["Slack #limitless-notifications"]
        S1["Started notification"]
        S2["Completed notification"]
        S3["Failed notification"]
        S4["Approval request"]
        S5["Daily digest"]
    end

    subgraph TelegramBot["Telegram @LimitlessBot"]
        T1["Started message"]
        T2["Completed message"]
        T3["Failed message"]
        T4["Approval prompt"]
        T5["Daily report"]
    end

    Events --> WEBHOOK
    WEBHOOK --> ROUTER

    ROUTER --> S1
    ROUTER --> S2
    ROUTER --> S3
    ROUTER --> S4
    ROUTER --> S5

    S1 --> T1
    S2 --> T2
    S3 --> T3
    S4 --> T4
    S5 --> T5
```

---

## Memory & Context Flow

```mermaid
flowchart TB
    subgraph Sources
        S1["Current Goal"]
        S2["Previous Results"]
        S3["Similar Past Goals"]
        S4["User Preferences"]
        S5["Error Patterns"]
    end

    subgraph Processing
        P1["Memory MCP"]
        P2["pgvector Search"]
        P3["Context Compression"]
    end

    subgraph Context
        C1["Assembled Context"]
        C2["Token Estimation"]
        C3["Priority Ranking"]
    end

    subgraph Output
        O1["Optimized Prompt"]
    end

    Sources --> Processing
    Processing --> Context
    Context --> Output
```

---

## Parallel Execution Flow (Future)

```mermaid
flowchart TB
    subgraph MainProcess
        MP["Main Process"]
    end

    subgraph TMux["tmux Session"]
        P1["Pane 1<br/>Task 1"]
        P2["Pane 2<br/>Task 2"]
        P3["Pane 3<br/>Task 3"]
    end

    subgraph Worktrees["Git Worktrees"]
        W1["worktree-1<br/>branch: limitless/task-1"]
        W2["worktree-2<br/>branch: limitless/task-2"]
        W3["worktree-3<br/>branch: limitless/task-3"]
    end

    subgraph Aggregation
        AGG["Result Aggregator"]
        MERGE["Git Merge"]
        CONFLICT["Conflict Resolution"]
    end

    MP --> TMux
    P1 --> W1
    P2 --> W2
    P3 --> W3

    W1 --> AGG
    W2 --> AGG
    W3 --> AGG

    AGG --> MERGE
    MERGE --> CONFLICT
```

---

## Error Handling Flow

```mermaid
flowchart TB
    subgraph Execution
        EXEC["Execute Task"]
    end

    subgraph ErrorTypes
        E1["API Error"]
        E2["Rate Limit"]
        E3["Timeout"]
        E4["Invalid Response"]
        E5["Cost Exceeded"]
    end

    subgraph Handlers
        H1["Retry with backoff"]
        H2["Switch to fallback"]
        H3["Extend timeout"]
        H4["Log & skip"]
        H5["Stop execution"]
    end

    subgraph Recovery
        R1["Continue"]
        R2["Abort"]
        R3["Notify user"]
    end

    EXEC --> E1
    EXEC --> E2
    EXEC --> E3
    EXEC --> E4
    EXEC --> E5

    E1 --> H1
    E2 --> H2
    E3 --> H3
    E4 --> H4
    E5 --> H5

    H1 --> R1
    H2 --> R1
    H3 --> R1
    H4 --> R1
    H5 --> R2
    R2 --> R3
```
