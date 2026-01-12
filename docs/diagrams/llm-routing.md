# Limitless Agent - LLM Routing Diagrams

This document details the intelligent LLM routing system.

---

## Overview

```mermaid
flowchart TB
    subgraph Input
        TASK["Incoming Task"]
    end

    subgraph Analysis
        CA["Complexity Analyzer"]
        RA["Rate Limit Analyzer"]
        COST["Cost Calculator"]
    end

    subgraph Decision
        DEC{{"Select Provider"}}
    end

    subgraph Providers
        subgraph Claude["Claude (Primary)"]
            HAIKU["Haiku<br/>Simple tasks"]
            SONNET["Sonnet<br/>Medium tasks"]
            OPUS["Opus<br/>Complex tasks"]
        end

        subgraph Ollama["Ollama (Secondary)"]
            LLAMA["llama3.2:3b<br/>Quick"]
            CODELLAMA["codellama:13b<br/>Code"]
            MISTRAL["mistral:7b<br/>General"]
        end

        subgraph External["External (Tertiary)"]
            GEMINI["Gemini Pro"]
            GPT["ChatGPT"]
        end
    end

    TASK --> Analysis
    Analysis --> DEC
    DEC --> Claude
    DEC --> Ollama
    DEC --> External
```

---

## Complexity Scoring Algorithm

```mermaid
flowchart TB
    subgraph Indicators
        direction TB
        SI["Simple Indicators<br/>format, validate, list, count"]
        MI["Medium Indicators<br/>analyze, implement, create"]
        CI["Complex Indicators<br/>architect, design, refactor"]
    end

    subgraph Scoring
        BASE["Base Score: 0.5"]

        subgraph Adjustments
            ADJ1["Simple pattern: -0.2"]
            ADJ2["Complex pattern: +0.2"]
            ADJ3["Large context: +0.1-0.2"]
            ADJ4["Multi-step: +0.15"]
        end
    end

    subgraph Final
        CLAMP["Clamp to 0.0-1.0"]

        subgraph Ranges
            R1["0.0-0.3: SIMPLE"]
            R2["0.3-0.7: MEDIUM"]
            R3["0.7-1.0: COMPLEX"]
        end
    end

    Indicators --> BASE
    BASE --> Adjustments
    Adjustments --> CLAMP
    CLAMP --> Ranges
```

---

## Provider Selection Matrix

```mermaid
quadrantChart
    title LLM Selection by Complexity vs Cost
    x-axis Low Cost --> High Cost
    y-axis Simple Task --> Complex Task
    quadrant-1 Claude Opus
    quadrant-2 Claude Sonnet
    quadrant-3 Ollama/Gemini
    quadrant-4 Claude Haiku

    Haiku: [0.15, 0.2]
    Sonnet: [0.4, 0.55]
    Opus: [0.85, 0.9]
    Llama: [0.05, 0.15]
    CodeLlama: [0.08, 0.45]
    Mistral: [0.07, 0.35]
    Gemini: [0.1, 0.5]
    GPT: [0.6, 0.65]
```

---

## Rate Limit Handling

```mermaid
stateDiagram-v2
    [*] --> Available

    Available --> RateLimited: Hit limit
    RateLimited --> Cooldown: Start timer
    Cooldown --> Available: Timer expired

    state Available {
        [*] --> Ready
        Ready --> InUse: Request
        InUse --> Ready: Response
        InUse --> Error: Failure
        Error --> Ready: Retry
    }

    state Cooldown {
        [*] --> Waiting
        Waiting --> Waiting: Check timer
        Waiting --> [*]: Expired
    }
```

---

## Fallback Chain Logic

```mermaid
flowchart TB
    subgraph Primary["PRIMARY: Claude"]
        CL_CHECK{{"Claude<br/>Available?"}}
        CL_EXEC["Execute on Claude"]
    end

    subgraph Secondary["SECONDARY: Ollama"]
        OL_CHECK{{"Ollama<br/>Available?"}}
        OL_SELECT{{"Task Type"}}
        OL_LLAMA["llama3.2:3b"]
        OL_CODE["codellama:13b"]
        OL_MISTRAL["mistral:7b"]
    end

    subgraph Tertiary["TERTIARY: Gemini"]
        GM_CHECK{{"Gemini<br/>Available?"}}
        GM_EXEC["Execute on Gemini"]
    end

    subgraph Quaternary["QUATERNARY: ChatGPT"]
        GP_EXEC["Execute on ChatGPT"]
    end

    subgraph Error
        ERR["Queue & Wait"]
    end

    CL_CHECK -->|Yes| CL_EXEC
    CL_CHECK -->|No| OL_CHECK

    OL_CHECK -->|Yes| OL_SELECT
    OL_SELECT -->|Quick| OL_LLAMA
    OL_SELECT -->|Code| OL_CODE
    OL_SELECT -->|General| OL_MISTRAL

    OL_CHECK -->|No| GM_CHECK
    GM_CHECK -->|Yes| GM_EXEC
    GM_CHECK -->|No| GP_EXEC

    GP_EXEC -->|Fail| ERR
```

