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
├── ../.claude-plugin/       # Claude Chat marketplace manifest (repo root)
├── ../claude/plugins/       # Claude Chat plugin manifest and skill link
├── claude/
│   ├── settings.json         # -> ~/.claude/settings.json
│   ├── rules/                 # -> ~/.claude/rules (Claude-only, path-scoped)
│   └── agents/                 # -> ~/.claude/agents (Claude subagents)
└── templates/
    ├── AGENTS.md.tmpl        # starter for a new project's AGENTS.md
    ├── skill/                 # example project skill copied into new repos
    └── init-project.sh        # scaffolds AGENTS.md/CLAUDE.md/skills in a repo
```

## Machine scope vs. project scope

- **Machine scope** (`shared/AGENTS.md`): personal preferences that apply
  in every repo and that the agents would not follow by default, such as
  tool choices and writing style. Leave out rules the tools already follow
  on their own. This is what `install.sh` wires up.
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
| Claude Code | `~/.claude/skills/<name>` | `shared/skills/<name>/` (symlink, one per skill) |
| Codex       | `~/.agents/skills/<name>` | `shared/skills/<name>/` (symlink, one per skill) |

There is one file, `shared/AGENTS.md` — edit it in the repo, both tools pick
up the change immediately (or after a re-run, in copy mode; see below).

## Bootstrapping a fresh machine

On macOS, the repository's top-level `bootstrap.sh` runs this installer after
the first successful nix-darwin switch. To re-run it manually, or to activate
new shared skills later:

```bash
cd ~/dotfiles/agents   # or wherever this ends up cloned
./install.sh
```

Re-running is safe — it's idempotent. Anything it would replace is moved to
`~/.agent-config-backup/<timestamp>/` first, and it prints a summary of what
it linked, copied, backed up, and skipped.

Add `--copy-claude-md` if you use Cowork for coding work (see below).

## Claude Chat marketplace

The repository root is also a Claude Chat marketplace. Its `my-skills` plugin
manifest is under `claude/plugins/my-skills/`, and that plugin's `skills/`
directory is a symlink to `shared/skills/`. This keeps Claude Chat, Claude
Code, and Codex on the same skill source of truth.

From Claude Chat, use **Customize → Plugins → Add Marketplace → Add from a
Repository** and select this repository. To validate the marketplace locally,
run `claude plugin validate .` from the repository root.

## Adding a new shared skill

```bash
mkdir -p shared/skills/my-skill
# add my-skill/SKILL.md, etc.
./install.sh
```

`install.sh` links each skill directory individually into both tools' skill
directories (`~/.agents/skills/` for Codex and `~/.claude/skills/` for Claude
Code). It never links either parent directory, because those locations may
also contain skills installed by other sources. Linking the parent would
clobber those or nest oddly on a re-run.

## Codex config.toml

The repository does not manage a Codex `config.toml`. The live
`~/.codex/config.toml` stays a real local file, untouched by `install.sh`.

Reason: on this machine it's rewritten continuously by the ChatGPT desktop
app — `[projects."..."] trust_level` entries as you trust folders, NUX/UI
state, and absolute machine-specific paths (`~/.codex/.tmp/...`,
`~/.cache/codex-runtimes/...`, `/Applications/ChatGPT.app/...`). Tracking it
would mean constant unrelated diffs and paths that wouldn't hold on another
machine. Keep portable behavior in shared instructions or skills rather than
copying this machine-specific file into the repository.

## Codex prompts

No Codex prompts directory is managed here. Reusable workflows belong in
skills or plugins instead, avoiding documentation tied to a particular Codex
version.

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
updates, no re-run needed — because Cowork was reported as not the primary## Project scaffolding

From a project's Git repository root:

```bash
~/dotfiles/agents/templates/init-project.sh
```

Pass `--import` to make `CLAUDE.md` a file that imports `AGENTS.md` instead
of a symlink to it. Pass `--prefix <name>` to choose the skill prefix,
for example `--prefix wf` in `wikifarmer-agents` for skills named
`wf-<topic>`. The script never overwrites an existing file, so
re-running it is safe. It exits without changing anything when run outside a
Git repository or from a directory below its root.

The script creates these files:

- `AGENTS.md`, from `templates/AGENTS.md.tmpl`. The template asks for
  commands, how to verify a change, deliberate decisions, and files not to
  touch, because an agent cannot work those out from the code.
- `CLAUDE.md`, a symlink to `AGENTS.md`. Claude Code reads `AGENTS.md`
  without help only from v2.1.277, so older versions need this file.
  Claude's Edit and Write tools refuse to write through the symlink and edit
  `AGENTS.md` instead. With `--import`, `CLAUDE.md` is a real file containing
  `@AGENTS.md`, which loads `AGENTS.md` in full and leaves room for
  Claude-only instructions below that line. Use `--import` when a
  contributor works on Windows without symlink support, because Git then
  checks the symlink out as a one-line text file. The `.claude/skills`
  symlink has the same limitation.
- `.agents/skills/<prefix>-example/`, an example skill copied from
  `templates/skill/`, when the repo has no skills yet. The example sets
  `disable-model-invocation: true` for Claude Code and
  `policy.allow_implicit_invocation: false` in `agents/openai.yaml` for
  Codex, so neither agent runs it unless asked by name.
- `.claude/skills`, a symlink to `../.agents/skills`. Codex reads
  `.agents/skills/` and Claude Code reads `.claude/skills/`, so the symlink
  lets both load the same skills, including skills added later. When
  `.claude/skills` is already a real directory, the script links each skill
  into it instead, and skills added later need another run.
- `.gitignore` entries for `CLAUDE.local.md` and for every skill whose name
  does not start with `<prefix>-`. With the prefix `ep`,
  `.agents/skills/ep-backfill/` is committed and `.agents/skills/pdf/` is
  ignored. The rule keeps personal and third-party skills out of version
  control. The hyphen stops a short prefix such as `wf` from also keeping a
  third-party skill named `workflow`.

Without `--prefix`, `<prefix>` is the repository directory name in
lowercase, with every character other than letters, digits, and hyphens
replaced by a hyphen, because skill names allow only those characters. A
prefix passed with `--prefix` must already follow those rules. Re-running
the script with a different prefix leaves an existing `.gitignore` rule
unchanged, so edit those lines by hand after a rename.

After scaffolding, fill in `AGENTS.md` by hand or ask an agent to. Claude's
`/init` command is the wrong tool for this step: `/init` writes to
`CLAUDE.md`, which Codex never reads.

A `CLAUDE.local.md` file (personal, uncommitted Claude instructions) stops
Claude Code v2.1.277 and later from reading `AGENTS.md` on its own. The
committed `CLAUDE.md` keeps `AGENTS.md` loaded in that case.

The script warns when it finds an `AGENTS.override.md` at the repo root.
Codex reads at most one instruction file per directory and prefers the
override, so an override at the root replaces the committed `AGENTS.md` for
Codex instead of adding to it.

d Claude-specific instructions that
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
