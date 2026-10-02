---
title: The failure log
version: 1
---

A decision record explains a choice. A failure log explains an accident: every time the prompt is
found doing something wrong, one entry saying what happened and what now stops it happening again.
The practice is older than prompts. Google's *Site Reliability Engineering* book (2016) gives a
chapter, *Postmortem Culture: Learning from Failure*, to writing them without blame, and **the point
carries over unchanged: the entry is about the system, not about who made the edit**.

## The numbers for the entry

The regression from lesson 14 is a ready example. The numbers come from `pl log`, and the evidence
from the run of the broken version that the last section already made:

```
ana@lab:~/triage$ pl log
commit   date        all tokens  subject
8ec39c2  2026-08-03  0/40   2366  First triage prompt
90a013e  2026-08-04 24/40   4734  Ask for JSON, name the fields and list the labels
f361c0a  2026-08-05 36/40  11036  Add three examples of the answer
9683448  2026-08-07 36/40  11636  Ask for the JSON object and nothing else
931c548  2026-08-10 36/40  13356  Put the message in tags and say it is data
c8470c9  2026-08-11 36/40  13356  Escape the message so it cannot close its own tags
31a6a59  2026-08-14  0/40   9739  Make the examples easier to read
03e1151  2026-08-17 36/40  13356  Put the examples back in JSON
ana@lab:~/triage$ pl check runs/plain.jsonl
check      pass  fail
json          0    40
fields        0    40
labels        0    40
category      0    40
urgency       0    40
all           0    40
ana@lab:~/triage$ pl show runs/plain.jsonl t04
│ account, high: wants the express delivery charge back
stop: end, tokens in 233, out 10
```

## The entry

```localised
F-0001  Every reply stopped being JSON              2026-08-14 to 2026-08-17

Change       31a6a59 "Make the examples easier to read"
Message      t04 "I can't log in. The password reset email never comes."
             and every other message: 0/40 on dev, 36/40 before
Model said   account, high: wants the express delivery charge back
Caught by    json, the first check: 0 of 40 passed. No run is recorded
             before the fix; the gate of lesson 14 would have run it that day
Fix          03e1151 put the examples back in JSON (decision 0001)
Test added   none: dev already fails this on the first check. Added
             instead: the gate, which runs dev on every change
Cost         9739 tokens on dev against 13356; cheaper, and useless
```

Five lines carry the weight.

- **Message and Model said** are the evidence, quoted rather than described. One real reply tells a
  reader more than a sentence about replies, and `t04` shows two things at once: the shape copied
  from the example, and the first example's summary pasted into a message about a password.
- **Caught by** names the check, or the check that would have caught it. When the answer is
  *nothing would have*, that line is the most important one in the log, because it is a hole in
  the tests.
- **Fix** names a commit, so the entry and the history point at each other.
- **Test added** is what keeps it fixed.

## The line that matters most

This failure is unusual in one way: the test set already caught it, and what was missing was
somebody running it. Most failures are the other kind. A customer writes something nobody
imagined, the reply is wrong, and somebody notices in the support queue. **The fix is not finished
until that message, cleaned of names and numbers, is a case in a test set**, with the answer a
person decided is right. Otherwise the gate has nothing to fail on, and the same failure can come
back with the next change and pass every check.

Read a dozen entries together and they show patterns no single one does. If three of them ended
*pulled towards the first example's label*, as `t37` would, the log would be saying something about
how the prompt is built rather than about three messages.
