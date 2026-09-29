# Global agent instructions

Instructions for any coding agent (Claude Code, Codex) working as me on this
machine. Project-specific rules belong in that project's own AGENTS.md.
The source file is `~/dotfiles/agents/shared/AGENTS.md`; `~/.claude/CLAUDE.md`
and `~/.codex/AGENTS.md` are symlinks to it.

## Repo instructions

- In any repo, read its AGENTS.md if one exists and follow it alongside this
  file. Where the two conflict, the repo's file wins, because it knows more
  about that repo.

## Model choice

- On every prompt, judge whether the current model will do a good job on the
  request. If it will, continue without comment. If it will not, name a
  better-suited model with a one-line reason and stop until I confirm, unless
  I have already told you to continue anyway.
- If a faster, cheaper model would do the job just as well, for example once
  a non-trivial implementation is agreed and only execution remains, name it
  with a one-line reason and stop until I confirm, unless I have already
  told you to continue anyway. Skip this for small fixes, because switching
  models re-reads the whole conversation without the prompt cache and can
  cost more than finishing.

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
