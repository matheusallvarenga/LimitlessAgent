#!/bin/bash
# ==============================================================================
# LIMITLESS AGENT - Health Check Script
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIMITLESS_HOME="${LIMITLESS_HOME:-$(dirname "$SCRIPT_DIR")}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

N8N_WEBHOOK_BASE="${N8N_WEBHOOK_BASE:-https://n8n.intentum.pro/webhook}"
OLLAMA_ENDPOINT="${OLLAMA_ENDPOINT:-https://ollama.intentum.ai}"

echo -e "${BLUE}Limitless Agent - Health Check${NC}"
echo "=============================="
echo ""

ERRORS=0
WARNINGS=0

# Check Claude CLI
echo -n "Claude CLI: "
if command -v claude &> /dev/null; then
    VERSION=$(claude --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}OK${NC} ($VERSION)"
else
    echo -e "${RED}NOT FOUND${NC}"
    ((ERRORS++))
fi

# Check Ollama
echo -n "Ollama: "
if curl -s --connect-timeout 5 "${OLLAMA_ENDPOINT}/api/tags" > /dev/null 2>&1; then
    MODELS=$(curl -s "${OLLAMA_ENDPOINT}/api/tags" | jq -r '.models | length' 2>/dev/null || echo "?")
    echo -e "${GREEN}OK${NC} (${MODELS} models)"
else
    echo -e "${YELLOW}NOT REACHABLE${NC}"
    ((WARNINGS++))
fi

# Check n8n Monitor
echo -n "n8n Monitor: "
RESPONSE=$(curl -s --connect-timeout 5 -X POST "${N8N_WEBHOOK_BASE}/limitless-monitor" \
    -H "Content-Type: application/json" \
    -d '{"action":"health_check"}' 2>/dev/null)
if [ -n "$RESPONSE" ] && echo "$RESPONSE" | jq -e '.status' > /dev/null 2>&1; then
    STATUS=$(echo "$RESPONSE" | jq -r '.status')
    echo -e "${GREEN}OK${NC} (status: $STATUS)"
else
    echo -e "${YELLOW}NOT REACHABLE${NC}"
    ((WARNINGS++))
fi

# Check n8n Notify
echo -n "n8n Notify: "
if curl -s --connect-timeout 5 -X POST "${N8N_WEBHOOK_BASE}/limitless-notify" \
    -H "Content-Type: application/json" \
    -d '{"event":"health_check"}' > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}NOT REACHABLE${NC}"
    ((WARNINGS++))
fi

# Check n8n Trigger
echo -n "n8n Trigger: "
if curl -s --connect-timeout 5 "${N8N_WEBHOOK_BASE}/limitless-trigger" > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}NOT REACHABLE${NC}"
    ((WARNINGS++))
fi

# Check configuration files
echo -n "Config: "
if [ -f "${LIMITLESS_HOME}/config/settings.json" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}MISSING${NC}"
    ((ERRORS++))
fi

# Check logs directory
echo -n "Logs: "
if [ -d "${LIMITLESS_HOME}/logs" ] && [ -w "${LIMITLESS_HOME}/logs" ]; then
    echo -e "${GREEN}OK${NC} (writable)"
else
    echo -e "${YELLOW}NOT WRITABLE${NC}"
    ((WARNINGS++))
fi

# Summary
echo ""
echo "=============================="
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Health Check: FAILED${NC}"
    echo "Errors: $ERRORS, Warnings: $WARNINGS"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Health Check: DEGRADED${NC}"
    echo "Warnings: $WARNINGS"
    exit 0
else
    echo -e "${GREEN}Health Check: PASSED${NC}"
    exit 0
fi
