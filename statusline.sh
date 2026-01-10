#!/bin/bash
# Trueline-style status line for Claude Code
# Displays usage bars for session context and cost

input=$(cat)

# ANSI color codes
RESET='\033[0m'
BOLD='\033[1m'

# Trueline-style colors
BG_BLUE='\033[44m'
BG_CYAN='\033[46m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_MAGENTA='\033[45m'
BG_RED='\033[41m'
BG_BLACK='\033[40m'
BG_GRAY='\033[100m'

FG_WHITE='\033[97m'
FG_BLACK='\033[30m'
FG_BLUE='\033[34m'
FG_CYAN='\033[36m'
FG_GREEN='\033[32m'
FG_YELLOW='\033[33m'
FG_MAGENTA='\033[35m'
FG_GRAY='\033[90m'

# Powerline-style arrows
ARROW_RIGHT=''
ARROW_LEFT=''

# Segment separator (space between segments)
SEP="  "

# Helper functions
get_value() {
    echo "$input" | jq -r "$1 // empty"
}

# Extract data
MODEL=$(get_value '.model.display_name')
MODEL_ID=$(get_value '.model.id')
COST=$(get_value '.cost.total_cost_usd')
DURATION_MS=$(get_value '.cost.total_duration_ms')
CONTEXT_SIZE=$(get_value '.context_window.context_window_size')
INPUT_TOKENS=$(get_value '.context_window.current_usage.input_tokens')
OUTPUT_TOKENS=$(get_value '.context_window.current_usage.output_tokens')
CACHE_CREATE=$(get_value '.context_window.current_usage.cache_creation_input_tokens')
CACHE_READ=$(get_value '.context_window.current_usage.cache_read_input_tokens')
TOTAL_INPUT=$(get_value '.context_window.total_input_tokens')
TOTAL_OUTPUT=$(get_value '.context_window.total_output_tokens')

# Calculate context usage percentage
CURRENT_TOKENS=0
if [ -n "$INPUT_TOKENS" ] && [ "$INPUT_TOKENS" != "null" ]; then
    CURRENT_TOKENS=$((INPUT_TOKENS + ${CACHE_CREATE:-0} + ${CACHE_READ:-0}))
fi

CONTEXT_PERCENT=0
if [ -n "$CONTEXT_SIZE" ] && [ "$CONTEXT_SIZE" != "null" ] && [ "$CONTEXT_SIZE" -gt 0 ]; then
    CONTEXT_PERCENT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
fi

# Progress bar function (trueline style)
make_bar() {
    local percent=$1
    local width=10
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    local bar=""

    # Choose color based on percentage
    local bar_color=$FG_GREEN
    if [ "$percent" -ge 80 ]; then
        bar_color=$FG_RED
    elif [ "$percent" -ge 60 ]; then
        bar_color=$FG_YELLOW
    fi

    # Build the bar
    bar="${bar_color}"
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${RESET}\033[90m"
    for ((i=0; i<empty; i++)); do bar+="░"; done
    bar+="${RESET}"

    echo -e "$bar"
}

# Format cost
format_cost() {
    if [ -z "$1" ] || [ "$1" == "null" ]; then
        echo "\$0.00"
    else
        printf "\$%.2f" "$1"
    fi
}

# Format tokens (K notation)
format_tokens() {
    local tokens=$1
    if [ -z "$tokens" ] || [ "$tokens" == "null" ] || [ "$tokens" -eq 0 ]; then
        echo "0"
    elif [ "$tokens" -ge 1000 ]; then
        printf "%.1fK" "$(echo "scale=1; $tokens/1000" | bc)"
    else
        echo "$tokens"
    fi
}

# Detect if model is Sonnet
is_sonnet() {
    [[ "$MODEL_ID" == *"sonnet"* ]] && return 0 || return 1
}

# Format duration from milliseconds to HH:MM:SS or MM:SS
format_duration() {
    local ms=$1
    if [ -z "$ms" ] || [ "$ms" == "null" ] || [ "$ms" -eq 0 ]; then
        echo "0:00"
        return
    fi

    local total_seconds=$((ms / 1000))
    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))
    local seconds=$((total_seconds % 60))

    if [ "$hours" -gt 0 ]; then
        printf "%d:%02d:%02d" "$hours" "$minutes" "$seconds"
    else
        printf "%d:%02d" "$minutes" "$seconds"
    fi
}

# Get git branch
get_git_branch() {
    local dir=$(get_value '.workspace.current_dir')
    if [ -n "$dir" ] && [ -d "$dir" ]; then
        cd "$dir" 2>/dev/null || return
        if git rev-parse --git-dir > /dev/null 2>&1; then
            local branch=$(git branch --show-current 2>/dev/null)
            if [ -z "$branch" ]; then
                # Detached HEAD - show short commit hash
                branch=$(git rev-parse --short HEAD 2>/dev/null)
            fi
            echo "$branch"
        fi
    fi
}

# Build status line segments
OUTPUT=""

# Segment 1: Model name with icon
MODEL_ICON="🤖"
if is_sonnet; then
    MODEL_ICON="🎵"
    OUTPUT+="${BG_MAGENTA}${FG_WHITE}${BOLD} ${MODEL_ICON} ${MODEL:-Claude} ${RESET}"
    OUTPUT+="${FG_MAGENTA}${ARROW_RIGHT}${RESET}"
else
    OUTPUT+="${BG_BLUE}${FG_WHITE}${BOLD} ${MODEL_ICON} ${MODEL:-Claude} ${RESET}"
    OUTPUT+="${FG_BLUE}${ARROW_RIGHT}${RESET}"
fi

# Segment 2: Git branch (if in a git repo)
GIT_BRANCH=$(get_git_branch)
if [ -n "$GIT_BRANCH" ]; then
    OUTPUT+="${SEP}"
    OUTPUT+="${BG_GRAY}${FG_WHITE}${BOLD}  ${GIT_BRANCH} ${RESET}"
    OUTPUT+="${FG_GRAY}${ARROW_RIGHT}${RESET}"
fi

# Segment 3: Context usage bar
CONTEXT_BAR=$(make_bar $CONTEXT_PERCENT)
OUTPUT+="${SEP}"
OUTPUT+="${BG_CYAN}${FG_BLACK} 📊 Ctx ${CONTEXT_PERCENT}% ${CONTEXT_BAR} ${RESET}"
OUTPUT+="${FG_CYAN}${ARROW_RIGHT}${RESET}"

# Segment 4: Session tokens
TOKENS_DISPLAY="$(format_tokens ${TOTAL_INPUT:-0})/$(format_tokens ${TOTAL_OUTPUT:-0})"
OUTPUT+="${SEP}"
OUTPUT+="${BG_GREEN}${FG_BLACK} ⇅ ${TOKENS_DISPLAY} ${RESET}"
OUTPUT+="${FG_GREEN}${ARROW_RIGHT}${RESET}"

# Segment 5: Cost
COST_DISPLAY=$(format_cost "$COST")
OUTPUT+="${SEP}"
OUTPUT+="${BG_YELLOW}${FG_BLACK} 💰 ${COST_DISPLAY} ${RESET}"
OUTPUT+="${FG_YELLOW}${ARROW_RIGHT}${RESET}"

# Segment 6: Session duration
DURATION_DISPLAY=$(format_duration "$DURATION_MS")
OUTPUT+="${SEP}"
OUTPUT+="${BG_RED}${FG_WHITE}${BOLD} ⏱ ${DURATION_DISPLAY} ${RESET}"
OUTPUT+="${FG_RED}${ARROW_RIGHT}${RESET}"

echo -e "$OUTPUT"
