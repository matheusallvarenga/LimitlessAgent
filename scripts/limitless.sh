#!/bin/bash
# ==============================================================================
# LIMITLESS AGENT - Main Entry Point
# "What if you could access 100% of your brain?"
#
# Inspired by the film Limitless (2011) and the NZT-48 pill
# Version: 1.0.0
# ==============================================================================

set -e

# Configuration
LIMITLESS_HOME="${LIMITLESS_HOME:-$(dirname "$(dirname "$(realpath "$0")")")}"
LIMITLESS_CONFIG="${LIMITLESS_HOME}/config/settings.json"
LIMITLESS_LOG_DIR="${LIMITLESS_HOME}/logs"
N8N_WEBHOOK_BASE="${N8N_WEBHOOK_BASE:-https://n8n.intentum.pro/webhook}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==============================================================================
# BANNER
# ==============================================================================

show_banner() {
    echo -e "${PURPLE}"
    echo "  ██╗     ██╗███╗   ███╗██╗████████╗██╗     ███████╗███████╗███████╗"
    echo "  ██║     ██║████╗ ████║██║╚══██╔══╝██║     ██╔════╝██╔════╝██╔════╝"
    echo "  ██║     ██║██╔████╔██║██║   ██║   ██║     █████╗  ███████╗███████╗"
    echo "  ██║     ██║██║╚██╔╝██║██║   ██║   ██║     ██╔══╝  ╚════██║╚════██║"
    echo "  ███████╗██║██║ ╚═╝ ██║██║   ██║   ███████╗███████╗███████║███████║"
    echo "  ╚══════╝╚═╝╚═╝     ╚═╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚══════╝"
    echo -e "${NC}"
    echo -e "${CYAN}  \"I see everything. I understand everything.\"${NC}"
    echo ""
}

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_nzt() {
    echo -e "${PURPLE}[NZT]${NC} $1"
}

generate_execution_id() {
    uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s%N
}

notify() {
    local event="$1"
    local payload="$2"

    # Send to n8n webhook (non-blocking)
    curl -s -X POST "${N8N_WEBHOOK_BASE}/limitless-notify" \
        -H "Content-Type: application/json" \
        -d "$payload" > /dev/null 2>&1 &
}

