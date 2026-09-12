# Personal knowledge system

## Where the architecture belongs

Keep two boundaries, not three new repositories:

| Location | Owns |
| --- | --- |
| Private Obsidian vault, outside dotfiles | Notes, attachments, Inbox.md, Tasks.md, canonical AGENTS.md, processing history |
| This repository | Tool installation, `home/.local/bin/kb`, generic starter template, machine bootstrap documentation |
| Local private state outside Git/Nix | Agent login, sync login/encryption key, original Notion exports, migration reports and backups |

The live vault AGENTS.md is a normal writable file. `kb init` copies a starter
once; a Nix rebuild never replaces it. A separate software repository becomes
worthwhile only if these few scripts grow into a maintained application.

Use Markdown and ordinary file search. Obsidian is the editor; interactive
agents interpret and organize. Bases can provide optional database views over
notes and properties, without becoming the sole copy of the knowledge.

## Machine setup and boundaries

The existing flake targets Apple Silicon macOS with nix-darwin, Home Manager
and nix-homebrew. Codex and ripgrep are already declared. Obsidian is now in the
Homebrew cask list; Home Manager links the helper using the existing repo-source
convention. No reusable module is needed for one cask and one helper yet.

No secret-manager module was found in the inspected Nix/shell configuration.
Keep authentication in the tools' local storage or OS keychain; never read it
into Nix expressions. No model API key is needed for the initial workflow.
Codex supports [ChatGPT subscription login](https://learn.chatgpt.com/docs/auth).

The helper is usable on macOS/Linux with Bash and Git. The repository's Nix
configuration remains macOS-specific; Linux GUI installation and a Linux Nix
host configuration are not implemented by adding this helper. WSL's existing
bootstrap is separate and does not yet install it.

Validate changes with `bash -n home/.local/bin/kb`,
`python3 knowledge-base/test_kb.py`, `git diff --check`, and the repository's
documented Nix evaluation and build dry run. Tests cover refusal to overwrite,
symlinks, nested repositories, recovery baselines and visibility of new files.

## Initialize or connect

Choose the sync method before settling on the production location. For Obsidian
Sync, choose a local directory outside other cloud-sync roots (for example a
dedicated Knowledge directory). For iCloud on iPhone, use Obsidian's actual
iCloud app container. Do not combine two file-sync services on one vault.

After reviewing the normal machine rebuild, the helper is on PATH. Before a
rebuild, invoke `~/.dotfiles/home/.local/bin/kb` directly. Rebuilds have the
repository's existing Homebrew `zap` behavior; adding this feature does not
require running cleanup to test the helper.

```sh
# Point this at your selected production path, not the dotfiles repository.
export KB_VAULT_PATH="/absolute/path/to/SecondBrain"
kb init "$KB_VAULT_PATH"
git -C "$KB_VAULT_PATH" status
# Inspect each initial file, then stage those files and commit a baseline.
kb doctor
kb agent
```

`init` refuses any existing path and vaults nested inside another Git repository.
It deliberately does not commit or create a remote. To connect an existing
vault, set KB_VAULT_PATH and inspect it; do not run init. Before initializing Git
in an existing vault, check whether Git history already exists and establish
an independent backup. Store the chosen path in machine-local shell settings;
it is not private knowledge to be evaluated into the Nix store.

The initial template contains only Inbox.md, Tasks.md and operating rules.
Create Notes/, Processing/ and attachment folders when there is content for them.
Preserve imported folders until validation establishes a reason to reorganize.

## Daily use and recovery

Capture in Inbox.md. Let devices finish syncing and avoid editing during a batch.
Run `kb agent`, then ask: `Process my inbox according to AGENTS.md.`
The agent searches first, preserves the capture, records destinations, and leaves
uncertain items pending. It must not expand a vague idea into invented knowledge.

Use `kb status` and `kb diff` to review changes. The latter shows staged and
unstaged diffs and lists untracked files; open those files separately. Commit
only after review. Do not use Git as the iPhone sync mechanism in v1. Keep Git
metadata local to each computer; arrange independent backup of notes,
attachments and Git history. Test restoring a file before real bulk edits.

The template excludes all .obsidian state from Git initially because plugin
settings can contain secrets. Keep essential editor settings documented; later
allowlist particular safe files if reproducibility benefits justify it.

`kb doctor` checks paths, required commands, a committed baseline, Git integrity
and instruction overrides. It cannot prove cloud sync completion, availability
of every attachment, authentication health, or off-device backup freshness.

## Migration gates

1. Preserve a dated Notion HTML export including content, subpages and comments;
   record its checksum. Keep Notion available. An export is a snapshot, not proof
   that all accessible/shared content was included.
2. Inventory source page IDs, database rows and attachments. Record excluded
   shared pages, missing permissions and unsupported blocks explicitly. Keep a
   source-ID-to-target-path manifest so retries do not duplicate notes.
3. Import into a separate staging vault. Prefer the official account importer
   when database fidelity warrants a read-only Notion integration token; that
   token is distinct from a model API key. Otherwise use its HTML ZIP importer.
4. Reconcile each source item, not just totals. Check attachment byte hashes,
   local images, internal targets and anchors, empty notes, duplicate IDs,
   Unicode/case filename collisions, code fences, tables, and representative
   rendered notes. Inspect YAML with a parser. Preserve formulas and relations
   as source evidence when behavior cannot be reproduced.
5. Classify each item as successful, warnings, manual review, or could not
   migrate; explain missing scope. Keep task/reminder replacement as a separate
   gate from content preservation. A checkbox is not a notification service.
6. Record edits made in Notion after the snapshot. Reconcile that delta before
   cutover. Promote a reviewed batch and take a recovery checkpoint. Only then
   normalize names, properties and organization incrementally.

The [official importer](https://obsidian.md/help/import/notion) supports account
and ZIP routes. Account import converts databases to Bases, but only a primary
view and a subset of behavior survive; linked data sources have limitations.
ZIP import expects HTML and does not preserve working databases. Markdown/CSV
export is a useful supplemental snapshot, not the preferred primary conversion.
[Notion export documentation](https://www.notion.com/en-gb/help/export-your-content)
also states that exporting all database views together is unsupported.

Do not substitute a custom connector-to-Markdown dump for a complete backup:
pagination, attachments with expiring URLs, omitted blocks and access scope all
need independent reconciliation. Third-party scripts are fallback tools for
specific verified importer failures, not an extra dependency in advance.

## Access and sync choices

| Approach | Assessment for v1 |
| --- | --- |
| Filesystem | Selected: no server, token or running editor needed; broad agent compatibility; renames require explicit link repair |
| Local REST API | Useful for editor-aware operations or restricted remote clients, but introduces a plugin, authentication and running service |
| MCP | Useful if a client lacks filesystem tools; capabilities and security depend on the chosen server, not the protocol alone |

The [Local REST API project](https://github.com/coddingtonbear/obsidian-local-rest-api)
and an [MCP adapter](https://github.com/MarkusPfundstein/mcp-obsidian) illustrate
the added components. Neither is required by this workflow.

Recommend Obsidian Sync for Mac/iPhone and future Linux. It supplies encryption
and version history. At review time Standard is $4/month billed annually or
$5 monthly, with 1 GB total storage and a 5 MB per-file limit; Plus is $8/$10,
10 GB and 200 MB per file. Inventory attachments before picking a tier.
See [current pricing](https://obsidian.md/sync); never purchase automatically.

iCloud is a reasonable no-new-subscription Apple-only alternative, subject to
available iCloud storage. Keep files downloaded and use the correct Obsidian
iCloud container. It does not supply a native Linux path. See the
[official sync guide](https://obsidian.md/help/sync-notes). Neither option removes
concurrent-edit conflicts or replaces a tested independent backup.

## Other agents and future automation

Launch other filesystem-capable agents in the same vault and explicitly have
them read AGENTS.md. CLAUDE.md imports it; other clients may need a tiny adapter
according to their instruction-loading behavior. Test that behavior before
granting write access; AGENTS.md is a convention, not universal enforcement.

There are no scheduled jobs, local-model services, MCP servers, embeddings or
direct API calls. Later automation can run the same workflow with its own
authentication and concurrency controls. No note schema change is required.
