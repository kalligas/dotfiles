# Reviewer detection and invocation

Run `scripts/detect_reviewers.sh` by absolute path from the repository under
review. The script prints each installed CLI and its path. Installation does
not prove that a CLI is authenticated or that the selected model is available.
Treat an authentication failure, a timeout, or an empty response as an
incomplete lens, rather than as a pass with no findings. Use the next available
reviewer when the selected CLI cannot complete a lens.

Choose a different vendor first: Claude or Gemini for a Codex orchestrator,
and Codex or Gemini for a Claude orchestrator. Use existing model settings
unless the user or project instructions choose a model. Start a new process
for every lens. Do not resume a session or give a reviewer the implementation
conversation. Supply the criteria and the ledger because both define scope.

## Temporary files and repository access

Create a temporary directory outside the repository:

```sh
review_dir=$(mktemp -d "${TMPDIR:-/tmp}/independent-review.XXXXXX")
```

Fill in one prompt from `reviewer-prompt.md` per lens, and save each prompt in
that directory, for example `$review_dir/spec-compliance.prompt.md`. Use the
absolute repository path in the prompt. Run commands below from the repository
root, with a different output basename for each reviewer. Background independent
processes with `&` when parallel execution is available, then `wait` for every
PID and inspect every exit status. Keep failed runs separate from completed
reviews.

The snapshot script uses a temporary Git index and the existing Git identity.
The snapshot script writes Git objects but leaves refs, the real index, and
working files unchanged. The snapshot includes untracked files allowed by Git's
ignore rules, and staged files that are ignored. Ignored, untracked files stay
excluded. Snapshot commits have no refs and may later be garbage-collected;
use the hashes within the current review. The snapshot records a submodule's
checked-out commit, rather than uncommitted files inside the submodule. Review
dirty submodules in their own repositories. A sparse checkout limits which
working files exist locally; use a full checkout for full repository access.

## Claude Code

For a CLI that supports `--tools`, restrict the available tools as well as the
allowed commands. `--allowedTools` alone does not remove other tools.

```sh
claude --print --no-session-persistence --output-format text \
  --permission-mode plan \
  --tools 'Read,Grep,Glob,Bash' \
  --allowedTools 'Read' 'Grep' 'Glob' \
    'Bash(git diff *)' 'Bash(git show *)' 'Bash(git ls-files *)' \
    'Bash(git log *)' 'Bash(rg *)' \
  --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
  < "$review_dir/spec-compliance.prompt.md" \
  > "$review_dir/spec-compliance.out.md" \
  2> "$review_dir/spec-compliance.err.log"
```

The prompt prohibits edits and commits. Read tools can inspect the repository;
the approved shell commands inspect diffs and callers. Do not enable tools that
write files or grant broader shell access to make a review succeed. Project
hooks and local settings may still run; if those can mutate the repository,
use a read-only filesystem sandbox or another reviewer. Check `claude --help`
when an installed version rejects a flag.

## Codex

```sh
codex exec --sandbox read-only --ephemeral --color never \
  --output-last-message "$review_dir/spec-compliance.out.md" \
  - < "$review_dir/spec-compliance.prompt.md" \
  > "$review_dir/spec-compliance.events.log" \
  2> "$review_dir/spec-compliance.err.log"
```

The filesystem sandbox enforces read-only repository access. The output file
is outside the repository and is written by the CLI. Do not use approval or
sandbox bypass flags. Check `codex exec --help` when an installed version
rejects a flag. Use the final message as the review result, and inspect logs
for failures or denied reads.

## Gemini

Gemini CLI versions differ in sandbox and tool controls. Inspect
`gemini --help` before choosing the invocation. For versions that provide
`--approval-mode plan`, `--sandbox`, `--prompt`, and `--output-format`:

```sh
gemini --approval-mode plan --sandbox --output-format text \
  --prompt "$(cat "$review_dir/spec-compliance.prompt.md")" \
  > "$review_dir/spec-compliance.out.md" \
  2> "$review_dir/spec-compliance.err.log"
```

Shell command substitution here passes the prompt as one quoted argument;
the shell does not execute text inside the prompt. Plan mode must deny writes
and mutating tools in the installed version. A sandbox alone may permit writes
inside the workspace. If the version cannot enforce read-only review, use
another CLI or a fresh-context subagent instead of enabling automatic approval.

## Fresh-context subagents and self-review

When no usable CLI is available, give each subagent a fresh context, the filled
prompt, and read access to the whole repository. For a harness with
`fork_turns`, choose `none`. For any other harness, use the equivalent setting
that omits the implementation conversation. Tell every reviewer to return
findings only and to leave fixes to the orchestrator.

If independent processes and fresh-context subagents are unavailable, use the
same prompt for each lens in the current session. Label the report
`self-review, not independent`, and report which lenses were actually checked.
Never count a failed CLI invocation as a completed review.
