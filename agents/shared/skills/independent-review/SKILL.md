---
name: independent-review
description: Run a bounded, independent, multi-lens code review of a finished code change, verify each finding against the code, fix the confirmed findings in one batch, check only the fixes, and stop by a rule fixed in advance. Use this skill whenever the user asks for an independent review, a second opinion, a review pass, or to "review this change / diff / branch / PR", and whenever an agent has just finished implementing a code change and the user wants it checked, even if the user does not name this skill. Also use when the user says each review round keeps surfacing new findings. Do not use for reviewing prose, for designing a change that has not been written yet, or for one-line edits.
compatibility: Agent-agnostic. Requires git and a POSIX shell. Uses an installed agent CLI (codex, claude, gemini) as the reviewer when one is available, and falls back to fresh-context subagents, then to a clearly labelled self-review.
metadata:
  short-description: Bounded independent code review with a stopping rule fixed in advance
---

# Independent review

An open-ended code review never runs out of findings. A single review pass
reports only a sample of the candidate problems in a change, so every new pass
draws a different sample, and every fix adds new code that no reviewer has seen.
This skill therefore fixes the number of passes before any results are visible,
splits the review into focused lenses, verifies findings before acting on them,
fixes confirmed findings in one batch, and then reviews only the fixes.

Paths such as `scripts/snapshot.sh` are relative to the directory that
contains this SKILL.md file; call the scripts by absolute path from inside the
repository under review.

## Terms

- **Change**: the diff between a base commit and the current working tree,
  including uncommitted and untracked files. The change is the only code under
  review.
- **Orchestrator**: the agent running this skill. The orchestrator plans the
  review, runs the reviewers, verifies findings, and applies fixes.
- **Reviewer**: a separate agent process that has no memory of how the change
  was written. Example: `codex exec` started by a Claude-based orchestrator.
- **Lens**: one review focus, such as "failure paths". Each reviewer receives
  exactly one lens.
- **Finding**: one claimed defect, with a location, a triggering scenario, a
  severity, and the intended behavior after a fix.
- **Severity**: `blocking` means the change violates an acceptance criterion,
  loses or corrupts data, opens a security hole, or breaks existing callers.
  `major` means incorrect behavior in a realistic but less common scenario.
  `minor` means a defect with small impact, such as a misleading error message.
  Style preferences are not findings unless a project instruction file requires
  the style.
- **Confidence**: a 0–100 score that the orchestrator assigns after checking a
  finding against the code. The scale is defined in Step 4.
- **Ledger**: a list, kept only in the current session, of every finding already
  decided, with the decision (fixed, rejected, pre-existing, escalated) and a
  one-line reason. Never write the ledger into the repository.
- **Fix diff**: the diff between the working tree before a batch of fixes and
  the working tree after the batch.
- **Round**: one batch of fixes followed by one verification pass over the fix
  diff.

## Limits fixed before Step 1

Record these limits at the start and do not change them during the run:

- Initial review: 2 to 4 lenses, one reviewer per lens.
- Fix rounds: at most 2.
- Auto-fix threshold: confidence 80 or higher.

The limits are fixed in advance because a stopping decision made after seeing
results always finds a reason for one more pass: every pass reports something
new.

## Step 1: Establish scope and acceptance criteria

1. Determine the base commit. Use the base the user names. Otherwise use
   `git merge-base HEAD <default-branch>`. Then record the change as a
   snapshot: `START=$(<skill-dir>/scripts/snapshot.sh)`. Reviewers read the
   change with `git diff <base> $START`, which includes untracked files that
   plain `git diff <base>` omits. Record `git diff --stat <base> $START`.
2. Collect acceptance criteria from the user's task, the issue or pull request
   description, spec files, and tests. If no written criteria exist, write 3 to
   7 criteria from the stated intent of the change and show the criteria to the
   user before continuing. A reviewer with criteria judges whether the change
   does what was asked; a reviewer without criteria judges taste, and taste
   findings never run out.
3. Find the project instruction files (for example `AGENTS.md`, `CLAUDE.md`,
   `CONTRIBUTING.md`, linter and formatter configs). Reviewers check
   compliance against these files.
