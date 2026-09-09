# dotagents

Machine-level configuration for two coding agents — Claude Code and Codex —
kept in one place and symlinked into `~/.claude` and `~/.codex`. Lives inside
the existing [`dotfiles`](../) repo rather than as a separate repo, since
that repo is already the symlink-managed source of truth for this machine.

## Layout

```
agents/
├── install.sh              # links this repo into ~/.claude and ~/.codex
├── shared/
│   ├── AGENTS.md            # THE global instruction file, for both tools
│   └── skills/               # skills usable by both tools, one dir each
├── claude/
│   ├── settings.json         # -> ~/.claude/settings.json
│   ├── rules/                 # -> ~/.claude/rules (Claude-only, path-scoped)
│   └── agents/                 # -> ~/.claude/agents (Claude subagents)
├── codex/
│   ├── config.toml           # NOT linked — see "Codex config.toml" below
│   └── prompts/               # NOT linked — see "Codex prompts" below
└── templates/
    ├── AGENTS.md.tmpl        # starter for a new project's AGENTS.md
    └── init-project.sh        # scaffolds AGENTS.md/CLAUDE.md/skills in a repo
```

## Machine scope vs. project scope

- **Machine scope** (`shared/AGENTS.md`): working agreements, safety rails,
  tool preferences, universal habits — things true of *you*, regardless of
  what repo you're in. This is what `install.sh` wires up.
- **Project scope** (a project's own `AGENTS.md`): facts specific to that
  codebase — its conventions, its "don't touch this", its build/test
  commands. Created per-project with `templates/init-project.sh`, never here.

Codex and Claude Code both layer instructions: the project file adds to (or,
for Codex, can be silenced by — see below) the global one. Keep the global
file lean; put everything project-specific in the project.

## How the two tools read this

| Tool        | Reads                  | Points at                       |
|-------------|-------------------------|----------------------------------|
| Codex       | `~/.codex/AGENTS.md`    | `shared/AGENTS.md` (symlink)     |
| Claude Code | `~/.claude/CLAUDE.md`   | `shared/AGENTS.md` (symlink by default; see Cowork note) |
| Claude Code | `~/.claude/settings.json` | `claude/settings.json` (symlink) |
| Claude Code | `~/.claude/rules/`      | `claude/rules/` (symlink)        |
| Claude Code | `~/.claude/agents/`     | `claude/agents/` (symlink)       |
| Both        | `~/.claude/skills/<name>`, `<codex skills dir>/<name>` | `shared/skills/<name>/` (symlink, one per skill) |

There is one file, `shared/AGENTS.md` — edit it in the repo, both tools pick
up the change immediately (or after a re-run, in copy mode; see below).

## Bootstrapping a fresh machine

```bash
cd ~/dotfiles/agents   # or wherever this ends up cloned
./install.sh
```

Re-running is safe — it's idempotent. Anything it would replace is moved to
`~/.agent-config-backup/<timestamp>/` first, and it prints a summary of what
it linked, copied, backed up, and skipped.

Add `--copy-claude-md` if you use Cowork for coding work (see below).

## Adding a new shared skill

```bash
mkdir -p shared/skills/my-skill
# add my-skill/SKILL.md, etc.
./install.sh
```

`install.sh` links each skill directory individually into both tools' skill
directories — never the whole `skills/` directory, because both tools write
their own entries into it at runtime (`~/.codex/skills/.system/` is Codex's
bundled-skills directory; `~/.claude/skills/synced/` is Claude Code's own
sync target). Linking the parent would either clobber those or nest oddly on
a re-run.

## Codex config.toml

`codex/config.toml` exists in this repo tree but is **gitignored and never
linked**. `~/.codex/config.toml` stays a real local file, untouched by
`install.sh`.

Reason: on this machine it's rewritten continuously by the ChatGPT desktop
app — `[projects."..."] trust_level` entries as you trust folders, NUX/UI
state, and absolute machine-specific paths (`~/.codex/.tmp/...`,
`~/.cache/codex-runtimes/...`, `/Applications/ChatGPT.app/...`). Tracking it
would mean constant unrelated diffs and paths that wouldn't hold on another
machine. If you want a portable reference for what a fresh Codex setup
looked like, hand-curate a subset (model, personality, reasoning effort)
into `codex/config.toml` as documentation — it will never be linked or
overwrite the live file.

## Codex prompts

`codex/prompts/` exists in this tree for parity with the original design but
is **not linked by `install.sh`**. Codex 0.153.4 (the version on this
machine at setup time) has no custom-prompts-directory feature — that role
is served by skills/plugins instead. If a future Codex version adds one,
wire it up then.

## Cowork copy-mode caveat

Cowork (the general-purpose surface in the Claude desktop app, distinct from
the Code tab / CLI / IDE extensions) skips a `~/.claude/CLAUDE.md` that is
itself a symlink, and skips a symlinked `~/.claude/rules` pointing outside
the current working directory. If you use Cowork for real coding work, run:

```bash
./install.sh --copy-claude-md
```

This writes `~/.claude/CLAUDE.md` as a real file instead of a symlink.
**You must re-run `./install.sh --copy-claude-md` after editing
`shared/AGENTS.md`** for the change to reach Claude Code — the copy does not
update itself. Re-running is safe: it only rewrites the copy when the
content has actually drifted, and backs up anything it replaces.

This machine is currently set up in **symlink mode** (default) — instant
updates, no re-run needed — because Cowork was reported as not the primary
surface for coding work here. If that changes, switch with the flag above.

## Project scaffolding

From a project's repo root:

```bash
/path/to/dotagents/templates/init-project.sh              # CLAUDE.md as symlink
/path/to/dotagents/templates/init-project.sh --import      # CLAUDE.md as real
                                                              file with @AGENTS.md
```

It creates `AGENTS.md` from the template (never clobbers an existing one),
creates `CLAUDE.md`, sets up `.agents/skills/` + `.claude/skills/` with
per-skill symlinks, and adds `CLAUDE.local.md` to `.gitignore`. It also warns
if it finds an `AGENTS.override.md` at the repo root: Codex reads at most
one instruction file per directory and prefers the override, so an override
at root **silences** the committed `AGENTS.md` for Codex rather than adding
to it — likely not what you want if `AGENTS.md` also has real content.

Use `--import` for repos with Windows contributors (who may not handle the
symlink the same way) or when you need Claude-specific instructions that
don't belong in the shared `AGENTS.md`.

## What this repo will never touch

`install.sh` refuses to create, modify, or back up these paths, on either
tool's side — they hold credentials or session state, not configuration:

```
~/.claude.json
~/.claude/projects/
~/.claude/todos/
~/.claude/shell-snapshots/
~/.claude/statsig/
~/.claude/history.jsonl
~/.codex/auth.json
~/.codex/sessions/
~/.codex/history.jsonl
~/.codex/logs/
~/.codex/config.toml   (see "Codex config.toml" above)
```

The `.gitignore` lists the same set as a belt-and-braces measure in case any
of it ever ends up under this directory tree by accident.
