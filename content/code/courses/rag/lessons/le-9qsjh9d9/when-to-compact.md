---
title: When to compact
version: 2
---

Lesson 13 measured what a conversation costs when every turn is sent again: Beatriz's prompt grew from
119 tokens at her first message to 1,235 at her eleventh, and the twelve turns cost 8,070 tokens of
prompt. That conversation is short. A support chat that goes on for forty messages, an agent working
through a task with long tool outputs, a tutoring session that lasts an hour: each reaches the window,
and long before it reaches the budget lesson 12 set.

Lesson 13's answer was to send less: a state and a recall instead of the history. That works when the
program knows what matters. When it does not, the other answer is **compaction**: replace the older
part of the conversation with something shorter that still carries what the rest of the conversation
needs, and keep going.

Three decisions make a compaction policy, and each is a number a team can measure.

- **When.** On a token count, not on a turn count: compact when the history passes a share of the
  budget, so that a chat of short messages is left alone and a chat with one enormous paste is not.
- **What stays as it was.** The latest turns, verbatim. The next reply is most likely about them, and a
  summary of the message the customer just sent is the one summary nobody needs.
- **What replaces the rest**, and that is the hard one. A summary is the usual answer. The rest of this
  lesson measures what a summary keeps, what it loses, and how to make it lose nothing that matters.

Compaction is also what frameworks and agent products do under names like "summary memory" or
"auto-compact", often with a default threshold and a default prompt. Lesson 10 said what to do with a
default: read it, and measure it on your own conversations.
