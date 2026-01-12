#!/bin/bash
# ==============================================================================
# LIMITLESS AGENT - Installation Script
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "  ██╗     ██╗███╗   ███╗██╗████████╗██╗     ███████╗███████╗███████╗"
echo "  ██║     ██║████╗ ████║██║╚══██╔══╝██║     ██╔════╝██╔════╝██╔════╝"
echo "  ██║     ██║██╔████╔██║██║   ██║   ██║     █████╗  ███████╗███████╗"
echo "  ██║     ██║██║╚██╔╝██║██║   ██║   ██║     ██╔══╝  ╚════██║╚════██║"
echo "  ███████╗██║██║ ╚═╝ ██║██║   ██║   ███████╗███████╗███████║███████║"
echo "  ╚══════╝╚═╝╚═╝     ╚═╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚══════╝"
echo -e "${NC}"
echo ""
echo -e "${BLUE}Installing Limitless Agent...${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIMITLESS_HOME="$(dirname "$SCRIPT_DIR")"

# Step 1: Check dependencies
echo -e "${BLUE}[1/5]${NC} Checking dependencies..."

# Check Claude CLI
if command -v claude &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Claude CLI found"
else
    echo -e "  ${RED}✗${NC} Claude CLI not found"
    echo -e "    Install: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Check curl
if command -v curl &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} curl found"
else
    echo -e "  ${RED}✗${NC} curl not found"
    exit 1
fi

# Check jq (optional)
if command -v jq &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} jq found"
else
    echo -e "  ${YELLOW}!${NC} jq not found (optional, for pretty JSON output)"
fi

# Step 2: Create directories
echo -e "${BLUE}[2/5]${NC} Creating directories..."

mkdir -p "${LIMITLESS_HOME}/logs"
mkdir -p "${LIMITLESS_HOME}/src/core"
mkdir -p "${LIMITLESS_HOME}/src/routing"
mkdir -p "${LIMITLESS_HOME}/src/integrations"
mkdir -p "${LIMITLESS_HOME}/src/utils"
mkdir -p "${LIMITLESS_HOME}/tests/unit"
mkdir -p "${LIMITLESS_HOME}/tests/integration"
mkdir -p "${LIMITLESS_HOME}/tests/e2e"
mkdir -p "${LIMITLESS_HOME}/sql/migrations"
mkdir -p "${LIMITLESS_HOME}/sql/seeds"

echo -e "  ${GREEN}✓${NC} Directories created"

# Step 3: Make scripts executable
echo -e "${BLUE}[3/5]${NC} Setting permissions..."

chmod +x "${LIMITLESS_HOME}/scripts/limitless.sh"
chmod +x "${LIMITLESS_HOME}/scripts/install.sh"
chmod +x "${LIMITLESS_HOME}/scripts/health-check.sh" 2>/dev/null || true

echo -e "  ${GREEN}✓${NC} Scripts are executable"

# Step 4: Create example config if not exists
echo -e "${BLUE}[4/5]${NC} Checking configuration..."

if [ -f "${LIMITLESS_HOME}/config/settings.json" ]; then
    echo -e "  ${GREEN}✓${NC} Configuration file exists"
else
    echo -e "  ${YELLOW}!${NC} Creating default configuration..."
    # Config should already exist from repo
fi

# Step 5: Verify installation
echo -e "${BLUE}[5/5]${NC} Verifying installation..."

if "${LIMITLESS_HOME}/scripts/limitless.sh" status > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Installation verified"
else
    echo -e "  ${YELLOW}!${NC} Some components may not be available"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Execute SQL schema in Supabase:"
echo "     psql \$DATABASE_URL -f sql/schema.sql"
echo ""
echo "  2. Import n8n workflows:"
echo "     Upload n8n/workflows/*.json to your n8n instance"
echo ""
echo "  3. Configure credentials in n8n:"
echo "     - Slack: Add bot to #limitless-notifications"
echo "     - Telegram: Create bot via @BotFather"
echo ""
echo "  4. Run your first goal:"
echo "     ./scripts/limitless.sh run \"Your goal here\""
echo ""
echo -e "${PURPLE}\"What if you could access 100% of your brain?\"${NC}"