check_ollama() {
    local endpoint="${OLLAMA_ENDPOINT:-https://ollama.intentum.ai}"

    if curl -s --connect-timeout 5 "${endpoint}/api/tags" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_claude() {
    if command -v claude &> /dev/null; then
        return 0
    else
        return 1
    fi
}

check_n8n() {
    if curl -s --connect-timeout 5 "${N8N_WEBHOOK_BASE}/limitless-monitor" -X POST -d '{"action":"health_check"}' > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# NZT PROTOCOL (RALPH LOOP CORE)
# ==============================================================================

nzt_protocol() {
    local goal="$1"
    local max_iterations="${2:-100}"
    local execution_id=$(generate_execution_id)
    local iteration=0
    local goal_complete=false

    log_nzt "Initiating NZT Protocol..."
    log_info "Execution ID: ${execution_id}"
    log_info "Goal: ${goal}"
    log_info "Max Iterations: ${max_iterations}"
    echo ""

    # Notify task started
    notify "task_started" "{\"event\":\"task_started\",\"goal\":\"${goal}\",\"execution_id\":\"${execution_id}\"}"

    # Create log directory if needed
    mkdir -p "${LIMITLESS_LOG_DIR}"
    local log_file="${LIMITLESS_LOG_DIR}/${execution_id}.log"

    # NZT Protocol: Navigate -> Zero-in -> Transform
    while [ "$goal_complete" = false ] && [ $iteration -lt $max_iterations ]; do
        iteration=$((iteration + 1))
        log_info "Iteration ${iteration}/${max_iterations}"

        # Execute Claude Code with the goal
        local result
        result=$(claude --print "
You are the Limitless Agent - an autonomous AI system that can accomplish any goal.

Like NZT-48, you have access to 100% of your capabilities:
- 27 specialized agents via Task tool
- 27 skills
- 14 MCPs

CURRENT GOAL: ${goal}

ITERATION: ${iteration}/${max_iterations}

EXECUTION ID: ${execution_id}

NZT PROTOCOL:
1. N - NAVIGATE: Analyze the goal and decompose into subtasks
2. Z - ZERO-IN: Select optimal agents and models for each subtask
3. T - TRANSFORM: Execute, iterate, and transform the goal into reality

INSTRUCTIONS:
- Analyze current progress
- Decompose into subtasks if needed
- Select appropriate agents
- Execute and track progress
- If the goal is COMPLETE, respond with exactly: GOAL_COMPLETE
- If more work is needed, continue executing

\"I wasn't high. I wasn't wired. Just clear. I knew what I needed to do and how to do it.\"

RESPOND with your actions and status.
" 2>&1) || true

        # Log the result
        echo "[Iteration ${iteration}] $(date -Iseconds)" >> "${log_file}"
        echo "${result}" >> "${log_file}"
        echo "---" >> "${log_file}"

        # Check if goal is complete
        if echo "$result" | grep -q "GOAL_COMPLETE"; then
            goal_complete=true
            log_success "Goal completed at iteration ${iteration}"
        fi

        # Small delay to prevent rate limiting
        sleep 2
    done

    # Calculate duration
    local duration="${iteration} iterations"

    # Notify completion or failure
    if [ "$goal_complete" = true ]; then
        notify "task_completed" "{\"event\":\"task_completed\",\"goal\":\"${goal}\",\"execution_id\":\"${execution_id}\",\"duration\":\"${duration}\",\"iterations\":${iteration}}"
        echo ""
        log_success "Limitless execution completed successfully"
        log_nzt "\"I see everything. I understand everything.\""
        return 0
    else
        notify "task_failed" "{\"event\":\"task_failed\",\"goal\":\"${goal}\",\"execution_id\":\"${execution_id}\",\"error\":\"Max iterations reached\",\"iteration\":${iteration},\"max_iterations\":${max_iterations}}"
        echo ""
        log_error "Limitless execution failed: max iterations reached"
        return 1
    fi
}

# ==============================================================================
# COMMANDS
# ==============================================================================

cmd_run() {
    local goal="$1"
    local max_iterations="${2:-100}"

    show_banner

    if [ -z "$goal" ]; then
        log_error "Goal is required"
        echo "Usage: $0 run \"your goal here\" [max_iterations]"
        exit 1
    fi

    nzt_protocol "$goal" "$max_iterations"
}

cmd_status() {
    show_banner
    log_info "Checking Limitless Agent status..."
    echo ""

    # Check Claude
    if check_claude; then
        log_success "Claude CLI: Available"
    else
        log_error "Claude CLI: Not found"
    fi

    # Check Ollama
    if check_ollama; then
        log_success "Ollama: Connected (https://ollama.intentum.ai)"
    else
        log_warning "Ollama: Not reachable"
    fi

    # Check n8n
    if check_n8n; then
        log_success "n8n: Connected (https://n8n.intentum.pro)"
    else
        log_warning "n8n: Not reachable"
    fi

    echo ""
    log_info "Limitless Home: ${LIMITLESS_HOME}"
    log_info "Config: ${LIMITLESS_CONFIG}"
}

cmd_health() {
    show_banner
    log_info "Running health check via n8n..."
    echo ""

    local response
    response=$(curl -s -X POST "${N8N_WEBHOOK_BASE}/limitless-monitor" \
        -H "Content-Type: application/json" \
        -d '{"action":"health_check"}')

    echo "$response" | jq . 2>/dev/null || echo "$response"
}

cmd_help() {
    show_banner
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  run <goal> [max_iter]  Execute Limitless Agent with a goal"
    echo "  status                 Check component status"
    echo "  health                 Run health check via n8n"
    echo "  help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 run \"Create a REST API with authentication\""
    echo "  $0 run \"Build a landing page\" 50"
    echo "  $0 status"
    echo ""
    echo "Environment Variables:"
    echo "  LIMITLESS_HOME         Installation directory"
    echo "  N8N_WEBHOOK_BASE       n8n webhook base URL"
    echo "  OLLAMA_ENDPOINT        Ollama API endpoint"
    echo ""
    echo "\"What if you could access 100% of your brain?\""
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        run)
            cmd_run "$@"
            ;;
        status)
            cmd_status
            ;;
        health)
            cmd_health
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
