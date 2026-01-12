# Limitless Agent - Quick Start Guide

Get up and running with Limitless Agent in under 10 minutes.

---

## Prerequisites

Before starting, ensure you have:

- [ ] **Claude Code CLI** installed and authenticated
- [ ] **Supabase** account (free tier works)
- [ ] **n8n** instance (self-hosted or cloud)
- [ ] **Ollama** running locally or remotely (optional but recommended)

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/matheusallvarenga/limitless-agent.git
cd limitless-agent
```

---

## Step 2: Run Installation Script

```bash
./scripts/install.sh
```

The script will:
1. Check dependencies
2. Create necessary directories
3. Set up configuration files
4. Make scripts executable

### Manual Installation (Alternative)

If you prefer manual setup:

```bash
# Create directories
mkdir -p logs

# Copy configuration template
cp config/settings.example.json config/settings.json

# Make scripts executable
chmod +x scripts/*.sh
```

---

## Step 3: Configure Supabase

### 3.1 Create a Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note your:
   - Project URL
   - API Key (anon/public)
   - Database connection string

### 3.2 Execute Schema

In Supabase SQL Editor, run:

```sql
-- Copy contents of sql/schema.sql and execute
```

Or via command line:

```bash
psql $DATABASE_URL -f sql/schema.sql
```

---

## Step 4: Configure n8n Workflows

### 4.1 Import Workflows

1. Go to your n8n instance
2. Create new workflows by importing:
   - `n8n/workflows/limitless-monitor.json`
   - `n8n/workflows/limitless-notify.json`
   - `n8n/workflows/limitless-trigger.json`

### 4.2 Configure Credentials

In n8n, set up:

- **Slack**: Create app and add to #limitless-notifications channel
- **Telegram**: Create bot via @BotFather and get token

### 4.3 Activate Workflows

Enable all three workflows in n8n.

---

## Step 5: Configure Settings

Edit `config/settings.json`:

```json
{
  "database": {
    "supabase_url": "https://YOUR-PROJECT.supabase.co",
    "supabase_key": "YOUR-ANON-KEY"
  },
  "notifications": {
    "n8n_webhook_base": "https://your-n8n.com/webhook"
  },
  "ollama": {
    "endpoint": "http://localhost:11434"
  }
}
```

---

## Step 6: Test Installation

### Health Check

```bash
./scripts/limitless.sh health
```

Expected output:
```
[INFO] Checking Limitless Agent status...
[SUCCESS] Claude CLI: Available
[SUCCESS] Ollama: Connected
[SUCCESS] n8n: Connected
[INFO] Limitless Home: /path/to/limitless-agent
```

### Run a Simple Goal

```bash
./scripts/limitless.sh run "List all files in the current directory"
```

---

## Step 7: Your First Real Goal

Try something more complex:

```bash
./scripts/limitless.sh run "Create a simple Python script that fetches weather data"
```

Watch as Limitless Agent:
1. Decomposes the goal
2. Selects appropriate agents
3. Routes to optimal LLM
4. Iterates until complete
5. Notifies you via Slack/Telegram

---

## Configuration Options

### Environment Variables

```bash
# Optional: Override config file settings
export LIMITLESS_HOME=/path/to/limitless-agent
export N8N_WEBHOOK_BASE=https://n8n.example.com/webhook
export OLLAMA_ENDPOINT=https://ollama.example.com
```

### Command Line Options

```bash
# Set max iterations
./scripts/limitless.sh run "goal" --max-iterations 50

# Verbose output
./scripts/limitless.sh run "goal" --verbose

# Dry run (show plan without executing)
./scripts/limitless.sh run "goal" --dry-run
```

---

## Troubleshooting

### Claude CLI Not Found

```bash
# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Or check PATH
which claude
```

### Ollama Connection Failed

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Start Ollama
ollama serve
```

### n8n Webhook Not Responding

1. Check workflow is active in n8n
2. Verify webhook URL is correct
3. Test manually:
```bash
curl -X POST https://your-n8n.com/webhook/limitless-monitor \
  -H "Content-Type: application/json" \
  -d '{"action": "health_check"}'
```

### Supabase Connection Failed

1. Verify URL and API key in settings.json
2. Check if schema was executed
3. Test connection:
```bash
curl https://YOUR-PROJECT.supabase.co/rest/v1/limitless_executions \
  -H "apikey: YOUR-ANON-KEY"
```

---

## Next Steps

- Read [SPECIFICATION.md](SPECIFICATION.md) for full technical details
- Explore [examples/](examples/) for more usage patterns
- Check [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- Join the community (coming soon)

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `./scripts/limitless.sh run "goal"` | Execute a goal |
| `./scripts/limitless.sh status` | Check component status |
| `./scripts/limitless.sh health` | Run health check |
| `./scripts/limitless.sh help` | Show help |

---

**Need help?** Open an issue on GitHub or check the documentation.
