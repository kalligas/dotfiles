#!/usr/bin/env bash
# install.sh — link this repo's agent config into ~/.claude and ~/.codex.
#
# Idempotent: safe to re-run. Anything it would replace is backed up first
# to ~/.agent-config-backup/<timestamp>/ before being touched.
#
# Usage:
#   ./install.sh                  # symlink mode (default)
#   ./install.sh --copy-claude-md # ~/.claude/CLAUDE.md becomes a real copy
#                                  # instead of a symlink (needed for Cowork;
#                                  # see README.md)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$SCRIPT_DIR"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$HOME/.agent-config-backup/$TIMESTAMP"
BACKUP_USED=false

COPY_CLAUDE_MD=false
for arg in "$@"; do
  case "$arg" in
    --copy-claude-md) COPY_CLAUDE_MD=true ;;
    *) echo "unknown flag: $arg" >&2; exit 1 ;;
  esac
done

# Codex's documented per-user skills directory. Keep the environment override
# for unusual installations, but use the cross-agent ~/.agents convention by
# default. Repository-scoped Codex skills live in .agents/skills instead.
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.agents/skills}"

# Paths this script must never create, modify, or back up. They hold
# credentials or session state, not configuration.
NEVER_TOUCH=(
  "$HOME/.claude.json"
  "$HOME/.claude/projects"
  "$HOME/.claude/todos"
  "$HOME/.claude/shell-snapshots"
  "$HOME/.claude/statsig"
  "$HOME/.claude/history.jsonl"
  "$HOME/.codex/auth.json"
  "$HOME/.codex/sessions"
  "$HOME/.codex/history.jsonl"
  "$HOME/.codex/logs"
  "$HOME/.codex/config.toml"  # intentionally out of scope; see README
)

LINKED=()
COPIED=()
BACKED_UP=()
SKIPPED=()
WARNINGS=()

is_guarded() {
  local p="$1"
  for g in "${NEVER_TOUCH[@]}"; do
    [[ "$p" == "$g" ]] && return 0
  done
  return 1
}

backup_path() {
  # Move an existing real file/dir/symlink at $1 into the backup dir,
  # preserving its path relative to $HOME.
  local src="$1"
  local rel="${src#"$HOME"/}"
  local dest="$BACKUP_ROOT/$rel"
  mkdir -p "$(dirname "$dest")"
  mv "$src" "$dest"
  BACKUP_USED=true
  BACKED_UP+=("$src -> $dest")
}

# link_path SRC DEST LABEL
# Ensure DEST is a symlink to SRC. Backs up whatever is at DEST first if it
# isn't already that exact symlink. Works for files and directories alike.
link_path() {
  local src="$1" dest="$2" label="$3"

  if is_guarded "$dest"; then
    SKIPPED+=("$label (guarded path, not touching): $dest")
    return
  fi

  if [[ -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      SKIPPED+=("$label (already linked): $dest")
      return
    fi
    backup_path "$dest"
  elif [[ -e "$dest" ]]; then
    backup_path "$dest"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  LINKED+=("$label: $dest -> $src")
}

echo "== agent-config install ($TIMESTAMP) =="
echo "repo:            $REPO"
echo "codex skills dir: $CODEX_SKILLS_DIR"
echo "claude md mode:   $([[ "$COPY_CLAUDE_MD" == true ]] && echo copy || echo symlink)"
echo

mkdir -p "$HOME/.claude" "$HOME/.codex"

# --- shared/AGENTS.md -> both tools' global instruction file ---------------
link_path "$REPO/shared/AGENTS.md" "$HOME/.codex/AGENTS.md" "codex AGENTS.md"

if [[ "$COPY_CLAUDE_MD" == true ]]; then
  DEST="$HOME/.claude/CLAUDE.md"
  if is_guarded "$DEST"; then
    SKIPPED+=("claude CLAUDE.md (guarded path, not touching): $DEST")
  elif [[ -L "$DEST" ]]; then
    backup_path "$DEST"
    cp "$REPO/shared/AGENTS.md" "$DEST"
    COPIED+=("claude CLAUDE.md (switched from symlink to copy): $DEST")
  elif [[ -e "$DEST" ]] && ! cmp -s "$REPO/shared/AGENTS.md" "$DEST"; then
    backup_path "$DEST"
    cp "$REPO/shared/AGENTS.md" "$DEST"
    COPIED+=("claude CLAUDE.md (existing copy differed, refreshed): $DEST")
  elif [[ -e "$DEST" ]]; then
    SKIPPED+=("claude CLAUDE.md (copy already up to date): $DEST")
  else
    cp "$REPO/shared/AGENTS.md" "$DEST"
    COPIED+=("claude CLAUDE.md (new copy): $DEST")
  fi
  WARNINGS+=("CLAUDE.md is a COPY, not a symlink. Re-run ./install.sh --copy-claude-md after editing shared/AGENTS.md, or the copy goes stale.")
else
  link_path "$REPO/shared/AGENTS.md" "$HOME/.claude/CLAUDE.md" "claude CLAUDE.md"
fi

# --- claude-only config ------------------------------------------------------
link_path "$REPO/claude/settings.json" "$HOME/.claude/settings.json" "claude settings.json"
link_path "$REPO/claude/rules"         "$HOME/.claude/rules"         "claude rules"
link_path "$REPO/claude/agents"        "$HOME/.claude/agents"        "claude agents"

# --- codex config.toml: intentionally NOT linked ----------------------------
# The ChatGPT desktop app rewrites ~/.codex/config.toml continuously (trust
# levels, UI state, absolute machine paths). It stays a real local file.
# See README.md "Codex config.toml" for the rationale.
SKIPPED+=("codex config.toml (intentionally not tracked/linked; see README): $HOME/.codex/config.toml")

# --- shared skills, linked one directory at a time --------------------------
# Never link a parent skills directory itself: it may contain skills installed
# by other sources. Link only the shared skill names managed by this repository.
mkdir -p "$HOME/.claude/skills" "$CODEX_SKILLS_DIR"

shopt -s nullglob
SKILL_DIRS=("$REPO"/shared/skills/*/)
shopt -u nullglob

if [[ ${#SKILL_DIRS[@]} -eq 0 ]]; then
  SKIPPED+=("shared skills (none defined yet in shared/skills/)")
else
  for dir in "${SKILL_DIRS[@]}"; do
    name="$(basename "$dir")"
    link_path "${dir%/}" "$HOME/.claude/skills/$name" "skill '$name' (claude)"
    link_path "${dir%/}" "$CODEX_SKILLS_DIR/$name"     "skill '$name' (codex)"
  done
fi

# --- summary -----------------------------------------------------------------
echo
echo "== summary =="
echo "linked (${#LINKED[@]}):"
printf '  %s\n' "${LINKED[@]:-}" | sed '/^  $/d'
echo "copied (${#COPIED[@]}):"
printf '  %s\n' "${COPIED[@]:-}" | sed '/^  $/d'
echo "backed up (${#BACKED_UP[@]}):"
printf '  %s\n' "${BACKED_UP[@]:-}" | sed '/^  $/d'
echo "skipped / already correct (${#SKIPPED[@]}):"
printf '  %s\n' "${SKIPPED[@]:-}" | sed '/^  $/d'

if [[ "$BACKUP_USED" == true ]]; then
  echo
  echo "backups written under: $BACKUP_ROOT"
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo
  echo "== warnings =="
  printf '  - %s\n' "${WARNINGS[@]}"
fi