4. Run the objective checks for the touched code: tests, type checker, linter.
   Record each failure as a finding with confidence 100. Tests run before
   reviewers because tests are deterministic and cheaper than a model pass.
5. Check the size of the change. If the change exceeds roughly 400 changed
   lines or spans unrelated components, tell the user that the share of defects
   a single pass catches falls as the change grows, and propose one run of this
   skill per component. Continue with the whole change if the user prefers.

## Step 2: Choose the lenses

Pick 2 to 4 lenses from the table, based on what the change touches. Always
include `spec compliance`. Write the chosen lenses down before starting any
reviewer.

| Lens | Pick when the change touches | The reviewer looks for |
|---|---|---|
| spec compliance | always | each acceptance criterion met; behavior nobody asked for |
| correctness and edge cases | logic, parsing, arithmetic | boundary values, empty or null input, off-by-one, wrong branch |
| failure paths | I/O, network, external services | unhandled errors, partial writes, missing cleanup, unsafe retries |
| security | user input, auth, queries, file paths, secrets | injection, old code paths that bypass a new control, secrets in logs |
| concurrency and state | shared state, async code, caches, transactions | races, stale caches, non-atomic read-modify-write |
| data and migrations | schemas, SQL, ETL, serialization | backward compatibility, nulls, idempotency, safe re-runs |
| callers and regressions | changed signatures or behavior used elsewhere | call sites not updated, changed behavior for existing callers |
| tests | added or changed tests | tests that cannot fail, new branches with no test |

Different lenses overlap less than repeated runs of the same prompt, so four
different lenses surface more distinct defects than four identical passes.

## Step 3: Run the reviewers

Read `references/reviewers.md` for detection and exact invocation, and run
`scripts/detect_reviewers.sh` to list the installed CLIs.

Choose reviewers in this order of preference:

1. An agent CLI from a different vendor than the orchestrator. A different
   model has different blind spots, while a model reviewing output from the
   same model tends to share the assumptions that produced the defect.
2. An agent CLI from the same vendor, started as a fresh process.
3. A subagent with a fresh context, through whatever subagent mechanism the
   harness provides.
4. If none of the above is available: review each lens in the current session,
   starting from the diff rather than from the memory of writing the change.
   Label the final report "self-review, not independent".

Assign one lens per reviewer. When several reviewer types are available, give
the highest-risk lenses (usually `spec compliance` and `security`) to the
reviewer from a different vendor.

Give every reviewer the initial-review prompt from
`references/reviewer-prompt.md`, filled in with the base commit, the `START` snapshot, the acceptance
criteria, the single lens, the instruction-file paths, and the current ledger.
Reviewers run read-only and with read access to the whole repository. Full
repository access matters: in a published experiment, false positives that
appeared in every pass with only the changed file visible disappeared once
reviewers could read the rest of the repository.

Run reviewers in parallel when the harness allows. Save each reviewer's output
to a temporary directory outside the repository.

## Step 4: Pool, deduplicate, and verify

1. Merge all findings into one list. Two findings are duplicates when the two
   findings share a root cause, even if the wording or the suggested fix
   differs. Keep the most specific wording and note which lenses reported the
   finding.
2. Do not rank findings by how many reviewers reported them. A false positive
   caused by missing context recurs in every pass, so repetition measures how
   easy a finding is to reach, not whether the defect exists.
3. Drop findings that match a ledger entry, unless the reviewer gives evidence
   the ledger entry did not consider. Note the drop in the report.
4. Verify each remaining finding: open the cited code, trace the scenario
   step by step, look for a guard or initialization elsewhere in the
   repository, and check whether an existing test covers the scenario. When a
   failing test is cheap to write, write the test: a failing test is the
   strongest evidence and stays as a regression test after the fix.
5. Assign a confidence score:
   - 100: reproduced by a failing test or a run.
   - 80–99: traced concretely through the code, and no guard exists.
   - 50–79: plausible, but depends on inputs or usage the orchestrator could not
     confirm.
   - below 50: contradicted by the code, or speculative.
6. Mark a finding `pre-existing` when the finding concerns code the change did
   not touch and the change does not make the defect worse. Pre-existing
   findings are reported, not fixed, because fixing untouched code widens the
   change and restarts the review.
7. Add every rejected (below 50) and pre-existing finding to the ledger with a
   one-line reason.

