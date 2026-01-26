#!/bin/bash
# Trueline-style status line for Claude Code
# Displays usage bars for project-level context and cost (accumulated across sessions)

input=$(cat)

# ============================================
# SEGMENT TOGGLES - Set to 0 to disable
# ============================================
SHOW_DIRECTORY=1      # Current working directory
SHOW_MODEL=1          # Model name (Opus/Sonnet)
SHOW_GIT_BRANCH=1     # Git branch name
SHOW_CONTEXT=1        # Context headroom bar
SHOW_TOKENS=1         # Project token counts
SHOW_COST=1           # Project cost
SHOW_CACHE=1          # Cache efficiency
SHOW_DURATION=1       # Project duration
SHOW_API_DURATION=1   # API call duration
SHOW_LINES=1          # Lines added/removed
SHOW_DATETIME=1       # Current date/time
# ============================================

# ============================================
# LAYOUT - Reorder segments by rearranging names
# Use | to separate left-aligned from right-aligned
# Segments: directory model git_branch context tokens cost cache duration api_duration lines datetime
# ============================================
LAYOUT="directory model git_branch context tokens cost cache duration api_duration lines | datetime"

# Project stats directory
STATS_DIR="$HOME/.claude/project-stats"
mkdir -p "$STATS_DIR"

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
BG_ORANGE='\033[48;5;166m'  # Burnt orange
BG_MAROON='\033[48;5;124m'  # Dark red ~#ab260c
BG_STEEL_BLUE='\033[48;5;67m'  # Steel blue for efficiency

FG_WHITE='\033[97m'
FG_BLACK='\033[30m'
FG_BLUE='\033[34m'
FG_CYAN='\033[36m'
FG_GREEN='\033[32m'
FG_YELLOW='\033[33m'
FG_MAGENTA='\033[35m'
FG_GRAY='\033[90m'
FG_ORANGE='\033[38;5;166m'  # Burnt orange
FG_MAROON='\033[38;5;124m'  # Dark red ~#ab260c
FG_STEEL_BLUE='\033[38;5;67m'  # Steel blue

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
CACHE_CREATE=$(get_value '.context_window.current_usage.cache_creation_input_tokens')
CACHE_READ=$(get_value '.context_window.current_usage.cache_read_input_tokens')
TOTAL_INPUT=$(get_value '.context_window.total_input_tokens')
TOTAL_OUTPUT=$(get_value '.context_window.total_output_tokens')
REMAINING_PERCENT=$(get_value '.context_window.remaining_percentage')
SESSION_ID=$(get_value '.session.session_id')
WORKSPACE_DIR=$(get_value '.workspace.current_dir')
API_DURATION_MS=$(get_value '.cost.total_api_duration_ms')
LINES_ADDED=$(get_value '.cost.total_lines_added')
LINES_REMOVED=$(get_value '.cost.total_lines_removed')

# Project stats tracking
get_project_hash() {
    echo "$1" | md5sum | cut -c1-12
}

