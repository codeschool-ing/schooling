---
title: Two dates per model
version: 1
---

Every model in Anthropic's table carries two dates, and they answer the two time questions of
lessons 1 and 2.

```
ana@desk:~/desk$ python card.py all "Reliable knowledge cutoff" Retirement
# https://platform.claude.com/docs/en/about-claude/models/overview, read 2026-10-07
Claude Fable 5.1
  Reliable knowledge cutoff   Jun 2026
  Retirement                  Not sooner than September 1, 2027
Claude Opus 5.5
  Reliable knowledge cutoff   Jun 2026
  Retirement                  Not sooner than September 22, 2027
Claude Sonnet 5.5
  Reliable knowledge cutoff   Jun 2026
  Retirement                  Not sooner than September 28, 2027
Claude Haiku 4.5
  Reliable knowledge cutoff   Feb 2025
  Retirement                  Not sooner than October 15, 2026
```

**Reliable knowledge cutoff** is lesson 1 section 10's date: what the model can be trusted to know
about the world. The three newer models stop at June 2026; Haiku 4.5 at February 2025, sixteen months
earlier. For ana's sorting and extraction that gap costs nothing, as lesson 1 argued. For a task
about recent events, libraries or products it would be the first thing to weigh.

**Retirement** is lesson 2 section 06's date, and the wording is precise: *not sooner than*. It is
a floor, a promise that the model will answer until at least then, and not a date on which it will
stop. On the day this was read, **Haiku 4.5's floor was eight days away**. After October 15, 2026
Anthropic may retire it at any time it announces, and the evaluation ana ran on it stops being a
guarantee of anything.

The sheet carries a different set of dates, for different models:

```
ana@desk:~/desk$ python sheet.py retiring --provider anthropic
# LiteLLM model sheet at 21881c57, 4472 entries
3 entries carry a deprecation date
2026-06-09  claude-mythos-preview                              anthropic
2026-11-30  claude-sonnet-4-5                                  anthropic
2026-11-30  claude-sonnet-4-5-20250929                         anthropic
```

Sonnet 4.5, which the comparison table no longer shows, has an actual deprecation date in the
sheet: November 30, 2026. The two sources are not contradicting each other. One lists the current
models and their floors; the other lists older names and the days they end.

## What ana does with this

- She treats **Haiku 4.5 as a model with a short future**. If it wins her evaluation she can use it,
  and she puts its replacement's evaluation in the calendar now, before the floor passes.
- She runs lesson 5's cases on **the dated identifier** `claude-haiku-4-5-20251001`, the one the
  table prints, so the run names exactly what it measured. Section 04 shows the alias beside it.
- She checks the page again before relying on it, because "read 2026-10-07" at the top of every
  capture is the age of every fact in this lesson.
