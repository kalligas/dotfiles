#!/usr/bin/env bash
# init-project.sh — scaffold a project for both Claude Code and Codex.
# Run from the project's repo root.
#
# Usage:
#   /path/to/dotagents/templates/init-project.sh            # symlink CLAUDE.md
#   /path/to/dotagents/templates/init-project.sh --import    # real CLAUDE.md
#                                                              with @AGENTS.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

IMPORT_MODE=false
for arg in "$@"; do
  case "$arg" in
    --import) IMPORT_MODE=true ;;
    *) echo "unknown flag: $arg" >&2; exit 1 ;;
  esac
done

echo "== init-project ($PROJECT_ROOT) =="

# --- AGENTS.md ---------------------------------------------------------------
if [[ -e "$PROJECT_ROOT/AGENTS.md" ]]; then
  echo "skip: AGENTS.md already exists, not clobbering"
else
  cp "$SCRIPT_DIR/AGENTS.md.tmpl" "$PROJECT_ROOT/AGENTS.md"
  echo "created: AGENTS.md (from template)"
fi

# --- AGENTS.override.md warning ----------------------------------------------
if [[ -e "$PROJECT_ROOT/AGENTS.override.md" ]]; then
  echo
  echo "WARNING: AGENTS.override.md exists at the repo root."
  echo "Codex reads at most one instruction file per directory and prefers"
  echo "the override over AGENTS.md. That means this override is SILENCING"
  echo "the committed AGENTS.md for Codex, not layering on top of it."
  echo "If that's not intentional, fold its contents into AGENTS.md instead."
  echo
fi

# --- CLAUDE.md ----------------------------------------------------------------
if [[ -e "$PROJECT_ROOT/CLAUDE.md" || -L "$PROJECT_ROOT/CLAUDE.md" ]]; then
  echo "skip: CLAUDE.md already exists, not clobbering"
elif [[ "$IMPORT_MODE" == true ]]; then
  cat > "$PROJECT_ROOT/CLAUDE.md" << 'EOF'
@AGENTS.md

## Claude Code

<!-- Claude-specific instructions that don't apply to Codex, or that
     Windows contributors (who may not see AGENTS.md conventions the same
     way) need spelled out explicitly here. -->
EOF
  echo "created: CLAUDE.md (real file, @AGENTS.md import + Claude Code section)"
else
  ln -s AGENTS.md "$PROJECT_ROOT/CLAUDE.md"
  echo "created: CLAUDE.md -> AGENTS.md (symlink)"
fi

# --- skills -------------------------------------------------------------------
mkdir -p "$PROJECT_ROOT/.agents/skills" "$PROJECT_ROOT/.claude/skills"
echo "ensured: .agents/skills/ and .claude/skills/"

shopt -s nullglob
SKILL_DIRS=("$PROJECT_ROOT"/.agents/skills/*/)
shopt -u nullglob

for dir in "${SKILL_DIRS[@]}"; do
  name="$(basename "$dir")"
  link="$PROJECT_ROOT/.claude/skills/$name"
  if [[ -L "$link" ]]; then
    echo "skip: .claude/skills/$name already linked"
  elif [[ -e "$link" ]]; then
    echo "skip: .claude/skills/$name exists and is not a symlink, not touching"
  else
    ln -s "../../.agents/skills/$name" "$link"
    echo "linked: .claude/skills/$name -> ../../.agents/skills/$name"
  fi
done

# --- .gitignore ----------------------------------------------------------------
if [[ -f "$PROJECT_ROOT/.gitignore" ]]; then
  if ! grep -qxF "CLAUDE.local.md" "$PROJECT_ROOT/.gitignore"; then
    echo "CLAUDE.local.md" >> "$PROJECT_ROOT/.gitignore"
    echo "added: CLAUDE.local.md to .gitignore"
  else
    echo "skip: CLAUDE.local.md already in .gitignore"
  fi
else
  echo "CLAUDE.local.md" > "$PROJECT_ROOT/.gitignore"
  echo "created: .gitignore with CLAUDE.local.md"
fi

echo
echo "done."
