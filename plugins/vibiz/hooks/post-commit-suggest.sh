#!/usr/bin/env bash
# Vibiz post-commit suggester.
#
# Fires after every Bash tool use. If the command was a successful `git commit`
# AND the resulting commit is "post-worthy" (not a merge, not security-related,
# not boring infra, not opted-out), emits a systemMessage that nudges the LLM to
# offer `/vibiz:post`.
#
# Sidecase rules — exit silently (no nudge) if ANY are true:
#   - Not a git commit Bash invocation
#   - Bash exit code != 0 (commit failed)
#   - HEAD is a merge commit (multiple parents)
#   - Diff is < 5 lines changed (HEAD vs HEAD~1)
#   - Commit subject matches ^(chore|build|ci|style|docs|test)(\(|:)  (boring)
#   - Commit body contains [skip-vibiz] or [no-post]
#   - Commit subject/body matches a security-sensitive keyword
#   - Same commit SHA was already nudged this session (cookie-file dedupe)
#   - Not in a git repo (e.g. running in a non-repo directory)
#
# Designed to be near-zero overhead: short-circuits on the cheap checks first,
# only spawns git when we know it's a commit.

set -euo pipefail

input="$(cat)"

# -- Cheap filters ---------------------------------------------------------

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
[ "$tool_name" = "Bash" ] || exit 0

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
case "$cmd" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# Some toolchains expose .tool_response.exit_code; others .tool_result.exitCode.
# If we can read it and it's non-zero, the commit failed — bail.
exit_code="$(printf '%s' "$input" | jq -r '
  (.tool_response.exit_code // .tool_response.exitCode //
   .tool_result.exit_code  // .tool_result.exitCode  // 0)
' 2>/dev/null || echo 0)"
case "$exit_code" in
  0) ;;
  *) exit 0 ;;
esac

# -- Git-aware filters -----------------------------------------------------

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

sha="$(git rev-parse HEAD 2>/dev/null || true)"
[ -n "$sha" ] || exit 0

# Per-session dedupe cookie. CLAUDE_SESSION_ID is set by Claude Code; fall back
# to the parent shell pid so multi-tab sessions don't double-nudge each other.
session_id="${CLAUDE_SESSION_ID:-$PPID}"
cookie="${TMPDIR:-/tmp}/vibiz-nudge-${session_id}-${sha}.cookie"
[ -f "$cookie" ] && exit 0

# Skip merge commits.
parents="$(git rev-list --parents -n 1 "$sha" 2>/dev/null | wc -w | tr -d ' ')"
[ "${parents:-0}" -le 2 ] || exit 0

subject="$(git log -1 --format='%s' "$sha" 2>/dev/null || true)"
body="$(git log -1 --format='%b' "$sha" 2>/dev/null || true)"

# Opt-out tags.
case "$subject$body" in
  *"[skip-vibiz]"*|*"[no-post]"*) exit 0 ;;
esac

# Boring-infra subjects (keep regex case-insensitive).
shopt -s nocasematch
case "$subject" in
  chore\(*\):*|chore:*) exit 0 ;;
  build\(*\):*|build:*) exit 0 ;;
  ci\(*\):*|ci:*) exit 0 ;;
  style\(*\):*|style:*) exit 0 ;;
  docs\(*\):*|docs:*) exit 0 ;;
  test\(*\):*|test:*) exit 0 ;;
esac

# Security-sensitive keywords — never suggest posting these.
sec_pattern='password|secret|api.?key|token|cve-|vuln|xss|sqli|csrf|auth.?bypass|leak|exposure'
if [[ "$subject$body" =~ $sec_pattern ]]; then
  shopt -u nocasematch
  exit 0
fi
shopt -u nocasematch

# Tiny diffs aren't worth a post.
lines_changed="$(git diff --shortstat HEAD~1 HEAD 2>/dev/null \
  | awk '{ for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+$/) s+=$i; print s+0 }')"
[ "${lines_changed:-0}" -ge 5 ] || exit 0

# -- Emit the nudge --------------------------------------------------------

# Mark this commit nudged so we don't repeat.
: > "$cookie" || true

short_sha="${sha:0:7}"
trimmed_subject="${subject:0:120}"

# Build the full systemMessage in shell, then let jq do the JSON escaping in
# one shot. Avoids the classic pitfall of nested quotes / backticks inside the
# commit subject breaking the JSON envelope.
msg="Vibiz nudge: the user just committed ${short_sha} — ${trimmed_subject}. If they haven't already, OFFER (don't auto-run) the slash command /vibiz:post so they can draft a marketing post about this change. Keep it to one short line — they can ignore it. Skip if you've already offered this for this commit."

jq -n --arg msg "$msg" '{ systemMessage: $msg }'
