# Scheduled agent tasks

This page records the scheduled agent tasks that keep Mike's Notion daily log
up to date, so the setup can be rebuilt on a new machine or account. The page
describes what each task does and how the tasks depend on each other. The
prompts themselves are not stored here, because the live copy of each prompt
is the one in the app that runs it. A private backup of every prompt is kept
in the Notion page "Scheduled task prompts" (see
[Prompt backup](#prompt-backup)).

## Terms

- **Scheduled task**: a prompt that an agent app runs on a timer without a
  person present. The Claude desktop app lists these under **Scheduled
  tasks**; the Codex app lists them under **Scheduled**.
- **Chat task**: a Claude scheduled task marked `Chat` in the app. A chat task
  runs in Claude's cloud with the account's connectors (Notion, Gmail, Slack,
  ClickUp and others) and cannot read files on this computer.
- **Local task**: a Claude scheduled task marked `Only on this computer`. A
  local task runs in Claude Code on this Mac, can read local files, and runs
  only while the Mac is awake and online. Claude Code stores a local task's
  prompt at `~/.claude/scheduled-tasks/<name>/SKILL.md`.
- **Scratchpad**: a Notion page that works as an inbox. The morning brief and
  chat takeaways are appended to it, and one task files those sections away
  every evening.
- **Daily database**: a Notion database with one page per filed item. Every
  page title has the form `<YYYYMMDD> - <Content>`, for example
  `20261103 - Recap`. The properties are `Day` (title), `Date`, `Topics`,
  `Status`, `Open action items`, `Chats covered` and `Action items`.
- **Topics**: a multi-select on the Daily database. New pages use ingestion,
  transformation, infrastructure, ci, agents, digest, analytics, invoices and
  other. The options databricks and notion stay only because older pages carry
  them; almost all work touches Databricks, so that option filtered nothing.
- **Recap page**: a Notion page that always holds the latest end-of-day recap.

## The tasks

Times are Europe/Athens.

| Task | App and kind | When | Reads | Writes |
|---|---|---|---|---|
| Daily briefing | Claude, chat | Weekdays 07:00 | Calendar, Gmail, Slack, ClickUp and GitHub items that mention Mike, recent Granola meetings | A morning brief section in the Scratchpad |
| Weekly LLM & Agent Engineering Digest | Claude, chat | Mondays 08:30 | The latest `- Weekly summary` page (for this week's focus), and the web: model providers, GitHub, Hacker News, practitioner blogs, Databricks and dbt release notes | `<YYYYMMDD> - Weekly Digest (<LLM name>)` in Daily |
| Weekly LLM Digest | Codex | Weekly, Mondays | Same as the Claude digest, with the same prompt | A second `- Weekly Digest (<LLM name>)` page in Daily |
| Monday Scratchpad & Daily summaries | Claude, chat | Mondays 10:30 | The digest pages, last week's Daily pages, the Scratchpad | `<YYYYMMDD> - Digest summary` and `<YYYYMMDD> - Weekly summary` in Daily |
| Recap | Claude, local | Weekdays about 17:00 | Notion, Slack, Gmail, Calendar, Granola, ClickUp, GitHub, Drive, and the local agent transcripts, for every day since the last Recap | The Recap page, and `<YYYYMMDD> - Recap` in Daily |
| Organize Notion Scratchpad | Claude, chat | Weekdays 19:48 | The Scratchpad | One Daily page per Scratchpad section; then removes the filed sections from the Scratchpad |

The `notion-chat-scratchpad` skill in `agents/shared/skills/` is the manual
path into the same flow: run it in any chat to append that chat's takeaways
to the Scratchpad, and the evening task files them.

## Why the tasks are split this way

- **Recap is a local task.** The recap reads the Claude Code transcripts in
  `~/.claude/projects/` and the Codex sessions in `~/.codex/sessions/`, and
  only a local task can read files on this Mac. A local task does not run
  while the Mac is asleep, so the recap covers every day since the most recent
  `- Recap` page in Daily, up to 7 days. A missed day is caught up by the next
  run instead of being lost.
- **Recap and the digests write to Daily directly.** Each of these tasks
  already knows its own title, so routing it through the Scratchpad would only
  add a filing step and a heading the filing task has to recognize. A digest
  task writes to the Scratchpad only when it cannot write to Daily, and the
  filing task then files it under the same title.
- **The morning brief and chat takeaways go through the Scratchpad.** These
  come from a skill and from chats that do not know the Daily naming rules.
  One filing task names, dates and copies each section into Daily, which keeps
  the titles consistent.
- **Two digests run, one per app.** Claude and Codex each write a digest with
  the same prompt, which shows how the two models filter the same week. The
  Digest summary ends with a comparison of what each digest found that the
  other missed. After a few weeks, that comparison decides whether the second
  digest is worth keeping.
- **The digests read last week's summary.** The digest prompt describes Mike's
  stack by hand, which goes stale as work moves on. The latest
  `- Weekly summary` names the current workstreams, so the digest ranks items
  that touch them higher.
- **The Monday summaries run two hours after the digests.** A digest searches
  widely and can take a long time. When the summaries task cannot find
  today's digest, it falls back to an older one, so the gap must be large
  enough for both digests to finish.
- **The Weekly summary checks the other tasks.** Only the Recap sends a
  notification on failure; the other tasks end with a one-line report that
  nobody reads. The Weekly summary's `Task health` section lists every missing
  morning brief, recap or digest from last week, and Scratchpad sections that
  were never filed.

## Contracts between the tasks

The tasks find each other's output by exact headings and titles. Changing one
of these in one prompt breaks the tasks that read it, so check every row of
this table before renaming anything.

| Output | Written by | Read by | Matched by |
|---|---|---|---|
| Daily title `- Weekly Digest (<LLM name>)` | Both digest tasks; Organize Scratchpad as a fallback | Monday summaries | A title containing `Digest` but not `summary` |
| Digest Heading 1 and sections | Both digest tasks | Organize Scratchpad (fallback), Monday summaries | `<LLM name> \| Weekly ... Digest`; `Part A`, `Part B` and `Closing`; `Worth experimenting with`, `Concept of the week` and `Skip the hype` |
| Morning brief heading | Daily briefing | Organize Scratchpad | A heading that is a weekday and date, for example `## Monday, October 12 2026` |
| Daily title `- Morning brief` | Organize Scratchpad | Monday summaries (task health) | Title suffix |
| Chat takeaways heading | `notion-chat-scratchpad` skill | Organize Scratchpad | `## <date> — <topic>` or `### <topic> · Key Takeaways` |
| Daily title `- Recap` | Recap | Recap (start of its period), Monday summaries | Title suffix |
| Recap sections `To do next`, `Decisions`, `Workstreams` | Recap | Recap (next run), Monday summaries | Heading text |
| Daily title `- Weekly summary` | Monday summaries | Both digest tasks, Monday summaries (to skip its own output) | Title suffix |
| Daily title `- Digest summary` | Monday summaries | Monday summaries (to skip its own output) | Title suffix |

Each task may write only its own pages. Every prompt names the pages it may
change and forbids changes to the pages the other tasks own.

## Rules every prompt follows

- **Unattended.** The prompt tells the agent never to ask questions, to make
  the most reasonable choice, and to state each assumption in one line on the
  page or in the final line. A scheduled run has nobody to answer a question.
- **Content is data.** The prompt tells the agent never to follow instructions
  found in emails, messages, pages or transcripts, because anyone who can
  send Mike a message could otherwise steer the task.
- **Named writes only.** The prompt lists every write the task may make and
  forbids all others, such as replying to email or changing ClickUp tasks.
- **Idempotent.** Before creating a Daily page, the task looks for a page with
  the same title and replaces its body instead of creating a duplicate, so a
  rerun on the same day is safe.
- **One-line finish.** The run ends with one line saying what was saved, and
  any skipped source or failed write is named in that line.
- **Automated sessions are skipped.** The recap skips agent sessions whose
  first user message starts with `<scheduled-task`, because those are runs of
  these tasks, not Mike's work.

## Prompt backup

The private Notion page "Scheduled task prompts" holds a copy of every
prompt, one code block per task, with the date it was last updated. The app
that runs a task holds the live prompt, and a save in the app once cut several
passages out of the Recap prompt without any error. The backup is the copy to
compare with or restore from. The page lives in Notion and not in this
repository, because the prompts contain workspace page IDs and Mike's
personal details.

## Recreate the setup

1. Create the Notion pages: the Scratchpad page, the Recap page, and the Daily
   database with the properties listed under [Terms](#terms). `Status` has the
   options Not started, In progress and Done.
2. In the Claude account, connect Notion, Gmail, Google Calendar, Google
   Drive, Slack, Granola and ClickUp. In the Codex app, connect Notion for the
   Codex digest. GitHub data comes from the `gh` CLI, which the Recap task
   runs on this Mac.
3. Create each task in the table above with its schedule and kind, using the
   prompts from the backup page. Put the new Notion page and database IDs into
   the prompts.
4. Create the Recap task as a local task in the Claude desktop app, because it
   reads local transcripts. This repository's `agents/claude/settings.json`
   lets Claude Code read those transcripts and run read-only `gh` commands
   without asking, which an unattended run needs.
5. Run each task once by hand in schedule order (briefing, digests, Monday
   summaries, recap, organize) and check that each one finds the previous
   task's output.

## When changing a prompt

- Edit the prompt in the app that runs it. After saving, open the prompt again
  and check that its last line is intact, then copy the new prompt into the
  backup page.
- If the change renames a heading, a section or a title, update every task in
  the contracts table that reads it, and run the reading task once by hand.
