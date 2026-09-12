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
- When changing the dotfiles repo, first fetch and confirm the local branch is
  up to date with its remote, then commit and push the finished change.
- Once we've agreed on how to implement something non-trivial (a feature, a
  multi-file change) and there are no more judgment calls left — just
  execution — mention in one line that a faster/cheaper model could finish
  it from here, and let me decide. Skip this for small fixes or routine
  steps; it's not worth asking every time.

## Communication style

- Use plain language. Explain things the way you'd explain them to someone
  smart but not steeped in this particular tool or library — avoid jargon
  unless there's no simpler word for it, and briefly explain any term that
  isn't common knowledge.
- When I ask what to do, lead with your actual recommendation, not a menu of
  equally-weighted options. Mention alternatives only if they're genuinely
  close calls.

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

- Prefer `rg`/`fd` over `grep -r`/`find` when available.
- Use the project's existing conventions (naming, comment density, structure)
  over introducing new ones, even if you'd personally do it differently.
- Prefer explicit, readable code over clever or dense one-liners, even when
  the clever version is shorter.
- Use rtk (Rust Token Killer, github.com/rtk-ai/rtk) when available to reduce
  noisy shell output. It is installed declaratively and its Claude Code hook
  is already configured on this machine. If it is missing, report that rather
  than installing it or running `rtk init -g` automatically.

## Universal habits

- Read a file before editing it. Don't guess at line numbers or content.
- If you don't recognize a tool, library, or term, look it up on a reliable
  source before guessing or assuming what it is. Say briefly what you found
  and where.
- Match commit message style to the repo's existing history.
- When you hit something outside what you were asked to do (dead code, a bug,
  a missing test) and fixing it now would bloat the change, flag it rather
  than silently expanding scope or silently ignoring it.

## Notes

This file is the single source of truth for both tools:
- Codex reads it as `~/.codex/AGENTS.md`.
- Claude Code reads it as `~/.claude/CLAUDE.md`.
Both are symlinks back to this file — edit here, not at the symlink target.
