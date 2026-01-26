# Claude Code Statusline

A Trueline-style status bar for Claude Code that displays real-time session and project statistics.

## Segments

| # | Icon | Segment | Description |
|---|------|---------|-------------|
| 1 | 📁 | Directory | Current working directory name |
| 2 | 🤖/🎵 | Model | Current model (robot for Opus, music note for Sonnet) |
| 3 |  | Git Branch | Current branch or detached HEAD commit |
| 4 | 📊 | Context Headroom | Remaining context capacity (bar decreases as context fills) |
| 5 | ⇅ | Tokens | Project total input/output tokens |
| 6 | 💰 | Cost | Project total cost in USD |
| 7 | ⏱ | Duration | Project total time spent |
| 8 | ⚡ | Cache Efficiency | Prompt cache hit percentage (only shown when caching active) |
| 9 | | Time | Current time (HH:MM) |

## Project-Level Tracking

Unlike session-based stats, this statusline tracks **cumulative statistics per project**. Stats persist across sessions and accumulate over time.

### How It Works

1. Projects are identified by their workspace directory
2. Stats are stored in `~/.claude/project-stats/{hash}.json`
3. Each API response updates the project totals
4. New sessions add to existing totals; same-session calls track deltas

### Stats File Format

```json
{
  "project": "/path/to/project",
  "last_session_id": "abc123",
  "last_session_cost": 0.05,
  "last_session_duration": 30000,
  "last_session_input": 5000,
  "last_session_output": 2000,
  "total_cost": 1.25,
  "total_duration": 3600000,
  "total_input": 150000,
  "total_output": 75000
}
```

### Resetting Project Stats

To reset stats for a project, delete its file from `~/.claude/project-stats/`.

To reset all project stats:
```bash
rm ~/.claude/project-stats/*.json
```

## Context Headroom Bar

The context bar shows **remaining capacity**, not usage:

- **100%** = Empty context (full capacity available)
- **0%** = Context full (summarization imminent)

Color coding:
- 🟢 Green: > 40% remaining
- 🟡 Yellow: 20-40% remaining
- 🔴 Red: < 20% remaining

The bar is 20 characters wide and decreases as you use more context.

## Dependencies

- `jq` - JSON parsing
- `bc` - Floating point math
- `md5sum` - Project hashing

## Configuration

The statusline is configured in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
```

## Customization

Edit `~/.claude/statusline.sh` to customize:

- **Colors**: Modify the ANSI color variables at the top
- **Segments**: Add, remove, or reorder segments in the "Build status line segments" section
- **Bar width**: Change `width=20` in `make_headroom_bar()` function
- **Icons**: Replace emoji icons with alternatives

### Segment Toggles

Enable or disable individual segments by editing the toggle variables at the top of `statusline.sh`:

```bash
SHOW_DIRECTORY=1      # Current working directory
SHOW_MODEL=1          # Model name (Opus/Sonnet)
SHOW_GIT_BRANCH=1     # Git branch name
SHOW_CONTEXT=1        # Context headroom bar
SHOW_TOKENS=1         # Project token counts
SHOW_COST=1           # Project cost
SHOW_CACHE=1          # Cache efficiency
SHOW_DURATION=1       # Project duration
SHOW_DATETIME=1       # Current date/time
```

Set any value to `0` to hide that segment.

## Available Data

The statusline receives JSON from Claude Code with these fields:

| Path | Description |
|------|-------------|
| `.model.display_name` | Model name |
| `.model.id` | Model ID (used to detect Sonnet) |
| `.cost.total_cost_usd` | Session cost |
| `.cost.total_duration_ms` | Session duration |
| `.context_window.context_window_size` | Max context size |
| `.context_window.used_percentage` | Pre-calculated % of context used |
| `.context_window.remaining_percentage` | Pre-calculated % of context remaining |
| `.context_window.current_usage.input_tokens` | Current turn input |
| `.context_window.current_usage.output_tokens` | Current turn output |
| `.context_window.current_usage.cache_creation_input_tokens` | Cache writes |
| `.context_window.current_usage.cache_read_input_tokens` | Cache hits |
| `.context_window.total_input_tokens` | Session total input |
| `.context_window.total_output_tokens` | Session total output |
| `.cost.total_api_duration_ms` | Time spent on API calls |
| `.cost.total_lines_added` | Lines of code added in session |
| `.cost.total_lines_removed` | Lines of code removed in session |
| `.version` | Claude Code version string |
| `.workspace.project_dir` | Original project directory |
| `.session.session_id` | Unique session ID |
| `.workspace.current_dir` | Working directory |
