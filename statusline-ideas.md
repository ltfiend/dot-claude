# Status Line Enhancement Ideas

## Idea: Display Claude.ai Account Usage Quotas

**Problem:** The status line only has access to session-level data. The actual account usage quotas (shown at claude.ai/settings/usage) are not available.

**Proposed Solution:** Browser automation to fetch and cache quota data

### Implementation Approach

1. **Create a quota fetcher script** that uses Claude-in-Chrome MCP tools to:
   - Navigate to claude.ai/settings/usage
   - Extract current usage percentage and reset time
   - Save to a cache file (e.g., `~/.claude/usage-cache.json`)

2. **Update statusline.sh** to:
   - Read from the cache file
   - Display quota bar and reset countdown
   - Show stale indicator if cache is old

3. **Refresh options:**
   - Manual: Run fetcher script on demand
   - Scheduled: Cron job or hook to refresh periodically
   - On-start: Fetch when Claude Code starts a new session

### Data to Extract
- Current usage (percentage or absolute)
- Reset time (countdown or timestamp)
- Plan limits (if visible)
- Sonnet vs Opus breakdown (if available)

### Cache Format
```json
{
  "fetched_at": "2025-01-10T12:00:00Z",
  "usage_percent": 45,
  "reset_time": "2025-01-10T17:00:00Z",
  "reset_in_hours": 5
}
```

### Notes
- Requires active browser session with Claude logged in
- Cache will become stale; need visual indicator
- Consider rate limiting fetches to avoid issues
