#!/bin/sh
# Report CLIs on PATH without starting an agent or checking credentials.
set -eu

found=false
for reviewer in claude codex gemini; do
    if reviewer_path=$(command -v "$reviewer" 2>/dev/null); then
        printf '%s\t%s\n' "$reviewer" "$reviewer_path"
        found=true
    fi
done

if [ "$found" = false ]; then
    printf '%s\n' 'No reviewer CLI found; use a fresh-context subagent or label the result self-review, not independent.' >&2
fi
