# Claude Code Configuration

Personal configuration directory for [Claude Code](https://claude.ai/code) CLI.

![Statusline Screenshot](statusline.png)

## Files

### Configuration

| File | Description |
|------|-------------|
| `settings.json` | User preferences (model selection, status line config, hooks) |
| `CLAUDE.md` | Global instructions that apply to all projects |

### Status Line

| File | Description |
|------|-------------|
| `statusline.sh` | Custom Trueline-style status bar showing model, git branch, context usage, tokens, cost, and duration |
| `statusline-ideas.md` | Notes on potential status line enhancements (e.g., fetching claude.ai quota data) |

The status line tracks **project-level** statistics (accumulated across sessions) rather than session-level stats. Data is stored in `~/.claude/project-stats/`.

### Hooks

| File | Description |
|------|-------------|
| `hooks/log-prompts.sh` | Logs each user prompt to `PROMPTS.md` in the current working directory with timestamps |

### Other

| File | Description |
|------|-------------|
| `.gitignore` | Excludes sensitive data, caches, history, and transient files from version control |
| `PROMPTS.md` | Auto-generated log of prompts from this directory (created by the hook) |

## What's Not Tracked

The `.gitignore` excludes:
- Credentials and secrets
- Cache and transient data (`cache/`, `file-history/`, `session-env/`)
- Conversation history (`history.jsonl`, `projects/`)
- Analytics data (`telemetry/`, `statsig/`)
- Browser automation state (`chrome/`)
- Plugins (managed separately)

## Usage

To use these configurations on another machine:

```bash
git clone <repo> ~/.claude
```

The status line requires `jq` and `bc` to be installed.
