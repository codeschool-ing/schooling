---
title: The failure log
version: 2
---

A decision record explains a choice. A failure log explains an accident: every time the prompt is
found doing something wrong, one entry saying what happened and what now stops it happening again.
The practice is older than prompts. Google's *Site Reliability Engineering* book (2016) gives a
chapter, *Postmortem Culture: Learning from Failure*, to writing them without blame, and **the point
carries over unchanged: the entry is about the system, not about who made the edit**.

## The evidence for the entry

The prompt as it stands fails `json` on two dev messages, and they have something in common:

```
ana@lab:~/triage$ grep -E "\"t3[78]\"" cases/dev.jsonl
{"id": "t37", "message": "The book I ordered says 'in stock' but my order still says 'awaiting dispatch' after a week.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "t38", "message": "The ebook I bought won't open on my reader.", "expect": {"category": "returns", "urgency": "normal"}}
ana@lab:~/triage$ pl show runs/dev.jsonl t37
│ {"category": "delivery", "urgency": "high", "summary": "Wants to know why the order status hasn"}}
stop: stop, tokens in 315, out 28, 4.2 s
ana@lab:~/triage$ pl show runs/dev.jsonl t38
│ {"category": "returns", "urgency": "normal", "summary": "The ebook won"}}
stop: stop, tokens in 303, out 22, 3.0 s
```

`t37` stops at *hasn* and `t38` at *won*, and both close the object twice. The model wrote the
apostrophe of *hasn't* and *won't*, ended the string there, and lost its place. Lesson 3 found `t38`
doing exactly this under `v2-json.txt`, and nothing since has fixed it.

## The entry

```localised
F-0001  Summaries cut at an apostrophe; the reply is not JSON

Seen         2026-08-17, prompts/triage.txt at 85dfa4e (id c1916fcd)
Messages     t37 "...still says 'awaiting dispatch' after a week."
             t38 "The ebook I bought won't open on my reader."
Model said   {"category": "returns", "urgency": "normal",
              "summary": "The ebook won"}}
Caught by    json, the first check: 2 of 40 on dev
Cause        the model ends the summary string at an apostrophe in a
             contraction it is copying from the message
Fix          not yet. Lesson 3's schema mode keeps the reply valid JSON;
             it is not in prompts/triage.txt. Decision to follow.
Test added   none needed: t37 and t38 are dev cases already. The gate of
             lesson 14 fails any change that breaks a third
Cost         two tickets in forty reach a person unsorted
```

Five lines carry the weight.

- *Messages* and *Model said* are the evidence, quoted rather than described. One real reply tells a
  reader more than a sentence about replies, and `t38`'s shows the cut and the double brace at once.
- *Caught by* names the check, or the check that would have caught it. When the answer is
  *nothing would have*, that line is the most important one in the log, because it is a hole in
  the tests.
- *Cause* says what the entry's author believes and no more. Two messages with the same cut are a
  pattern; *the model cannot handle apostrophes* would be a claim nobody measured.
- *Fix* names a commit or says there is none yet. An entry that is honest about an open failure is
  worth more than a log that only records the closed ones.
- *Test added* is what keeps it fixed.

## The line that matters most

This failure is the convenient kind: the test set already catches it, and the work left is a fix.
Most failures are the other kind. A customer writes something nobody imagined, the reply is wrong,
and somebody notices in the support queue. **The fix is not finished until that message, cleaned of
names and numbers, is a case in a test set**, with the answer a person decided is right. Otherwise
the gate has nothing to fail on, and the same failure can come back with the next change and pass
every check.

Read a dozen entries together and they show patterns no single one does. Here two messages already
make one: an apostrophe in a contraction, copied into a JSON string, is where this model loses its
place. A third entry ending *cut at an apostrophe* would be the log saying something about how the
replies are produced rather than about three messages.
