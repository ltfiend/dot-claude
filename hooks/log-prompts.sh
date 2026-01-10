#!/bin/bash
# Hook: Log user prompts to PROMPTS.md in the current project

# Read JSON input from stdin
input=$(cat)

# Extract the prompt using jq (or fallback to grep/sed if jq unavailable)
if command -v jq &> /dev/null; then
    prompt=$(echo "$input" | jq -r '.prompt // empty')
else
    # Fallback: extract prompt field (basic extraction)
    prompt=$(echo "$input" | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"prompt"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/')
fi

# Only proceed if we have a prompt
if [ -n "$prompt" ]; then
    # Get current timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Append to PROMPTS.md in current working directory
    {
        echo "## $timestamp"
        echo ""
        echo "$prompt"
        echo ""
        echo "---"
        echo ""
    } >> PROMPTS.md
fi

# Output empty JSON (hook must return valid JSON)
echo '{}'
