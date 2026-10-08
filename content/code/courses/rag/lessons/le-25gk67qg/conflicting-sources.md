---
title: When the sources disagree
version: 2
---

Two documents can both be relevant and say different things. Sometimes one replaced the other, as the
2025 returns policy was replaced. Sometimes both are current and apply to different cases: the returns
policy gives thirty days and the terms of sale give seven, because one is the shop's promise and the
other is the law. A generator handed both has to decide what to do, and the worst decision is to quote
both and leave the reader to choose.

## With the replaced policy in the sources

The status filter is what kept the 2025 policy out. Here it is loosened to the audience alone, so the
replaced policy is allowed back in:

```
ana@vm:~/rag$ python -c "from answer import answer; print(answer(\"How many days do I have to return a printed book?\", where=\"audience = %s\", params=(\"public\",))[0])"
According to [1], you have 14 days to return a printed book, but this is only if it is unread and in the condition in which you received it. However, [2] states that you have 30 days from delivery to return a printed book in the condition you received it. 

Since [2] is the more recent update, I prefer it. Therefore, you have 30 days from delivery to return a printed book.
```

**Fourteen days from `[1]`, thirty from `[2]`, and a choice, said out loud.** The prompt said to
prefer the source updated most recently and say so, and the headers carried the dates, 2025-03-01 and
2026-02-02. The model did both. Without the dates in the prompt it could not have: the instruction is
useless when nothing in front of the model says which source is newer. And it is an instruction, so
it is followed most of the time, by this model on this question.

## With the filter back on

```
ana@vm:~/rag$ python answer.py "How many days do I have to return a printed book?"
According to [1], you have 30 days from delivery to return a printed book. This is the most recent and updated policy, as stated in the source date (2026-02-02).
  [1] Returns and refunds policy > The return window, updated 2026-02-02
```

**Thirty days, from the current policy, with no conflict left to resolve.** The filter removed the
2025 policy before the model saw it, so there was nothing to choose between. The model still said the
policy was the most recent, an instruction applied where it had nothing to do, which is harmless here
and is the reason a prompt should not carry an instruction for a case the code can settle.

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
