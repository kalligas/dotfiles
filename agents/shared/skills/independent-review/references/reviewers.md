# Reviewer detection and invocation

Run `scripts/detect_reviewers.sh` by absolute path from the repository under
review. The script prints each installed CLI and its path. Installation does
not prove that a CLI is authenticated or that the selected model is available.
Treat an authentication failure, a rate-limit error, a timeout, or an empty
response as an incomplete lens, rather than as a pass with no findings. Use the
next available reviewer when the selected CLI cannot complete a lens.

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

The directory holds everything the run produces:

- `state`: one `NAME=hash` line per snapshot (`START`, `PRE_1`, `POST_1`, and
  so on). Shell variables do not survive between an agent's tool calls, so
  every command that needs a hash reads the file back with
  `. "$review_dir/state"`.
- `change.diff` and `change.stat`: the change under review, written in
  Step 1. A reviewer without a shell reads the change from these files.
- `fix-<round>.diff`: the fix diff of each round, written in Step 5.
- `process.md`: one line per problem with the review process itself, with its
  evidence, written as the problem happens. The orchestrator reads it after
  the final report to decide whether to offer an improvement to the skill.
- `<name>.prompt.md`, `<name>.out.md`, `<name>.err.log`: the filled prompt, the
  review, and the error output of each reviewer. `<name>.status` exists only
  when the reviewer failed, and names the reason.

Fill one prompt from `reviewer-prompt.md` per lens with
`scripts/fill_prompt.py`, using a different name for each reviewer, for
example `spec-compliance`. Use absolute paths in the prompt. Background
independent processes with `&` when parallel execution is available, then
`wait` for every PID and inspect every exit status. Keep failed runs separate
from completed reviews.

The snapshot script uses a temporary Git index and the existing Git identity.
The snapshot script writes Git objects but leaves refs, the real index, and
working files unchanged. The snapshot includes untracked files allowed by Git's
ignore rules, and staged files that are ignored. Ignored, untracked files stay
excluded. Snapshot commits have no refs and may later be garbage-collected;
use the hashes within the current review. The snapshot records a submodule's
checked-out commit, rather than uncommitted files inside the submodule. Review
dirty submodules in their own repositories. A sparse checkout limits which
working files exist locally; use a full checkout for full repository access.

## The runner script

`scripts/run_reviewer.sh` starts one reviewer with the invocation below for
its CLI:

```sh
<skill-dir>/scripts/run_reviewer.sh <codex|claude> <repo> "$review_dir" <name> [<related-repo> ...]
```

The script reads `<name>.prompt.md` and writes `<name>.out.md` and
`<name>.err.log`. It exits non-zero and writes `<name>.status` when the review
is empty, when the review starts with `REVIEW INCOMPLETE`, or when the error
log shows a rate limit. The reviewer prompts ask a reviewer that could not
read the change to start its answer with `REVIEW INCOMPLETE`. For a Codex run,
the status also names the first `codex_core::tools::router` error from the
error log. Chain a fallback reviewer for the same lens with `||`:

```sh
run_reviewer.sh codex "$repo" "$review_dir" security \
  || run_reviewer.sh claude "$repo" "$review_dir" security
```

## Claude Code

Give a Claude reviewer no shell. Measured on Claude Code 2.1.301 with a
`PreToolUse` hook that rewrites shell commands (rtk):

- With `--permission-mode plan`, a `Bash(git log *)` allow rule did not
  restrict the shell: `databricks --version` also ran. Plan mode also adds
  instructions about a plan file and ExitPlanMode, which reviewers then
  discuss in their reports.
- With `--permission-mode dontAsk` or `manual`, every shell command was
  denied, including allowed ones, because the hook changes `git log ...` to
  `rtk git log ...` before the allow rules are matched.

A reviewer with only Read, Grep, and Glob reads the change from
`change.diff` and searches the repository, and cannot run any command:

```sh
claude --print --no-session-persistence --output-format text \
  --permission-mode dontAsk \
  --tools 'Read,Grep,Glob' \
  --add-dir "$review_dir" [--add-dir <related-repo> ...] \
  --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
  < "$review_dir/spec-compliance.prompt.md" \
  > "$review_dir/spec-compliance.out.md" \
  2> "$review_dir/spec-compliance.err.log"
```

Run the command from the repository root. `dontAsk` denies every tool use
that would otherwise prompt, so the reviewer can neither write files nor run
commands. `--add-dir` gives read access to the review directory and to each
related repository. Check `claude --help` when an installed version rejects a
flag.

## Codex

```sh
codex exec --sandbox read-only --ephemeral --color never \
  -C "$repo" \
  --output-last-message "$review_dir/spec-compliance.out.md" \
  - < "$review_dir/spec-compliance.prompt.md" \
  > "$review_dir/spec-compliance.events.log" \
  2> "$review_dir/spec-compliance.err.log"
```

The filesystem sandbox enforces read-only access, and still lets Codex read
related repositories by absolute path. The output file is outside the
repository and is written by the CLI. Do not use approval or sandbox bypass
flags. Check `codex exec --help` when an installed version rejects a flag.
Use the final message as the review result, and inspect logs for failures or
denied reads.

Run at most one Codex process at a time. Two Codex reviewers started together
both failed with `429 Too Many Requests` and `exceeded retry limit` in their
error logs, while single runs succeeded (codex-cli 0.153.4). A failed run
leaves the `--output-last-message` file missing or empty.

A Codex run can also fail inside its tools and still write an answer. In one
run, every tool call of a single Codex reviewer failed with
`ERROR codex_core::tools::router: error=timed out negotiating with the
code-mode host`, three times in a row. The reviewer then wrote a 400-byte
"Review incomplete" answer, which `run_reviewer.sh` now marks as failed.

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
`run_reviewer.sh` does not start Gemini; run the command above directly.

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
