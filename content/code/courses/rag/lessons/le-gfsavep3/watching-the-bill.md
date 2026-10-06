---
title: Watching the bill
version: 1
---

A cost measured once is a cost from that week. The pipeline keeps it measured by logging it, which
lesson 9 already does: every query's record carries its prompt and completion tokens. From that log,
four numbers are worth watching every day.

- **Tokens per answered query**, input and output separately. A rise means the prompts grew: a larger
  `k`, a longer history, a document that became one enormous chunk. Lesson 12's budget should make it
  flat, and a rise means something bypassed the budget.
- **The share of questions refused before the model.** It is the cheapest answer the pipeline gives. A
  sudden fall can mean the floor was lowered, or that the index started matching everything.
- **The cache hit rate**, and for a semantic cache, a sample of its hits checked by a person every week.
  A hit rate that rises after a threshold change is a cost going down and a risk going up.
- **Cost per user per day**, with a limit. A single account sending thousands of questions, by script
  or by accident, is a bill nobody planned, and a limit per account is the control a provider's own
  spending cap is too coarse to be.

`llm-observability`, later in this track, builds the dashboards, traces and alerts for these. What
this course leaves it is the habit behind them: every decision that changes what is sent to a model,
the floor, the budget, the memory, the cache, has a cost in tokens that can be counted, and was counted
here before it was made.
