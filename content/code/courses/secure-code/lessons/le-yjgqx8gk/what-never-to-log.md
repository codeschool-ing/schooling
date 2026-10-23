---
title: What never goes in a log, and one line per event
version: 1
---

The old sign-in wrote the password into the log. Nobody decided to; somebody wrote a debugging
line with every field in it, and it stayed. **A log is copied, kept and searched by people who are
not the patient**, so some things never go in it, whatever the convenience.

| never log | because | log instead |
|---|---|---|
| passwords, even wrong ones | a wrong password is often the right one for another site, or one typo away | that the attempt failed, and for whom |
| session ids, tokens, API keys | anybody reading the line can act as that session or service | that a session started or ended |
| full card numbers | the card rules forbid storing them, and a log is storage | nothing; the payment provider has the record |
| clinical notes, exam results, diagnoses | health data is the most protected category under the LGPD | the record's identifier, so the team can look it up with authorisation |
| a person's full details when an identifier will do | each copy is one more place an erasure request has to reach | the identifier |

The test `test_a_password_is_never_logged` holds the first row: if anybody adds the field back to a
log line, it fails.

### One event, one line

The fourth test sent a name with a line break in it. With `%s`, the old code wrote the name as it
arrived, so one sign-in attempt became **two lines in the log**, the second starting with text the
sender chose. A log read by people, and by tools that treat each line as one event, can then be made
to show an event that never happened. The fix is the same idea as lesson 4, for one more context:
**encode a value for the place it is written**. `%r` writes the name as a Python literal, quotes
and `\n` included, so the line break stays visible and stays inside one line:

```
INFO portal sign-in succeeded name='lucia'
```

Structured logging, one JSON object per line with each value in its own field, solves the same
problem by construction, and is what most log services prefer. Python's `logging` module can produce
it with a small formatter or a library; the rule underneath does not change.
