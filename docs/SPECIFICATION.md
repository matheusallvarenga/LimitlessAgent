# Limitless Agent - Technical Specification

**Document Type**: RFC / PRD
**Version**: 1.0.0
**Status**: IN PROGRESS - Phase 1 Implementation Started
**Author**: Matheus Allvarenga
**Date**: 2026-01-11
**Last Updated**: 2026-01-11
**Repository**: https://github.com/matheusallvarenga/claude-code

---

## Executive Summary

Este documento especifica a criação do **Limitless Agent** - um sistema de agente autônomo inspirado no filme Limitless (2011), capaz de realizar qualquer tarefa complexa utilizando o ecossistema completo de 27 agentes especializados, 27 skills, 14 MCPs, e integrações com múltiplas LLMs.

*"What if you could access 100% of your brain?"*

O Limitless Agent será construído sobre padrões comprovados pela indústria, incluindo o **NZT Protocol (Ralph Loop)** (Geoffrey Huntley), **Claude Agent SDK** (Anthropic), e arquiteturas multi-agente validadas por AWS, Anthropic e comunidade open-source.

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Goals & Non-Goals](#2-goals--non-goals)
3. [Background & Research](#3-background--research)
4. [Proposed Solution](#4-proposed-solution)
5. [Technical Architecture](#5-technical-architecture)
6. [Implementation Roadmap](#6-implementation-roadmap)
7. [Resource Requirements](#7-resource-requirements)
8. [Risk Analysis](#8-risk-analysis)
9. [Success Metrics](#9-success-metrics)
10. [Appendices](#10-appendices)

---

## Implementation Decisions (2026-01-11)

As decisoes abaixo foram tomadas durante a sessao de planejamento e inicio de implementacao:

### Database: Supabase Cloud
- **Decisao**: Usar Supabase cloud em vez de SQLite local
- **Razao**: Acesso remoto, pgvector nativo, backup automatico
- **Impacto**: Schema SQL criado em `sql/schema.sql`

### Monitoring: n8n na Fase 1
- **Decisao**: Incluir n8n na Fase 1 (nao deixar para depois)
- **Razao**: +3h de trabalho vs visibilidade imediata
- **Impacto**: Workflows criados em `n8n/workflows/`

### Notificacoes: Slack + Telegram
- **Decisao**: Slack como primario, Telegram como backup
- **Razao**: Cobertura dupla, preferencia do usuario
- **Impacto**: Configuracao em `config/notifications.json`

### Ollama Models (Instalados)
- **llama3.2:3b**: Quick tasks, fallback rapido
- **codellama:13b**: Code generation, code review
- **mistral:7b**: General reasoning, analysis
- **Endpoint**: https://ollama.intentum.ai

### LLM Fallback Chain
```
Claude MAX → Ollama (self-hosted) → Gemini Pro → ChatGPT
```

### Estrutura de Projeto Criada
```
LimitlessAgent/
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── SPECIFICATION.md
│   ├── ARCHITECTURE.md
│   ├── QUICKSTART.md
│   ├── API.md
│   ├── diagrams/
│   └── examples/
├── config/
│   ├── settings.json
│   ├── ollama.json
│   ├── notifications.json
│   └── limits.json
├── n8n/workflows/
│   ├── limitless-monitor.json
│   ├── limitless-notify.json
│   └── limitless-trigger.json
├── sql/
│   └── schema.sql
├── scripts/
│   ├── limitless.sh
│   ├── install.sh
│   └── health-check.sh
├── src/
└── tests/
```

---

## 1. Problem Statement

### 1.1 Current State

O sistema atual possui:
- **27 agentes especializados** em `.claude/agents/`
- **27 skills** em `.claude/skills/`
- **14 MCP servers** configurados
- **24 slash commands**
- **1 workflow-orchestrator** (declarativo, não-agêntico)

**Problema**: Estes recursos operam de forma **isolada e manual**. Não existe um sistema que:
- Orquestre agentes automaticamente baseado em goals
- Itere autonomamente até completar objetivos
- Aproveite o ecossistema de forma integrada
- Persista contexto entre sessões
- Execute tarefas em paralelo

### 1.2 Gap Analysis

| Capacidade | Estado Atual | Estado Desejado |
|------------|--------------|-----------------|
| Autonomia | Manual | Autônomo com supervisão |
| Orquestração | Nenhuma | Multi-agente inteligente |
| Paralelismo | Nenhum | tmux/worktrees |
| Persistência | Sessão única | Memory MCP + DB |
| Multi-LLM | Claude only | Claude + Ollama + Gemini + ChatGPT |
| Economia | Não otimizado | Token-efficient routing |

### 1.3 Impact

Sem um Do Anything Agent:
- 70% do potencial do ecossistema é subutilizado
- Tarefas complexas requerem supervisão constante
- Sem continuidade entre sessões
- Sem paralelismo para tasks independentes
- Custo de tokens não otimizado

---

## 2. Goals & Non-Goals

### 2.1 Goals (Must Have)

| ID | Goal | Priority |
|----|------|----------|
| G1 | Implementar Ralph Loop como core pattern | P0 |
| G2 | Orquestrar 27 agentes via Task tool | P0 |
| G3 | Integrar 14 MCPs nativamente | P0 |
| G4 | Persistir contexto via Memory MCP | P1 |
| G5 | Suportar multi-instance via tmux | P1 |
| G6 | Conectar múltiplas LLMs (Claude, Gemini, Codex) | P1 |
| G7 | Otimizar uso de tokens com routing inteligente | P1 |
| G8 | Integrar banco de dados para state management | P2 |
| G9 | Implementar safety controls (circuit breaker) | P0 |
| G10 | Documentação completa e exemplos | P1 |

### 2.2 Non-Goals (Out of Scope v1.0)

| ID | Non-Goal | Reason |
|----|----------|--------|
| NG1 | Interface gráfica/web | CLI-first approach |
| NG2 | Cloud deployment | Local-first, pode evoluir |
| NG3 | Multi-tenant | Single user system |
| NG4 | Real-time collaboration | Não necessário para v1 |
| NG5 | Custom LLM training | Usa modelos existentes |

### 2.3 Success Criteria

1. **Autonomia**: Completar goal complexo com ≤3 intervenções humanas
2. **Economia**: Reduzir custo de tokens em 40% vs uso direto
3. **Velocidade**: 2x faster que execução manual sequencial
4. **Confiabilidade**: 95% completion rate para goals bem definidos

---

## 3. Background & Research

### 3.1 Industry Patterns Analyzed

#### 3.1.1 Ralph Loop (Geoffrey Huntley)
- **Source**: https://paddo.dev/blog/ralph-wiggum-autonomous-loops/
- **Pattern**: `while true; do claude --goal; if complete; break; done`
- **Results**: 3 meses de execução contínua, compiler completo criado
- **Adoption**: Plugin oficial no Claude Code

#### 3.1.2 Claude Agent Loop (Anthropic)
- **Source**: https://blog.promptlayer.com/claude-code-behind-the-scenes-of-the-master-agent-loop/
- **Pattern**: `while(tool_call) → execute → feed results → repeat`
- **Design**: Single-threaded, debuggable, max 1 subagent branch
- **Philosophy**: Simplicidade > Complexidade

#### 3.1.3 claude-flow (ruvnet)
- **Source**: https://github.com/ruvnet/claude-flow
- **Pattern**: 64 agentes, swarm intelligence, hive-mind
- **Features**: 87 MCP tools, SQLite memory, SPARC methodology
- **Results**: 84.8% SWE-Bench solve rate

#### 3.1.4 AWS CLI Agent Orchestrator
- **Source**: https://github.com/awslabs/cli-agent-orchestrator
- **Pattern**: tmux sessions, MCP communication, 3 orchestration modes
- **Modes**: Handoff (sync), Assign (async), Send Message (direct)

#### 3.1.5 Uzi (Git Worktrees + tmux)
- **Source**: https://www.vibesparking.com/en/blog/ai/claude-code/uzi/
- **Pattern**: Worktree isolation, parallel agents, checkpoint merging
- **Use Case**: 3-5 agents exploring different implementations

### 3.2 Frameworks Evaluated

| Framework | Type | Strengths | Weaknesses |
|-----------|------|-----------|------------|
| LangChain | Python | Ecosystem, tools | Overhead, complexity |
| CrewAI | Python | Role-based agents | Limited customization |
| AutoGen | Python | Multi-agent, Microsoft | Heavy, enterprise-focused |
| Claude Agent SDK | TypeScript | Official, simple | Limited orchestration |
| Semantic Kernel | C#/Python | Enterprise, Microsoft | Overkill for this use case |

### 3.3 Token Optimization Research

| Strategy | Savings | Complexity |
|----------|---------|------------|
| Model routing (Haiku vs Sonnet vs Opus) | 60-80% | Medium |
| Context compression | 20-30% | Low |
| Caching (context7 MCP) | 40-50% | Low |
| Prompt optimization | 15-25% | Medium |
| Batch processing | 30-40% | High |

---

## 4. Proposed Solution

### 4.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     DO ANYTHING AGENT (DAA) v1.0                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      LAYER 1: INTERFACE                              │   │
│  │  CLI Command: /do-anything <goal> [options]                         │   │
│  │  Bash Script: do-anything.sh                                         │   │
│  │  API: Future REST/WebSocket interface                               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    LAYER 2: ORCHESTRATION CORE                       │   │
│  │                                                                      │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │   │
│  │  │   RALPH LOOP    │  │  GOAL DECOMP    │  │  AGENT ROUTER   │     │   │
│  │  │  (Core Engine)  │  │  (Planning)     │  │  (Selection)    │     │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘     │   │
│  │                                                                      │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │   │
│  │  │  MODEL ROUTER   │  │ PARALLEL ENGINE │  │  STATE MANAGER  │     │   │
│  │  │ (Token Optim)   │  │  (tmux/worktree)│  │  (Persistence)  │     │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘     │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    LAYER 3: AGENT POOL (27)                          │   │
│  │                                                                      │   │
│  │  Development (6)    Research (4)     Content (6)     PKM (5)        │   │
│  │  ├─fullstack        ├─competitive    ├─podcast-*     ├─connection   │   │
│  │  ├─frontend         ├─market-res     ├─social-media  ├─moc-agent    │   │
│  │  ├─backend          ├─seo-analyzer   ├─content-cur   ├─metadata     │   │
│  │  ├─code-reviewer    └─sales-auto     └─video-editor  ├─tag-agent    │   │
│  │  ├─task-decomp                                       └─review       │   │
│  │  └─prompt-engineer                                                   │   │
│  │                                                                      │   │
│  │  Utility (6)                                                         │   │
│  │  ├─context-manager  ├─ui-ux          ├─cli-ui        ├─visual-ocr   │   │
│  │  └─timestamp-prec   └─...                                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    LAYER 4: INTEGRATION                              │   │
│  │                                                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │   │
│  │  │   MCPs (14)  │  │  Skills (27) │  │  LLMs (3+)   │              │   │
│  │  │  ├─memory    │  │  ├─docx      │  │  ├─Claude    │              │   │
│  │  │  ├─notion    │  │  ├─pdf       │  │  ├─Gemini    │              │   │
│  │  │  ├─supabase  │  │  ├─pptx      │  │  ├─Codex     │              │   │
│  │  │  ├─github    │  │  ├─xlsx      │  │  └─Local     │              │   │
│  │  │  ├─vercel    │  │  └─...       │  │              │              │   │
│  │  │  └─...       │  │              │  │              │              │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │   │
│  │                                                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │   │
│  │  │  Database    │  │   GitHub     │  │  Monitoring  │              │   │
│  │  │  ├─SQLite    │  │  ├─Issues    │  │  ├─Metrics   │              │   │
│  │  │  ├─Vector    │  │  ├─PRs       │  │  ├─Logs      │              │   │
│  │  │  └─Cache     │  │  └─Actions   │  │  └─Alerts    │              │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Core Components

#### 4.2.1 Ralph Loop Engine

O coração do sistema - um loop infinito que:
1. Recebe um goal
2. Executa Claude com contexto
3. Analisa resultado
4. Se não completo, re-alimenta com feedback
5. Repete até completion ou max iterations

```bash
#!/bin/bash
# Core Ralph Loop - Simplified
while true; do
    result=$(claude --goal "$GOAL" --context "$CONTEXT")
    if echo "$result" | grep -q "DONE"; then
        break
    fi
    CONTEXT="$result"  # Feed back
done
```

#### 4.2.2 Goal Decomposition

Usa o agente `task-decomposition-expert` para:
1. Analisar goal complexo
2. Identificar subgoals independentes
3. Determinar dependências
4. Criar execution plan

#### 4.2.3 Agent Router

Seleciona agentes baseado em:
1. Tipo de tarefa (development, research, content, etc.)
2. Complexidade (Haiku vs Sonnet vs Opus)
3. Disponibilidade (rate limits)
4. Histórico de sucesso

#### 4.2.4 Model Router (Token Optimization)

```
┌─────────────────────────────────────────────────────────────────┐
│                    MODEL ROUTING STRATEGY                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Task Complexity Assessment                                      │
│  ├── Simple (planning, formatting, queries)                     │
│  │   └── Route to: Haiku ($0.25/1M input, $1.25/1M output)     │
│  │                                                               │
│  ├── Medium (coding, analysis, research)                        │
│  │   └── Route to: Sonnet ($3/1M input, $15/1M output)         │
│  │                                                               │
│  └── Complex (architecture, creative, reasoning)                │
│      └── Route to: Opus ($15/1M input, $75/1M output)          │
│                                                                  │
│  Fallback Strategy                                               │
│  ├── If Claude rate limited → Gemini CLI                        │
│  ├── If Gemini rate limited → Codex                             │
│  └── If all limited → Queue + Wait                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### 4.2.5 Parallel Engine

Usa tmux + git worktrees para:
1. Isolar contexto de cada agente
2. Executar em paralelo
3. Agregar resultados
4. Resolver conflitos

#### 4.2.6 State Manager

Persiste estado em:
1. **Memory MCP**: Contexto de curto prazo
2. **SQLite**: Estado estruturado (executions, metrics)
3. **Vector Store**: Embeddings para semantic search
4. **GitHub**: Código e artifacts

---

## 5. Technical Architecture

### 5.1 File Structure

```
.claude/
├── commands/
│   └── do-anything.md              # Main command definition
├── agents/
│   ├── do-anything-agent.md        # Core DAA agent spec
│   └── ... (27 specialized agents)
├── skills/
│   └── ... (27 skills)
├── mcp.json                        # MCP configuration
└── settings.json

Automation/
├── scripts/
│   ├── do-anything.sh              # Main bash wrapper
│   ├── ralph-loop.sh               # Core loop implementation
│   ├── parallel-engine.sh          # tmux orchestration
│   ├── model-router.sh             # LLM selection logic
│   └── state-manager.sh            # Persistence layer
├── lib/
│   ├── agent-router.js             # Agent selection logic
│   ├── goal-decomposer.js          # Goal analysis
│   └── token-optimizer.js          # Token counting/routing
└── db/
    ├── schema.sql                  # SQLite schema
    └── migrations/

Config/
├── Commands/
│   └── agents/
│       └── do-anything.md          # Slash command
└── Guides/
    └── DO-ANYTHING-AGENT-SPECIFICATION.md  # This document
```

### 5.2 Data Flow

```
User Goal
    │
    ▼
┌─────────────────┐
│  /do-anything   │  CLI Entry Point
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  do-anything.sh │  Bash Wrapper
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Goal Decomp    │────▶│  State Init     │
│  (Claude)       │     │  (SQLite)       │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│  Ralph Loop     │◀─────────────────────┐
│  (Core Engine)  │                      │
└────────┬────────┘                      │
         │                               │
         ▼                               │
┌─────────────────┐     ┌────────────────┴┐
│  Agent Router   │────▶│  Model Router   │
│  (Selection)    │     │  (Haiku/Sonnet) │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│  Execute Agent  │
│  (Task tool)    │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌───────┐ ┌───────┐
│  MCP  │ │ Skill │
│ Tools │ │ Tools │
└───┬───┘ └───┬───┘
    │         │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│  Result Check   │
│  (Completion?)  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
  DONE    Continue
    │         │
    ▼         │
┌─────────┐   │
│ Summary │   │
│ + Exit  │   │
└─────────┘   │
              │
              ▼
         ┌────────┐
         │ Update │
         │ Context│
         └────┬───┘
              │
              └──────────▶ (Back to Ralph Loop)
```

### 5.3 Multi-LLM Integration

```
┌─────────────────────────────────────────────────────────────────┐
│                    MULTI-LLM ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Primary: Claude (Anthropic)                                     │
│  ├── Haiku: Quick tasks, validation, formatting                 │
│  ├── Sonnet: Main workload, coding, analysis                    │
│  └── Opus: Complex reasoning, architecture, creative            │
│                                                                  │
│  Secondary: Gemini (Google)                                      │
│  ├── gemini-2.0-flash: Fast, multimodal                         │
│  ├── gemini-2.0-pro: Complex tasks                              │
│  └── Use case: Rate limit fallback, multimodal tasks            │
│                                                                  │
│  Tertiary: Codex/GPT (OpenAI)                                   │
│  ├── gpt-4o: General purpose                                    │
│  ├── o1: Deep reasoning                                         │
│  └── Use case: Second opinion, specialized coding               │
│                                                                  │
│  Local: Ollama (Self-hosted)                                    │
│  ├── llama3.2: Quick local inference                            │
│  ├── codellama: Code-specific tasks                             │
│  └── Use case: Offline, privacy-sensitive, cost reduction       │
│                                                                  │
│  Router Logic:                                                   │
│  1. Estimate task complexity                                     │
│  2. Check rate limits for each provider                          │
│  3. Select optimal model based on cost/capability                │
│  4. Execute with fallback chain                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.4 Database Schema

```sql
-- Supabase/PostgreSQL Schema for DAA State Management
-- Full schema with pgvector: sql/schema.sql

-- Executions table
CREATE TABLE executions (
    id TEXT PRIMARY KEY,
    goal TEXT NOT NULL,
    status TEXT CHECK(status IN ('running', 'completed', 'failed', 'cancelled')),
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    total_iterations INTEGER DEFAULT 0,
    total_tokens_used INTEGER DEFAULT 0,
    total_cost_usd REAL DEFAULT 0,
    metadata JSON
);

-- Subgoals table
CREATE TABLE subgoals (
    id TEXT PRIMARY KEY,
    execution_id TEXT REFERENCES executions(id),
    parent_id TEXT REFERENCES subgoals(id),
    description TEXT NOT NULL,
    status TEXT CHECK(status IN ('pending', 'in_progress', 'completed', 'failed')),
    assigned_agent TEXT,
    assigned_model TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    result JSON
);

-- Agent executions table
CREATE TABLE agent_runs (
    id TEXT PRIMARY KEY,
    execution_id TEXT REFERENCES executions(id),
    subgoal_id TEXT REFERENCES subgoals(id),
    agent_type TEXT NOT NULL,
    model_used TEXT NOT NULL,
    input_tokens INTEGER,
    output_tokens INTEGER,
    duration_ms INTEGER,
    status TEXT CHECK(status IN ('success', 'failed', 'timeout')),
    error_message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Context/Memory table
CREATE TABLE context_store (
    key TEXT PRIMARY KEY,
    value JSON NOT NULL,
    execution_id TEXT REFERENCES executions(id),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME
);

-- Metrics table
CREATE TABLE metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_name TEXT NOT NULL,
    metric_value REAL NOT NULL,
    labels JSON,
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_executions_status ON executions(status);
CREATE INDEX idx_subgoals_execution ON subgoals(execution_id);
CREATE INDEX idx_agent_runs_execution ON agent_runs(execution_id);
CREATE INDEX idx_metrics_name ON metrics(metric_name);
```

---

## 6. Implementation Roadmap

### Phase 1: Foundation (Core Ralph Loop)

**Duration**: 1-2 sessions
**Priority**: P0

| Task | Description | Deliverable |
|------|-------------|-------------|
| 1.1 | Create `/do-anything` command | `.claude/commands/do-anything.md` |
| 1.2 | Implement Ralph Loop in bash | `Automation/scripts/ralph-loop.sh` |
| 1.3 | Implement completion detection | Pattern matching for "DONE" |
| 1.4 | Basic state file management | JSON state file |
| 1.5 | Integration tests | Test with simple goal |

**Exit Criteria**: Successfully complete a simple goal with 3+ iterations

### Phase 2: Agent Integration

**Duration**: 1-2 sessions
**Priority**: P0

| Task | Description | Deliverable |
|------|-------------|-------------|
| 2.1 | Create DAA agent definition | `.claude/agents/do-anything-agent.md` |
| 2.2 | Implement agent selection logic | `agent-router.js` |
| 2.3 | Integrate with Task tool | Subagent invocation |
| 2.4 | Goal decomposition via agent | Use task-decomposition-expert |
| 2.5 | Multi-agent workflow test | Test with 3+ agents |

**Exit Criteria**: Successfully orchestrate 3+ agents for a complex goal

### Phase 3: MCP & Persistence

**Duration**: 1-2 sessions
**Priority**: P1

| Task | Description | Deliverable |
|------|-------------|-------------|
| 3.1 | Integrate Memory MCP | Context persistence |
| 3.2 | Set up SQLite database | Schema + migrations |
| 3.3 | Implement state manager | `state-manager.sh` |
| 3.4 | Integrate Notion MCP | Documentation output |
| 3.5 | Integrate GitHub MCP | Code operations |

**Exit Criteria**: State persists across sessions, MCPs working

### Phase 4: Token Optimization & Multi-LLM

**Duration**: 2-3 sessions
**Priority**: P1

| Task | Description | Deliverable |
|------|-------------|-------------|
| 4.1 | Implement model router | `model-router.sh` |
| 4.2 | Token counting/estimation | Token optimizer |
| 4.3 | Haiku/Sonnet/Opus routing | Complexity-based selection |
| 4.4 | Gemini CLI integration | Fallback provider |
| 4.5 | Cost tracking | Metrics collection |

**Exit Criteria**: 40%+ token cost reduction demonstrated

### Phase 5: Parallel Execution

**Duration**: 2-3 sessions
**Priority**: P1

| Task | Description | Deliverable |
|------|-------------|-------------|
| 5.1 | tmux session manager | `parallel-engine.sh` |
| 5.2 | Git worktree isolation | Branch per agent |
| 5.3 | Output aggregation | Result merging |
| 5.4 | Conflict resolution | Merge strategy |
| 5.5 | Parallel workflow test | 3+ agents in parallel |

**Exit Criteria**: 2x speed improvement for parallelizable tasks

### Phase 6: Safety & Monitoring

**Duration**: 1-2 sessions
**Priority**: P0

| Task | Description | Deliverable |
|------|-------------|-------------|
| 6.1 | Circuit breaker | Max iterations, error rate |
| 6.2 | Rate limiting | Per-provider limits |
| 6.3 | Logging system | Structured logs |
| 6.4 | Metrics dashboard | Basic monitoring |
| 6.5 | Alert system | Failure notifications |

**Exit Criteria**: No runaway loops, proper error handling

### Phase 7: Documentation & Polish

**Duration**: 1 session
**Priority**: P1

| Task | Description | Deliverable |
|------|-------------|-------------|
| 7.1 | User documentation | README, examples |
| 7.2 | API documentation | Command reference |
| 7.3 | Architecture docs | This document updated |
| 7.4 | Video walkthrough | Optional |
| 7.5 | GitHub release | v1.0.0 tag |

**Exit Criteria**: Complete documentation, ready for external use

---

## 7. Resource Requirements

### 7.1 Development Resources

| Resource | Requirement | Notes |
|----------|-------------|-------|
| Claude Code CLI | Latest version | Primary interface |
| tmux | Installed | Parallel execution |
| SQLite | v3.x | State management |
| Node.js | v18+ | Utility scripts |
| jq | Installed | JSON processing |
| Git | Latest | Version control |

### 7.2 API Access

| Provider | API Key Required | Rate Limits |
|----------|------------------|-------------|
| Anthropic | Yes | Tier-dependent |
| Google (Gemini) | Yes | 60 RPM free |
| OpenAI | Optional | Tier-dependent |
| Ollama | No (local) | Unlimited |

### 7.3 Cost Estimation

| Model | Est. Monthly Usage | Est. Cost |
|-------|-------------------|-----------|
| Claude Haiku | 5M tokens | $1.25 |
| Claude Sonnet | 2M tokens | $9.00 |
| Claude Opus | 500K tokens | $11.25 |
| Gemini Flash | 1M tokens | Free tier |
| **Total** | | **~$22/month** |

---

## 8. Risk Analysis

### 8.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Infinite loops | Medium | High | Circuit breaker, max iterations |
| Token exhaustion | Medium | Medium | Model routing, rate limiting |
| Context overflow | Low | Medium | Context compression |
| Agent conflicts | Low | Medium | Isolation via worktrees |
| API downtime | Low | High | Multi-provider fallback |

### 8.2 Operational Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Cost overrun | Medium | Medium | Budget alerts, limits |
| Security issues | Low | High | Sandbox mode, review |
| Data loss | Low | High | State persistence |
| Scope creep | High | Medium | Strict non-goals |

---

## 9. Success Metrics

### 9.1 Quantitative Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Goal completion rate | >95% | Completed/Attempted |
| Average iterations to complete | <5 | Mean iterations |
| Token cost per goal | <$0.50 avg | Total cost/goals |
| Parallel speedup | >2x | Parallel/Sequential time |
| Error rate | <5% | Errors/Executions |

### 9.2 Qualitative Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| User satisfaction | High | Self-assessment |
| Code quality | Maintained | Linting, reviews |
| Documentation quality | Complete | Coverage check |

---

## 10. Appendices

### Appendix A: Glossary

| Term | Definition |
|------|------------|
| DAA | Do Anything Agent |
| Ralph Loop | Autonomous iteration pattern by Geoffrey Huntley |
| MCP | Model Context Protocol |
| Subagent | Specialized agent invoked by main agent |
| Worktree | Git feature for multiple working directories |

### Appendix B: References

1. [Ralph Wiggum Autonomous Loops](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/)
2. [Claude Code Agent Loop](https://blog.promptlayer.com/claude-code-behind-the-scenes-of-the-master-agent-loop/)
3. [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents)
4. [AWS CLI Agent Orchestrator](https://github.com/awslabs/cli-agent-orchestrator)
5. [claude-flow](https://github.com/ruvnet/claude-flow)
6. [Anthropic Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)
7. [Uzi Parallel AI Coders](https://www.vibesparking.com/en/blog/ai/claude-code/uzi/)

### Appendix C: Related Documents

- `CLAUDE.md` - Project context
- `Automation/agents/AGENTS-CATALOG.md` - Agent documentation
- `Automation/mcps/MCP-CATALOG.md` - MCP documentation
- `README.md` - Repository overview

---

**Document Status**: IN PROGRESS
**Current Phase**: Phase 1 - Foundation (Structure Created)
**Last Updated**: 2026-01-11

### Completed
- [x] Project structure created
- [x] Configuration files (settings.json, ollama.json, notifications.json)
- [x] SQL schema for Supabase (schema.sql)
- [x] n8n workflows (daa-monitor.json, daa-notify.json)
- [x] Main script (do-anything.sh)

### Next Steps
1. [ ] Execute SQL schema in Supabase
2. [ ] Import workflows in n8n (https://n8n.intentum.pro)
3. [ ] Configure Slack credentials in n8n
4. [ ] Configure Telegram bot
5. [ ] Test do-anything.sh script
6. [ ] Begin Phase 2: Agent Integration

---

*Architecture research complete. Implementation in progress.*
