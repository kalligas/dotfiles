#!/bin/sh
# Start one read-only reviewer and mark the run as failed when it produced no review.
# Usage: run_reviewer.sh <codex|claude> <repo> <review_dir> <name> [<related-repo> ...]
# Reads <review_dir>/<name>.prompt.md; writes <name>.out.md and <name>.err.log, and
# <name>.status only on failure. Exits non-zero on failure, so a fallback can follow ||.
set -eu

if [ "$#" -lt 4 ]; then
    sed -n '3,6p' "$0" >&2
    exit 2
fi
cli=$1 repo=$2 review_dir=$3 name=$4
shift 4

prompt="$review_dir/$name.prompt.md"
out="$review_dir/$name.out.md"
err="$review_dir/$name.err.log"
status="$review_dir/$name.status"
[ -f "$prompt" ] || { echo "no prompt: $prompt" >&2; exit 2; }

# A rerun under another CLI replaces the failed run's files; keep the failed log for the report.
if [ -f "$status" ]; then
    mv "$err" "$review_dir/$name.failed-$(date +%s).err.log" 2>/dev/null || true
    rm -f "$status"
fi
rm -f "$out"

rc=0
case "$cli" in
    codex)
        codex exec --sandbox read-only --ephemeral --color never \
            -C "$repo" \
            --output-last-message "$out" \
            - < "$prompt" > "$review_dir/$name.events.log" 2> "$err" || rc=$?
        ;;
    claude)
        # No shell: Read, Grep and Glob only, so the reviewer cannot run any command.
        # Turn the related repositories left in "$@" into --add-dir pairs, keeping spaces.
        related_count=$#
        set -- "$@" --add-dir "$review_dir"
        while [ "$related_count" -gt 0 ]; do
            related=$1
            shift
            set -- "$@" --add-dir "$related"
            related_count=$((related_count - 1))
        done
        (cd "$repo" && claude --print --no-session-persistence --output-format text \
            --permission-mode dontAsk \
            --tools 'Read,Grep,Glob' \
            "$@" \
            --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
            < "$prompt" > "$out" 2> "$err") || rc=$?
        ;;
    *)
        echo "unsupported reviewer CLI: $cli (codex or claude)" >&2
        exit 2
        ;;
esac

reason=
# Codex streams the whole session to stderr, so match only its own error lines, never
# reviewed content that happens to mention a rate limit.
if grep -Eq '^ERROR: .*(429 Too Many Requests|exceeded retry limit)' "$err" 2>/dev/null; then
    reason="rate limited"
elif [ ! -s "$out" ]; then
    reason="empty review (exit $rc)"
fi

if [ -n "$reason" ]; then
    printf '%s: %s; see %s\n' "$cli" "$reason" "$err" > "$status"
    cat "$status" >&2
    exit 1
fi
printf '%s: %s done (%s bytes)\n' "$cli" "$name" "$(wc -c < "$out" | tr -d ' ')"
