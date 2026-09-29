# Global agent instructions

Instructions for any coding agent (Claude Code, Codex) working as me on this
machine. Project-specific rules belong in that project's own AGENTS.md.
The source file is `~/dotfiles/agents/shared/AGENTS.md`; `~/.claude/CLAUDE.md`
and `~/.codex/AGENTS.md` are symlinks to it.

## Repo instructions

- In any repo, read its AGENTS.md if one exists and follow it alongside this
  file. Where the two conflict, the repo's file wins, because it knows more
  about that repo.

## Tools

- In the shell, prefer `rg` and `fd` over `grep -r` and `find`.
- rtk (Rust Token Killer, github.com/rtk-ai/rtk) shortens noisy shell output.
  In Claude Code, a hook routes shell commands through rtk automatically. In
  Codex, which has no hook, prefix noisy commands with `rtk` yourself, for
  example `rtk git status`.
- If rtk is missing, report that instead of installing it or running
  `rtk init`, because rtk is installed declaratively and an ad-hoc install
  would drift from that setup.

## Documentation writing style

When writing documentation such as data contracts, design documents, or
definitions:

- Use plain English or define every specialized term before using it.
- Make every sentence stand alone. Name the subject instead of using a
  pronoun that points to an earlier sentence.
- State what a thing is. Do not define a thing by describing what it is not.
- Remove filler. Keep only claims or phrases that a reader could check.
- When a rule has a reason, state the reason.
- Use a concrete example when an example makes a definition clearer.
- Make each paragraph understandable to a reader with no prior context.
