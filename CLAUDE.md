# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the `~/.claude` configuration directory for Claude Code. It contains:
- **plugins/marketplaces/claude-plugins-official/**: The official Claude Code plugins marketplace with internal (Anthropic) and external (third-party) plugins
- **projects/**: Per-project configuration and history
- **settings.json**: User preferences
- **history.jsonl**: Conversation history

## Plugin Marketplace Structure

```
plugins/marketplaces/claude-plugins-official/
├── plugins/           # Internal plugins by Anthropic
└── external_plugins/  # Third-party partner plugins
```

## Plugin Architecture

Each plugin follows this structure:
```
plugin-name/
├── .claude-plugin/
│   └── plugin.json      # Plugin metadata (required)
├── .mcp.json            # MCP server configuration (optional)
├── commands/            # Slash commands as .md files (optional)
├── agents/              # Agent definitions (optional)
├── skills/              # Skill definitions with SKILL.md (optional)
├── hooks/               # Hook scripts (optional)
└── README.md
```

### Plugin Components

**Commands** (`commands/*.md`): User-invoked via `/command-name`. Markdown files with YAML frontmatter:
```yaml
---
description: Short description for /help
argument-hint: <arg1> [optional-arg]
allowed-tools: [Read, Glob, Grep, Bash]
---
```

**Skills** (`skills/*/SKILL.md`): Model-invoked capabilities Claude uses based on context. Frontmatter:
```yaml
---
name: skill-name
description: Trigger conditions describing when Claude should use this skill
version: 1.0.0
---
```

**Agents**: Autonomous subagents spawned by Claude for specialized tasks.

**Hooks**: Event-driven scripts triggered on PreToolUse, PostToolUse, Stop, UserPromptSubmit, etc.

**MCP Servers** (`.mcp.json`): External tool integration via Model Context Protocol.

## Key Plugins

- **plugin-dev**: Comprehensive toolkit for developing plugins (hooks, MCP, structure, commands, agents, skills)
- **hookify**: Create custom hooks via markdown files without editing hooks.json
- **example-plugin**: Reference implementation demonstrating all extension options
- **commit-commands**, **code-review**, **pr-review-toolkit**: Git workflow tools
- **LSP plugins** (typescript-lsp, pyright-lsp, gopls-lsp, etc.): Language server integrations

## Testing Plugins Locally

```bash
cc --plugin-dir /path/to/plugin-name
```

## Installing Plugins

```bash
/plugin install {plugin-name}@claude-plugin-directory
# or browse in /plugin > Discover
```

## Environment Variables in Plugins

Use `${CLAUDE_PLUGIN_ROOT}` for portable paths within plugin configurations. Environment variables are expanded in hooks.json and .mcp.json.

## Workflow Rules

- **Always commit after edits**: When you finish making code changes or edits, create a git commit with a descriptive message summarizing the changes. Do not wait for the user to ask.