update_project_stats() {
    local project_dir="$1"
    local stats_file="$STATS_DIR/$(get_project_hash "$project_dir").json"

    # Default values
    local cur_cost=${COST:-0}
    local cur_duration=${DURATION_MS:-0}
    local cur_input=${TOTAL_INPUT:-0}
    local cur_output=${TOTAL_OUTPUT:-0}

    # Handle null/empty values
    [[ "$cur_cost" == "null" ]] && cur_cost=0
    [[ "$cur_duration" == "null" ]] && cur_duration=0
    [[ "$cur_input" == "null" ]] && cur_input=0
    [[ "$cur_output" == "null" ]] && cur_output=0

    if [ -f "$stats_file" ]; then
        # Read existing stats
        local last_session=$(jq -r '.last_session_id // ""' "$stats_file")
        local last_cost=$(jq -r '.last_session_cost // 0' "$stats_file")
        local last_duration=$(jq -r '.last_session_duration // 0' "$stats_file")
        local last_input=$(jq -r '.last_session_input // 0' "$stats_file")
        local last_output=$(jq -r '.last_session_output // 0' "$stats_file")
        local total_cost=$(jq -r '.total_cost // 0' "$stats_file")
        local total_duration=$(jq -r '.total_duration // 0' "$stats_file")
        local total_input=$(jq -r '.total_input // 0' "$stats_file")
        local total_output=$(jq -r '.total_output // 0' "$stats_file")

        if [ "$SESSION_ID" == "$last_session" ]; then
            # Same session - calculate delta from last call
            local delta_cost=$(echo "$cur_cost - $last_cost" | bc)
            local delta_duration=$((cur_duration - last_duration))
            local delta_input=$((cur_input - last_input))
            local delta_output=$((cur_output - last_output))

            # Only add positive deltas
            [[ $(echo "$delta_cost > 0" | bc) -eq 1 ]] && total_cost=$(echo "$total_cost + $delta_cost" | bc)
            [[ $delta_duration -gt 0 ]] && total_duration=$((total_duration + delta_duration))
            [[ $delta_input -gt 0 ]] && total_input=$((total_input + delta_input))
            [[ $delta_output -gt 0 ]] && total_output=$((total_output + delta_output))
        else
            # New session - add all current values
            total_cost=$(echo "$total_cost + $cur_cost" | bc)
            total_duration=$((total_duration + cur_duration))
            total_input=$((total_input + cur_input))
            total_output=$((total_output + cur_output))
        fi
    else
        # First time for this project
        local total_cost=$cur_cost
        local total_duration=$cur_duration
        local total_input=$cur_input
        local total_output=$cur_output
    fi

    # Save updated stats
    cat > "$stats_file" << EOF
{
  "project": "$project_dir",
  "last_session_id": "$SESSION_ID",
  "last_session_cost": $cur_cost,
  "last_session_duration": $cur_duration,
  "last_session_input": $cur_input,
  "last_session_output": $cur_output,
  "total_cost": $total_cost,
  "total_duration": $total_duration,
  "total_input": $total_input,
  "total_output": $total_output
}
EOF

    # Output the totals for use in statusline
    echo "$total_cost $total_duration $total_input $total_output"
}

# Get project-level accumulated stats
PROJECT_STATS=""
if [ -n "$WORKSPACE_DIR" ] && [ "$WORKSPACE_DIR" != "null" ]; then
    PROJECT_STATS=$(update_project_stats "$WORKSPACE_DIR")
    PROJECT_COST=$(echo "$PROJECT_STATS" | awk '{print $1}')
    PROJECT_DURATION=$(echo "$PROJECT_STATS" | awk '{print $2}')
    PROJECT_INPUT=$(echo "$PROJECT_STATS" | awk '{print $3}')
    PROJECT_OUTPUT=$(echo "$PROJECT_STATS" | awk '{print $4}')
else
    # Fallback to session stats if no workspace
    PROJECT_COST=$COST
    PROJECT_DURATION=$DURATION_MS
    PROJECT_INPUT=$TOTAL_INPUT
    PROJECT_OUTPUT=$TOTAL_OUTPUT
fi

# Context remaining percentage (from Claude Code JSON)
HEADROOM_PERCENT=${REMAINING_PERCENT%.*}  # truncate decimal
HEADROOM_PERCENT=${HEADROOM_PERCENT:-100}

