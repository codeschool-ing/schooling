---
title: When the sources disagree
version: 1
---

Two documents can both be relevant and say different things. Sometimes one replaced the other, as the
2025 returns policy was replaced. Sometimes both are current and apply to different cases: the returns
policy gives thirty days and the terms of sale give seven, because one is the shop's promise and the
other is the law. A generator handed both has to decide what to do, and the worst decision is the
one extract-1 makes.

## With the replaced policy in the sources

The status filter is what kept the 2025 policy out. Here it is loosened to the audience alone, so the
replaced policy is allowed back in:

```
ana@lab:~/rag$ python -c "from answer import answer; print(answer(\"How many days do I have to return a printed book?\", where=\"audience = %s\", params=(\"public\",))[0])"
You have 30 days from delivery to return a printed book in the condition you received it. [2] You may return a printed book within 14 days of delivery if it is unread and in the condition in which you received it. [1] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [3]
```

**Thirty days from `[2]` and fourteen from `[1]`, side by side, each cited.** The prompt said to prefer
the source updated most recently and say so; the headers carried the dates, 2026-02-02 and 2025-03-01.
extract-1 has no notion of a date and quoted both. A real model would usually follow the instruction
here, given the dates, which is exactly why the dates have to be in the prompt: the instruction is
useless without them.

## With the filter back on

```
ana@lab:~/rag$ python answer.py "How many days do I have to return a printed book?"
You have 30 days from delivery to return a printed book in the condition you received it. [1] Our returns and refunds policy extends this period to 30 days for printed books. [3] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [2]
  [1] Returns and refunds policy > The return window, updated 2026-02-02
  [3] Terms of sale > 6. The right of withdrawal, updated 2026-01-05
  [2] Returns and refunds policy > Damaged, faulty and wrong items, updated 2026-02-02
```

**Thirty days, from the current policy, and a second source that agrees.** `[3]` is the terms of
sale's clause on withdrawal, *Our returns and refunds policy extends this period to 30 days*, which is
a different document saying the same thing. This is the kind of disagreement that is not one: the
terms state the legal minimum of seven days and point to the policy for the thirty.

## Resolve conflicts in code where you can

The pattern from the last section applies again. **Wherever the rule for which source wins can be
written down, write it in code, before the prompt**, and leave to the model only the conflicts no rule
covers.

- **A replaced document**: filter by `status`, as above. The decision is made once, by whoever marks
  the document superseded, and every answer follows it.
- **Two versions of one document**: keep the newest by `doc_version` or `updated`, unless the question
  is about a date in the past, as lesson 2's legal questions were.
- **A general rule and an exception**: keep both, because the model needs both, and order them so the
  more specific one comes first; lesson 12 measures what order does.
- **Two current documents that really disagree**: that is a defect in the documents, not in the
  pipeline. Show both with their dates, and log it, because somebody who owns one of them needs to
  hear about it. The `owner` column from lesson 5 says who.
