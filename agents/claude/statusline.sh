#!/bin/bash
# Claude Code status line: repo: repo | wt: worktree | git: branch[*] | mdl: model | ctx: % | cost: $
input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
  model=$(echo "$input" | jq -r '.model.display_name // empty')
  ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
  cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
else
  cwd=$(pwd)
  model=""; ctx=""; cost=""
fi
[ -z "$cwd" ] && cwd=$(pwd)

out=""
add() { [ -n "$1" ] && { [ -n "$out" ] && out="$out | $1" || out="$1"; }; }

# The main repo root is the parent of the shared .git dir, so it stays the same
# inside a linked worktree, where --show-toplevel returns the worktree folder.
toplevel=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
if [ -n "$toplevel" ]; then
  common=$(git -C "$cwd" --no-optional-locks rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  repo_root=$(dirname "$common")
  add "repo: $(basename "$repo_root")"
  [ "$toplevel" != "$repo_root" ] && add "wt: $(basename "$toplevel")"

  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    dirty=""
    [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -n 1)" ] && dirty="*"
    add "git: ${branch}${dirty}"
  fi
else
  add "dir: $(basename "$cwd")"
fi

[ -n "$model" ] && add "mdl: $model"
[ -n "$ctx" ] && add "$(printf 'ctx: %.0f%%' "$ctx")"
[ -n "$cost" ] && add "$(printf 'cost: $%.2f' "$cost")"

printf '%s\n' "$out"