# Progress bar function (trueline style)
# Shows remaining capacity (bar decreases as usage increases)
make_headroom_bar() {
    local remaining_percent=$1
    local width=20
    local filled=$((remaining_percent * width / 100))
    local empty=$((width - filled))
    local bar=""

    # Choose color based on remaining percentage (low remaining = bad)
    local bar_color=$FG_GREEN
    if [ "$remaining_percent" -le 20 ]; then
        bar_color=$FG_RED
    elif [ "$remaining_percent" -le 40 ]; then
        bar_color=$FG_YELLOW
    fi

    # Build the bar (filled = remaining capacity, empty = used)
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

# ============================================
# SEGMENT DEFINITIONS
# Each function outputs its formatted segment or nothing if disabled/no data
# ============================================

segment_directory() {
    [ "$SHOW_DIRECTORY" -eq 1 ] || return
    [ -n "$WORKSPACE_DIR" ] && [ "$WORKSPACE_DIR" != "null" ] || return
    local DIR_NAME=$(basename "$WORKSPACE_DIR")
    echo "${BG_BLACK}${FG_WHITE}${BOLD} 📁 ${DIR_NAME} ${RESET}${FG_BLACK}${ARROW_RIGHT}${RESET}"
}

segment_model() {
    [ "$SHOW_MODEL" -eq 1 ] || return
    local MODEL_ICON="🤖"
    if is_sonnet; then
        MODEL_ICON="🎵"
        echo "${BG_MAGENTA}${FG_BLACK} ${MODEL_ICON} ${MODEL:-Claude} ${RESET}${FG_MAGENTA}${ARROW_RIGHT}${RESET}"
    else
        echo "${BG_BLUE}${FG_BLACK} ${MODEL_ICON} ${MODEL:-Claude} ${RESET}${FG_BLUE}${ARROW_RIGHT}${RESET}"
    fi
}

segment_git_branch() {
    [ "$SHOW_GIT_BRANCH" -eq 1 ] || return
    local GIT_ICON=$'\uf1d2'
    local GIT_BRANCH=$(get_git_branch)
    [ -n "$GIT_BRANCH" ] || return
    echo "${BG_ORANGE}${FG_BLACK} ${GIT_ICON} ${GIT_BRANCH} ${RESET}${FG_ORANGE}${ARROW_RIGHT}${RESET}"
}

segment_context() {
    [ "$SHOW_CONTEXT" -eq 1 ] || return
    local CONTEXT_BAR=$(make_headroom_bar $HEADROOM_PERCENT)
    echo "${BG_CYAN}${FG_BLACK} 📊 ${HEADROOM_PERCENT}% ${CONTEXT_BAR} ${RESET}${FG_CYAN}${ARROW_RIGHT}${RESET}"
}

segment_tokens() {
    [ "$SHOW_TOKENS" -eq 1 ] || return
    local TOKENS_DISPLAY="$(format_tokens ${PROJECT_INPUT:-0})/$(format_tokens ${PROJECT_OUTPUT:-0})"
    echo "${BG_GREEN}${FG_BLACK} ⇅ ${TOKENS_DISPLAY} ${RESET}${FG_GREEN}${ARROW_RIGHT}${RESET}"
}

segment_cost() {
    [ "$SHOW_COST" -eq 1 ] || return
    local COST_DISPLAY=$(format_cost "$PROJECT_COST")
    echo "${BG_BLACK}${FG_WHITE} 💰 ${COST_DISPLAY} ${RESET}${FG_BLACK}${ARROW_RIGHT}${RESET}"
}

segment_cache() {
    [ "$SHOW_CACHE" -eq 1 ] || return
    local CACHE_TOTAL=$((${CACHE_CREATE:-0} + ${CACHE_READ:-0}))
    [ "$CACHE_TOTAL" -gt 0 ] || return
    local CACHE_HIT_PERCENT=$((${CACHE_READ:-0} * 100 / CACHE_TOTAL))
    echo "${BG_STEEL_BLUE}${FG_BLACK} ⚡${CACHE_HIT_PERCENT}% ${RESET}${FG_STEEL_BLUE}${ARROW_RIGHT}${RESET}"
}

segment_duration() {
    [ "$SHOW_DURATION" -eq 1 ] || return
    local DURATION_DISPLAY=$(format_duration "$PROJECT_DURATION")
    echo "${BG_MAGENTA}${FG_BLACK} ⏱ ${DURATION_DISPLAY} ${RESET}${FG_MAGENTA}${ARROW_RIGHT}${RESET}"
}

segment_api_duration() {
    [ "$SHOW_API_DURATION" -eq 1 ] || return
    local API_DUR=${API_DURATION_MS:-0}
    [[ "$API_DUR" == "null" ]] && API_DUR=0
    [ "$API_DUR" -gt 0 ] || return
    local API_DURATION_DISPLAY=$(format_duration "$API_DUR")
    echo "${BG_YELLOW}${FG_BLACK} 📡 ${API_DURATION_DISPLAY} ${RESET}${FG_YELLOW}${ARROW_RIGHT}${RESET}"
}

segment_lines() {
    [ "$SHOW_LINES" -eq 1 ] || return
    local LA=${LINES_ADDED:-0}
    local LR=${LINES_REMOVED:-0}
    [[ "$LA" == "null" ]] && LA=0
    [[ "$LR" == "null" ]] && LR=0
    [ "$LA" -gt 0 ] || [ "$LR" -gt 0 ] || return
    echo "${BG_BLACK}${FG_GREEN}${BOLD} +${LA} ${RESET}${BG_BLACK}${FG_MAROON}${BOLD} -${LR} ${RESET}${FG_BLACK}${ARROW_RIGHT}${RESET}"
}

segment_datetime() {
    [ "$SHOW_DATETIME" -eq 1 ] || return
    local CURRENT_TIME=$(date '+%Y-%m-%d %H:%M')
    echo "${BG_GRAY}${FG_BLACK} ${CURRENT_TIME} ${RESET}${FG_GRAY}${ARROW_RIGHT}${RESET}"
}

# ============================================
# RENDER ENGINE
# ============================================

render_segment() {
    case "$1" in
        directory)    segment_directory ;;
        model)        segment_model ;;
        git_branch)   segment_git_branch ;;
        context)      segment_context ;;
        tokens)       segment_tokens ;;
        cost)         segment_cost ;;
        cache)        segment_cache ;;
        duration)     segment_duration ;;
        api_duration) segment_api_duration ;;
        lines)        segment_lines ;;
        datetime)     segment_datetime ;;
    esac
}

