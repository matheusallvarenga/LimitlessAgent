# Limitless Agent - API Reference

Complete API documentation for Limitless Agent webhooks and database schemas.

---

## n8n Webhook Endpoints

### Base URL

```
https://n8n.intentum.pro/webhook
```

---

## limitless-trigger

Trigger new Limitless Agent executions.

### Endpoint

```
POST /webhook/limitless-trigger
```

### Request Body

```json
{
  "goal": "Create a REST API with authentication",
  "options": {
    "max_iterations": 100,
    "notify": true,
    "priority": "normal"
  },
  "metadata": {
    "source": "webhook",
    "user": "api-user"
  }
}
```

### Parameters

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `goal` | string | Yes | - | The goal to achieve |
| `options.max_iterations` | integer | No | 100 | Maximum iterations |
| `options.notify` | boolean | No | true | Send notifications |
| `options.priority` | string | No | "normal" | Priority: low, normal, high |
| `metadata` | object | No | {} | Additional metadata |

### Response

```json
{
  "success": true,
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "started",
  "timestamp": "2026-01-11T20:00:00Z"
}
```

### Error Response

```json
{
  "success": false,
  "error": "Goal is required",
  "code": "VALIDATION_ERROR"
}
```

---

## limitless-monitor

Query execution status and system health.

### Endpoint

```
POST /webhook/limitless-monitor
```

### Actions

#### health_check

```json
{
  "action": "health_check"
}
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2026-01-11T20:00:00Z",
  "limitless_version": "1.0.0",
  "n8n_status": "connected",
  "components": {
    "claude": "available",
    "ollama": "available",
    "supabase": "connected"
  }
}
```

#### get_active_workflows

```json
{
  "action": "get_active_workflows"
}
```

Response:
```json
{
  "workflows": [
    {
      "id": "1",
      "name": "limitless-monitor",
      "active": true
    }
  ],
  "count": 3
}
```

#### get_workflow_executions

```json
{
  "action": "get_workflow_executions",
  "status": "all",
  "limit": 25
}
```

Response:
```json
{
  "health_status": "green",
  "total_executions": 150,
  "successful": 142,
  "failed": 8,
  "running": 0,
  "success_rate": 94.67,
  "avg_duration_ms": 45000,
  "timestamp": "2026-01-11T20:00:00Z"
}
```

#### get_execution_details

```json
{
  "action": "get_execution_details",
  "execution_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

Response:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "goal": "Create REST API",
  "status": "completed",
  "started_at": "2026-01-11T19:00:00Z",
  "completed_at": "2026-01-11T19:05:00Z",
  "duration_ms": 300000,
  "iteration_count": 3,
  "tasks": [
    {
      "name": "Setup project",
      "status": "completed",
      "agent": "backend-architect"
    }
  ]
}
```

---

## limitless-notify

Receive execution notifications.

### Endpoint

```
POST /webhook/limitless-notify
```

### Events

#### task_started

```json
{
  "event": "task_started",
  "goal": "Create REST API",
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-01-11T20:00:00Z"
}
```

#### task_completed

```json
{
  "event": "task_completed",
  "goal": "Create REST API",
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "duration": "3 iterations",
  "iterations": 3,
  "timestamp": "2026-01-11T20:05:00Z"
}
```

#### task_failed

```json
{
  "event": "task_failed",
  "goal": "Create REST API",
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "error": "Max iterations reached",
  "iteration": 100,
  "max_iterations": 100,
  "timestamp": "2026-01-11T20:10:00Z"
}
```

#### approval_required

```json
{
  "event": "approval_required",
  "action": "Delete production database",
  "risk_level": "HIGH",
  "timeout": 30,
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-01-11T20:00:00Z"
}
```

### Response

```json
{
  "success": true,
  "event": "task_started",
  "timestamp": "2026-01-11T20:00:00Z"
}
```

---

## Database Schema

### Tables

#### limitless_executions

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `goal` | TEXT | The goal to achieve |
| `status` | VARCHAR(20) | pending, running, completed, failed, cancelled |
| `started_at` | TIMESTAMP | Start time |
| `completed_at` | TIMESTAMP | Completion time |
| `duration_ms` | INTEGER | Duration in milliseconds |
| `iteration_count` | INTEGER | Number of iterations |
| `max_iterations` | INTEGER | Maximum allowed iterations |
| `result` | JSONB | Final result |
| `error` | TEXT | Error message if failed |
| `metadata` | JSONB | Additional metadata |

#### limitless_tasks

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `execution_id` | UUID | Foreign key to executions |
| `name` | VARCHAR(255) | Task name |
| `description` | TEXT | Task description |
| `status` | VARCHAR(20) | Task status |
| `agent_name` | VARCHAR(100) | Assigned agent |
| `model_used` | VARCHAR(100) | LLM model used |
| `input` | JSONB | Task input |
| `output` | JSONB | Task output |
| `tokens_input` | INTEGER | Input tokens used |
| `tokens_output` | INTEGER | Output tokens used |
| `cost_usd` | DECIMAL | Cost in USD |
| `duration_ms` | INTEGER | Duration in milliseconds |

#### limitless_memory

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `key` | VARCHAR(255) | Unique key |
| `value` | JSONB | Stored value |
| `memory_type` | VARCHAR(50) | Type: general, session, preference |
| `importance` | DECIMAL | 0.0 to 1.0 |
| `access_count` | INTEGER | Times accessed |
| `expires_at` | TIMESTAMP | Expiration time |

#### limitless_documents

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGSERIAL | Primary key |
| `content` | TEXT | Document content |
| `metadata` | JSONB | Document metadata |
| `embedding` | VECTOR(768) | Vector embedding |
| `doc_type` | VARCHAR(100) | Document type |
| `source` | VARCHAR(255) | Source reference |

### Functions

#### match_documents

Search for similar documents using vector similarity.

```sql
SELECT * FROM match_documents(
  query_embedding := '[0.1, 0.2, ...]'::vector,
  match_count := 5,
  filter := '{"doc_type": "code"}'::jsonb
);
```

### Views

#### limitless_execution_summary

Aggregated execution statistics.

```sql
SELECT * FROM limitless_execution_summary;
```

#### limitless_agent_performance

Per-agent performance metrics.

```sql
SELECT * FROM limitless_agent_performance;
```

#### limitless_daily_metrics

Daily aggregated metrics.

```sql
SELECT * FROM limitless_daily_metrics;
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request parameters |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Internal server error |
| `TIMEOUT` | 504 | Request timeout |

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| limitless-trigger | 10 requests/minute |
| limitless-monitor | 60 requests/minute |
| limitless-notify | 100 requests/minute |

---

## Authentication

Currently, n8n webhooks are public. For production, configure:

1. **API Key Header**: Add `X-API-Key` header validation in n8n
2. **IP Whitelist**: Restrict to known IPs
3. **JWT**: Implement JWT validation

Example with API key:

```bash
curl -X POST https://n8n.example.com/webhook/limitless-trigger \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-secret-key" \
  -d '{"goal": "..."}'
```

---

## SDKs (Coming Soon)

- **Python**: `pip install limitless-agent`
- **Node.js**: `npm install limitless-agent`
- **CLI**: Built-in with `limitless.sh`