---

## Cost Optimization

```mermaid
pie showData
    title Cost Distribution by Model (Typical Session)
    "Haiku (Simple)" : 45
    "Sonnet (Medium)" : 35
    "Opus (Complex)" : 15
    "Ollama (Fallback)" : 5
```

### Cost Comparison

```mermaid
xychart-beta
    title "Cost per 1M Tokens (Input/Output)"
    x-axis ["Haiku", "Sonnet", "Opus", "Gemini", "GPT-4"]
    y-axis "USD" 0 --> 80
    bar [0.25, 3, 15, 1.25, 10]
    bar [1.25, 15, 75, 5, 30]
```

---

## Token Estimation

```mermaid
flowchart LR
    subgraph Input
        TEXT["Input Text"]
    end

    subgraph Estimation
        CHARS["Character Count"]
        WORDS["Word Count"]
        FORMULA["tokens ≈ chars/4<br/>or words * 1.3"]
    end

    subgraph Overhead
        SYSTEM["System Prompt: ~2000"]
        AGENT["Agent Def: ~500"]
        TOOLS["Tool Defs: ~1000"]
        CONTEXT["Context: Variable"]
    end

    subgraph Total
        CALC["Total Estimate"]
        BUFFER["+ 10% Buffer"]
    end

    TEXT --> Estimation
    Estimation --> CALC
    Overhead --> CALC
    CALC --> BUFFER
```

---

## Model Capabilities

```mermaid
flowchart TB
    subgraph Haiku["Claude Haiku - $0.25/1M"]
        H1["Planning"]
        H2["Formatting"]
        H3["Validation"]
        H4["Simple queries"]
        H5["Quick responses"]
    end

    subgraph Sonnet["Claude Sonnet - $3/1M"]
        S1["Coding"]
        S2["Analysis"]
        S3["Research"]
        S4["Documentation"]
        S5["Testing"]
    end

    subgraph Opus["Claude Opus - $15/1M"]
        O1["Architecture"]
        O2["Complex reasoning"]
        O3["Creative tasks"]
        O4["System design"]
        O5["Deep analysis"]
    end

    subgraph OllamaModels["Ollama Models - $0"]
        L1["llama3.2:3b<br/>Quick fallback"]
        L2["codellama:13b<br/>Code-specific"]
        L3["mistral:7b<br/>General purpose"]
    end
```

---

## Response Time Expectations

```mermaid
gantt
    title Average Response Time by Model
    dateFormat X
    axisFormat %s

    section Claude
    Haiku (simple)     :0, 2
    Sonnet (medium)    :0, 5
    Opus (complex)     :0, 15

    section Ollama
    llama3.2:3b        :0, 3
    codellama:13b      :0, 8
    mistral:7b         :0, 6

    section External
    Gemini Pro         :0, 4
    ChatGPT            :0, 6
```

---

## Routing Decision Tree

```mermaid
flowchart TB
    START["New Task"] --> COMPLEXITY["Analyze Complexity"]

    COMPLEXITY --> IS_SIMPLE{{"Score < 0.3?"}}
    IS_SIMPLE -->|Yes| HAIKU_CHECK{{"Haiku available?"}}
    HAIKU_CHECK -->|Yes| USE_HAIKU["Use Haiku"]
    HAIKU_CHECK -->|No| LLAMA["Use llama3.2:3b"]

    IS_SIMPLE -->|No| IS_MEDIUM{{"Score < 0.7?"}}
    IS_MEDIUM -->|Yes| SONNET_CHECK{{"Sonnet available?"}}
    SONNET_CHECK -->|Yes| USE_SONNET["Use Sonnet"]
    SONNET_CHECK -->|No| CODE_CHECK{{"Is code task?"}}
    CODE_CHECK -->|Yes| CODELLAMA["Use codellama:13b"]
    CODE_CHECK -->|No| MISTRAL["Use mistral:7b"]

    IS_MEDIUM -->|No| OPUS_CHECK{{"Opus available?"}}
    OPUS_CHECK -->|Yes| USE_OPUS["Use Opus"]
    OPUS_CHECK -->|No| GEMINI_CHECK{{"Gemini available?"}}
    GEMINI_CHECK -->|Yes| USE_GEMINI["Use Gemini Pro"]
    GEMINI_CHECK -->|No| USE_GPT["Use ChatGPT"]
```
