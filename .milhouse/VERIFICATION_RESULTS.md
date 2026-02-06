# Milhouse Tool Verification Results
**Date:** 2026-02-06  
**Branch:** `milhouse/tool-verification`

## Summary

| Tool | Status | Notes |
|------|--------|-------|
| Copilot CLI | ✅ PASS | Commit `99ab6b8` |
| OpenCode CLI | ✅ PASS | Commit `911de58` |
| AMP CLI | ❌ FAIL | Requires paid credits (402 error) |
| Install Command | ✅ PASS | Creates all expected files |
| Claude CLI | ✅ PASS | Fixed stdin hanging issue |

## Detailed Results

### US-002: Copilot CLI ✅
- Successfully read prd.json, progress.txt, CLAUDE.md
- Created verification branch
- Appended to progress.txt
- Updated prd.json marking story complete
- Committed with proper format

### US-003: OpenCode CLI ✅
- Successfully read all required files
- Updated prd.json and progress.txt
- Committed with proper format

### US-004: AMP CLI ❌
**Error:**
```
402 {"type":"error","error":{"type":"unknown_error","message":"Execute mode (amp -x) and the Amp SDK require paid credits and cannot use Amp's ad-supported free-tier, because ads cannot be displayed in non-interactive contexts. Add credits at https://ampcode.com/pay."}}
```

**Root Cause:** AMP's free tier ($10/day, ad-supported) is **interactive-only by design**. The execute mode (`-x`, `--dangerously-allow-all`) used by Milhouse requires paid credits because:
- Ads cannot display in non-interactive/scripted contexts
- Execute mode runs headless without a TTY

**User has $10 free credits available** (`amp usage`) but they can only be used interactively.

**Options:**
1. **Add paid credits** at https://ampcode.com/pay for automated use
2. **Run AMP manually** in interactive mode (not through Milhouse)
3. **Use alternative tools** (Copilot, OpenCode, Claude) for automation

### US-005: Install Command ✅
Created files:
- `.milhouse/.milhouse-source`
- `.milhouse/prd.json`
- `.milhouse/progress.txt`
- `CLAUDE.md` (at project root)

### US-001: Claude CLI ✅
**Status:** PASSED
**Fix:** Applied `< /dev/null` redirection to `agent.sh` to prevent `SIGTTIN` signal hanging background process. This matches behavior of legacy `ralph.sh`.

## Recommendations

1. **Claude CLI**: Wait until 5pm Tokyo, then run `milhouse run --tool claude 1`
2. **AMP CLI**: Add paid credits if you need AMP support for non-interactive mode
3. **Default Tool**: Use `copilot` or `opencode` as alternatives when Claude is rate limited
