#!/usr/bin/env bash
# init-project.sh — scaffold a project for both Claude Code and Codex.
# Run from the project's repo root. Safe to re-run: it never overwrites
# existing files.
#
# Usage:
#   ~/dotfiles/agents/templates/init-project.sh             # CLAUDE.md -> AGENTS.md
#   ~/dotfiles/agents/templates/init-project.sh --import    # CLAUDE.md imports AGENTS.md
#   ~/dotfiles/agents/templates/init-project.sh --prefix wf # skills named wf-<topic>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(pwd -P)"

if ! GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "error: run this script from the root of a Git repository" >&2
  exit 1
fi
GIT_ROOT="$(cd "$GIT_ROOT" && pwd -P)"

if [[ "$PROJECT_ROOT" != "$GIT_ROOT" ]]; then
  echo "error: run this script from the repository root: $GIT_ROOT" >&2
  exit 1
fi

IMPORT_MODE=false
SKILL_PREFIX=""
while (( $# > 0 )); do
  case "$1" in
    --import) IMPORT_MODE=true ;;
    --prefix)
      if (( $# < 2 )); then
        echo "error: --prefix needs a value" >&2
        exit 1
      fi
      SKILL_PREFIX="$2"
      shift
      ;;
    --prefix=*) SKILL_PREFIX="${1#--prefix=}" ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

# Skill names allow lowercase letters, digits, and hyphens. Without
# --prefix, the repo directory name is normalized to those characters.
if [[ -z "$SKILL_PREFIX" ]]; then
  SKILL_PREFIX="$(basename "$PROJECT_ROOT" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9-]+/-/g; s/-+/-/g; s/^-//; s/-$//')"
  if [[ -z "$SKILL_PREFIX" ]]; then
    echo "error: could not derive a skill prefix from the directory name;" >&2
    echo "pass one with --prefix" >&2
    exit 1
  fi
elif ! [[ "$SKILL_PREFIX" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "error: --prefix must be lowercase letters, digits, and single hyphens" >&2
  exit 1
fi

# Copy a template, replacing {{PREFIX}} with the skill prefix.
render_template() {
  sed "s/{{PREFIX}}/$SKILL_PREFIX/g" "$1" > "$2"
}

echo "== init-project ($PROJECT_ROOT, skill prefix: $SKILL_PREFIX) =="

# --- AGENTS.md ---------------------------------------------------------------
if [[ -e "$PROJECT_ROOT/AGENTS.md" ]]; then
  echo "skip: AGENTS.md already exists, not clobbering"
else
  render_template "$SCRIPT_DIR/AGENTS.md.tmpl" "$PROJECT_ROOT/AGENTS.md"
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

<!-- Claude-only instructions go below this line. Instructions for every
     agent belong in AGENTS.md, so Codex sees them too. -->
EOF
  echo "created: CLAUDE.md (imports AGENTS.md)"
else
  ln -s AGENTS.md "$PROJECT_ROOT/CLAUDE.md"
  echo "created: CLAUDE.md -> AGENTS.md (symlink)"
fi

# --- skills -------------------------------------------------------------------
mkdir -p "$PROJECT_ROOT/.agents/skills"

shopt -s nullglob
SKILL_DIRS=("$PROJECT_ROOT"/.agents/skills/*/)
shopt -u nullglob

# The example skill is only added to a repo that has no skills yet, so
# deleting it later does not bring it back on the next run.
if (( ${#SKILL_DIRS[@]} == 0 )); then
  EXAMPLE="$PROJECT_ROOT/.agents/skills/$SKILL_PREFIX-example"
  mkdir -p "$EXAMPLE/agents"
  render_template "$SCRIPT_DIR/skill/SKILL.md.tmpl" "$EXAMPLE/SKILL.md"
  cp "$SCRIPT_DIR/skill/agents/openai.yaml" "$EXAMPLE/agents/openai.yaml"
  echo "created: .agents/skills/$SKILL_PREFIX-example (example skill)"
  SKILL_DIRS=("$EXAMPLE/")
fi

CLAUDE_SKILLS="$PROJECT_ROOT/.claude/skills"
if [[ -L "$CLAUDE_SKILLS" ]]; then
  echo "skip: .claude/skills is already a symlink"
elif [[ -d "$CLAUDE_SKILLS" ]]; then
  # A real .claude/skills directory predates this layout. Link each skill
  # into it instead of replacing the directory.
  echo "note: .claude/skills is a real directory; linking skills one by one"
  for dir in "${SKILL_DIRS[@]}"; do
    name="$(basename "$dir")"
    link="$CLAUDE_SKILLS/$name"
    if [[ -L "$link" ]]; then
      echo "skip: .claude/skills/$name already linked"
    elif [[ -e "$link" ]]; then
      echo "skip: .claude/skills/$name exists and is not a symlink, not touching"
    else
      ln -s "../../.agents/skills/$name" "$link"
      echo "linked: .claude/skills/$name -> ../../.agents/skills/$name"
    fi
  done
else
  mkdir -p "$PROJECT_ROOT/.claude"
  ln -s ../.agents/skills "$CLAUDE_SKILLS"
  echo "created: .claude/skills -> ../.agents/skills (symlink)"
fi

# --- .gitignore ----------------------------------------------------------------
GITIGNORE="$PROJECT_ROOT/.gitignore"
touch "$GITIGNORE"
# Appending to a file without a final newline would join two lines.
if [[ -s "$GITIGNORE" && "$(tail -c 1 "$GITIGNORE")" != "" ]]; then
  echo >> "$GITIGNORE"
fi

if grep -qxF "CLAUDE.local.md" "$GITIGNORE"; then
  echo "skip: CLAUDE.local.md already in .gitignore"
else
  echo "CLAUDE.local.md" >> "$GITIGNORE"
  echo "added: CLAUDE.local.md to .gitignore"
fi

# Skills whose names do not start with "<prefix>-" are personal or
# third-party installs, so only the repo's own skills are committed. The
# hyphen stops a short prefix such as "wf" from also keeping "workflow". The
# .claude/skills lines only matter when .claude/skills is a real directory.
if grep -qxF ".agents/skills/*" "$GITIGNORE"; then
  echo "skip: skill ignore rules already in .gitignore"
else
  cat >> "$GITIGNORE" << EOF
# Commit only agent skills whose names start with "$SKILL_PREFIX-".
.agents/skills/*
!.agents/skills/$SKILL_PREFIX-*
.claude/skills/*
!.claude/skills/$SKILL_PREFIX-*
EOF
  echo "added: skill ignore rules to .gitignore (keeps $SKILL_PREFIX-* skills)"
fi

echo
echo "done. Next: fill in AGENTS.md, or ask an agent to. Don't use Claude's"
echo "/init for this: it writes to CLAUDE.md, which Codex never reads."
