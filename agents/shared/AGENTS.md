# Global agent instructions

Machine-scope agreements for any coding agent (Claude Code, Codex) running as
me. Project-specific facts belong in that project's own AGENTS.md, not here.

## Working agreements

- Do the work; don't narrate a plan and stop unless you're genuinely blocked
  on a decision only I can make (ambiguous scope, destructive/irreversible
  action, missing credentials or input).
- If a request is ambiguous, make the call a careful colleague would make and
  say what you assumed, rather than opening with a question.
- When you finish, say plainly what's done, what you skipped, and why. No
  hedging, no over-qualifying.
- Prefer finishing the whole task over doing the easy 80% and stopping.

## Safety rails

- Never commit secrets, API keys, tokens, or credentials to any repo. Use
  environment variables or a secrets manager and reference them by name.
- Confirm before: force-pushing, rewriting history on a shared branch,
  deleting data, or any action that touches money or sends something to a
  real person/service on my behalf.
- Before a destructive git operation (checkout/reset/clean that can discard
  work), check `git status` first and stash or commit what's there.
- Don't add remotes or push unless I ask.

## Tool preferences

- TODO: preferred package manager(s) per language (npm vs pnpm/yarn, pip vs
  uv/poetry, etc).
- TODO: preferred test runner / how to run the test suite when not obvious.
- TODO: linter/formatter expectations (run before commit? auto-fix ok?).
- Prefer `rg`/`fd` over `grep -r`/`find` when available.
- Use the project's existing conventions (naming, comment density, structure)
  over introducing new ones, even if you'd personally do it differently.

## Universal habits

- Read a file before editing it. Don't guess at line numbers or content.
- Match commit message style to the repo's existing history.
- TODO: default git commit message sign-off / co-author line, if any, beyond
  what each tool already appends.
- When you hit something outside what you were asked to do (dead code, a bug,
  a missing test) and fixing it now would bloat the change, flag it rather
  than silently expanding scope or silently ignoring it.
- TODO: any topics/tools you never want an agent to touch without asking
  (e.g. specific production systems, specific cloud accounts).

## Notes

This file is the single source of truth for both tools:
- Codex reads it as `~/.codex/AGENTS.md`.
- Claude Code reads it as `~/.claude/CLAUDE.md`.
Both are symlinks back to this file — edit here, not at the symlink target.
