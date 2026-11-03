# Scheduled agent tasks

This page records the scheduled agent tasks that keep Mike's Notion daily log
up to date, so the setup can be rebuilt on a new machine or account. The page
describes what each task does and how the tasks depend on each other. The
prompts themselves are not stored here, because the live copy of each prompt
is the one in the app that runs it, and a second copy in this repository would
drift.

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
- **Scratchpad**: a Notion page that works as an inbox. Tasks and chats append
  sections to it, and one task files those sections away every evening.
- **Daily database**: a Notion database with one page per filed item. Every
  page title has the form `<YYYYMMDD> - <Content>`, for example
  `20261103 - Recap`. The properties are `Day` (title), `Date`, `Topics`,
  `Status`, `Open action items`, `Chats covered` and `Action items`.
- **Recap page**: a Notion page that always holds the latest end-of-day recap.

## The tasks

Times are Europe/Athens.

| Task | App and kind | When | Reads | Writes |
|---|---|---|---|---|
| Daily briefing | Claude, chat | Weekdays 07:00 | Calendar, Gmail, Slack, ClickUp and GitHub items that mention Mike, recent Granola meetings | A morning brief section in the Scratchpad |
| Weekly LLM & Agent Engineering Digest | Claude, chat | Mondays 08:30 | The web: model providers, GitHub, Hacker News, practitioner blogs, Databricks and dbt release notes | A digest section in the Scratchpad |
| Weekly LLM Digest | Codex | Weekly, Mondays | Same as the Claude digest | A second digest section in the Scratchpad |
| Monday Scratchpad & Daily summaries | Claude, chat | Mondays 09:00 | The digest in the Scratchpad, last week's Daily pages | `<YYYYMMDD> - Digest summary` and `<YYYYMMDD> - Weekly summary` in Daily |
| Recap | Claude, local | Weekdays about 17:00 | Notion, Slack, Gmail, Calendar, Granola, ClickUp, GitHub, Drive, and the local agent transcripts | The Recap page, and `<YYYYMMDD> - Recap` in Daily |
| Organize Notion Scratchpad | Claude, chat | Weekdays 19:48 | The Scratchpad | One Daily page per Scratchpad section; then removes the filed sections from the Scratchpad |

The `notion-chat-scratchpad` skill in `agents/shared/skills/` is the manual
path into the same flow: run it in any chat to append that chat's takeaways
to the Scratchpad, and the evening task files them.

## Why the tasks are split this way

- **Recap is a local task.** The recap reads the Claude Code transcripts in
  `~/.claude/projects/` and the Codex sessions in `~/.codex/sessions/`, and
  only a local task can read files on this Mac. The cost of a local task is
  that a day with the Mac asleep at 17:00 gets no recap.
- **Recap writes to Daily directly.** The recap rewrites the Recap page every
  day, and the Daily copy is a dated snapshot of that page. Routing the recap
  through the Scratchpad would add a step with no benefit.
- **Everything else goes through the Scratchpad.** Tasks and chats append to
  one page, and one filing task names, dates and copies each section into
  Daily. Keeping the naming rules in one task keeps Daily titles consistent.
- **Two digests run, one per app.** Claude and Codex each write a digest with
  the same brief, which shows how the two models filter the same week. Each
  digest heading starts with the model name, for example
  `# Fable 5.1 | Weekly LLM & Data Engineering Digest`, so the filing task
  can tell the two apart.
- **The Monday summaries run after the digests.** The summaries task reads the
  digest from the Scratchpad at 09:00, before the evening filing task moves it
  to Daily. The 30-minute gap after the 08:30 digest gives that run time to
  finish.

## Contracts between the tasks

The tasks find each other's output by exact headings and titles. Changing one
of these in one prompt breaks the tasks that read it, so check every row of
this table before renaming anything.

| Output | Written by | Read by | Matched by |
|---|---|---|---|
| Digest heading | Both digest tasks | Organize Scratchpad, Monday summaries | A Heading 1 of the form `<LLM name> \| Weekly ... Digest` |
| Digest sections | Both digest tasks | Monday summaries | `Part A`, `Part B` and `Closing` headings; `Worth experimenting with`, `Concept of the week` and `Skip the hype` sections |
| Morning brief heading | Daily briefing | Organize Scratchpad | A heading that is a weekday and date, for example `## Monday, October 12 2026` |
| Chat takeaways heading | `notion-chat-scratchpad` skill | Organize Scratchpad | `## <date> — <topic>` or `### <topic> · Key Takeaways` |
| Daily titles `- Morning brief`, `- Weekly Digest`, `- <topic>` | Organize Scratchpad | Monday summaries | Title suffix; a digest is any title containing `Digest` but not `summary` |
| Daily title `- Recap` | Recap | Monday summaries | Title suffix |
| Recap sections `To do next`, `Decisions`, `Workstreams` | Recap | Recap (next day), Monday summaries | Heading text |
| Daily titles `- Digest summary`, `- Weekly summary` | Monday summaries | Monday summaries (to skip its own earlier output) | Title suffix |

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

## Recreate the setup

1. Create the Notion pages: the Scratchpad page, the Recap page, and the Daily
   database with the properties listed under [Terms](#terms). `Topics` is a
   multi-select with the options databricks, invoices, notion, analytics and
   other. `Status` has the options Not started, In progress and Done.
2. In the Claude account, connect Notion, Gmail, Google Calendar, Google
   Drive, Slack, Granola and ClickUp. GitHub data comes from the `gh` CLI,
   which the Recap task runs on this Mac.
3. Create each task in the table above with its schedule and kind. Put the new
   Notion page and database IDs into the prompts.
4. Create the Recap task as a local task in the Claude desktop app, because it
   reads local transcripts. This repository's `agents/claude/settings.json`
   lets Claude Code read those transcripts and run read-only `gh` commands
   without asking, which an unattended run needs.
5. Run each task once by hand in schedule order (briefing, digests, Monday
   summaries, recap, organize) and check that each one finds the previous
   task's output.

## When changing a prompt

- Edit the prompt in the app that runs it. After saving, open the prompt again
  and check that its last line is intact, because a damaged save once cut
  several passages out of the Recap prompt without any error.
- If the change renames a heading, a section or a title, update every task in
  the contracts table that reads it, and run the reading task once by hand.