# Strip ANSI escape codes to measure visible character width
visible_length() {
    local clean
    clean=$(echo -e "$1" | sed $'s/\033\[[0-9;]*m//g')
    echo "${#clean}"
}

# Parse LAYOUT into left and right groups, render segments
LEFT_OUTPUT=""
RIGHT_OUTPUT=""
side="left"

for item in $LAYOUT; do
    if [ "$item" = "|" ]; then
        side="right"
        continue
    fi
    result=$(render_segment "$item")
    if [ -n "$result" ]; then
        if [ "$side" = "left" ]; then
            [ -n "$LEFT_OUTPUT" ] && LEFT_OUTPUT+="${SEP}"
            LEFT_OUTPUT+="$result"
        else
            [ -n "$RIGHT_OUTPUT" ] && RIGHT_OUTPUT+="${SEP}"
            RIGHT_OUTPUT+="$result"
        fi
    fi
done

# Output with right-justification padding
if [ -n "$RIGHT_OUTPUT" ]; then
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 120)
    LEFT_LEN=$(visible_length "$LEFT_OUTPUT")
    RIGHT_LEN=$(visible_length "$RIGHT_OUTPUT")
    PADDING=$((TERM_WIDTH - LEFT_LEN - RIGHT_LEN))
    if [ "$PADDING" -gt 0 ]; then
        printf -v PAD_STR '%*s' "$PADDING" ''
        echo -e "${LEFT_OUTPUT}${PAD_STR}${RIGHT_OUTPUT}"
    else
        # Terminal too narrow for padding; fall back to separator
        echo -e "${LEFT_OUTPUT}${SEP}${RIGHT_OUTPUT}"
    fi
else
    echo -e "$LEFT_OUTPUT"
fi
