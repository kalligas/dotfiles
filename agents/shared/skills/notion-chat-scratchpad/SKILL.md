---
name: notion-chat-scratchpad
description: Extract key takeaways and action items from the current chat and append or update them in the user's Notion Scratchpad. Use when asked to capture, summarize, or enrich Scratchpad from the active conversation.
metadata:
  short-description: Capture chat takeaways to Notion Scratchpad
---

# Notion Chat Scratchpad

Use this skill when the user wants the current conversation distilled into the
Notion Scratchpad.

## Workflow

1. Review the current chat, focusing on decisions, durable facts, useful
   context, open questions, and concrete next actions.
2. Use the Notion connector when available. If the Notion tools are not already
   loaded, discover them with tool search before falling back to manual
   instructions.
3. Find the existing Notion page whose title is `Scratchpad`. If multiple
   plausible pages exist, prefer the one the user most recently used or the one
   in their personal workspace. Ask only if the target is genuinely ambiguous.
4. Add a compact dated entry rather than replacing unrelated existing content.
   Use today's local date in the entry heading.
5. Keep the entry practical:
   - `Key Takeaways`: concise bullets for decisions, findings, and reusable
     context.
   - `Action Items`: checkbox-style tasks with owner or timing only when the
     chat actually provides them.
   - `Open Questions`: include only unresolved questions that matter.
6. Do not include credentials, tokens, private keys, or secrets. If the chat
   contains sensitive operational details, summarize them at a safe level.
7. Do not invent outcomes, deadlines, owners, links, or Notion structure. If
   the conversation does not contain action items, say so in the Scratchpad
   entry instead of manufacturing tasks.

## Output To User

After updating Notion, reply with a short confirmation and summarize the
sections added. Include the Notion page title or link if the connector returns
one.