## Step 5: Fix in one batch

1. Record the pre-fix state: `PRE=$(<skill-dir>/scripts/snapshot.sh)`. The snapshot script
   stores the working tree, including untracked files, as a commit object
   without touching the branch, the index, or the working tree.
2. Fix every in-scope finding with confidence 80 or higher, at any severity,
   in one batch. Fixing in one batch means the verification pass sees all fix
   code together, instead of each round reviewing code written to silence the
   previous round.
3. Escalate a finding to the user instead of fixing it when the fix requires a
   decision the acceptance criteria do not settle. Examples: two valid
   behaviors exist (for a request containing a forbidden field, return an error
   or silently drop the field), a public API or stored data format would
   change, or existing callers rely on the current behavior.
4. When reviewers propose different fixes for the same finding, choose one
   behavior, state the chosen behavior in one sentence in the ledger entry, and
   implement exactly that behavior. A single explicit behavior prevents a fix
   that half-satisfies several reviewers and fully satisfies none.
5. Fix the cause of each defect. Do not add a defensive check at the reported
   line when the defect originates elsewhere: a defensive check silences the
   finding, grows the code, and is itself unreviewed code.
6. Add each fixed finding to the ledger with the files changed.
7. Re-run the objective checks from Step 1.
8. Record the post-fix state: `POST=$(<skill-dir>/scripts/snapshot.sh)`. The fix diff is
   `git diff $PRE $POST`.

## Step 6: Verify the fixes only

1. Measure the fix diff with `git diff --shortstat $PRE $POST`.
2. If the fix diff is at most 150 changed lines and at most 30% of the original
   change, run one reviewer with the verification prompt from
   `references/reviewer-prompt.md`. The verification prompt asks two questions
   only: whether each fixed finding is resolved, and whether the fix diff
   introduces a defect. Findings about code outside the fix diff are out of
   scope for the verification pass. Prefer the reviewer from a different
   vendor.
3. If the fix diff is larger, the fixes are new code rather than a repair: run
   Step 3 on the fix diff with the 1 or 2 lenses closest to the fixed findings.
   The larger review still counts as the verification pass of the current
   round.
4. Verify the returned findings as in Step 4.

## Step 7: Stop, continue, or escalate

- **Stop** when the verification pass returns no finding with confidence 80 or
  higher inside the fix diff.
- **Continue** to a second round (Steps 5 and 6) only for verified findings
  inside the fix diff.
- **Escalate** to the user, without further fixing, when any of these hold:
  - the round limit is reached and verified findings remain;
  - the number of blocking findings did not strictly decrease from the
    previous round;
  - a finding recorded as fixed is reported again with evidence that the fix
    did not work;
  - reviewers disagree about what the intended behavior is.

A count of blocking findings that stays flat or grows means the loop is not
converging, which usually points to a design question that more fixing cannot
answer.

Never start a fresh, open-ended review of the whole change because the
previous pass found something new. Never report "the reviewer found nothing"
as proof of correctness; report the result as "no findings in this pass" and
list what the reviewer checked.

## Final report

Use this structure:

```
## Independent review: <base>..<HEAD or working tree>

Scope: <files> files, +<added>/-<removed> lines. Criteria: <count> (<source>).
Lenses: <lens> (<reviewer>), ...
Objective checks: <tests / types / lint, pass or fail>
Rounds: <n> of 2. Stop reason: <one sentence>

### Fixed (<n>)
- [<severity>] <path:line>: <problem>. Fix: <behavior after fix>. Evidence: <test name, or trace>.

### Needs your decision (<n>)
- [<severity>] <path:line>: <problem>. Options: <A> / <B>. Trade-off: <one sentence>.

### Not fixed: confidence 50-79 (<n>)
- <path:line>: <problem>. Unconfirmed because: <reason>.

### Rejected (<n>)
- <problem>: <reason, one line>.

### Pre-existing, outside the change (<n>)
- <path:line>: <problem>.

### Not covered
- Lenses not run: <list>.
- Not assessed by this review: design fit, naming, and whether the change matches intent that is not written in the criteria.
```

The "Not covered" section exists because automated review measures only
defects a reviewer can point to in code. Design fit, naming, and unwritten
intent remain the user's judgment.
