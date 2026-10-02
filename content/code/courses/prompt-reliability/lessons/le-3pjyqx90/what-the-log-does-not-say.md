---
title: What the log does not say
version: 1
---

It is tempting to treat the history as the documentation: every change is in git, with a date and
a message, so anybody who wants to know can look. **The history says what changed and when. It
almost never says why**, and the why is what the next person needs.

Here is the whole record of `prompts/triage.txt`, one line per commit:

```
ana@lab:~/triage$ git log --format='%h %ad %s' --date=short -- prompts/triage.txt
03e1151 2026-08-17 Put the examples back in JSON
31a6a59 2026-08-14 Make the examples easier to read
c8470c9 2026-08-11 Escape the message so it cannot close its own tags
931c548 2026-08-10 Put the message in tags and say it is data
9683448 2026-08-07 Ask for the JSON object and nothing else
f361c0a 2026-08-05 Add three examples of the answer
90a013e 2026-08-04 Ask for JSON, name the fields and list the labels
8ec39c2 2026-08-03 First triage prompt
```

Every subject is a fair description of its diff. None of them says what problem it solved, what
else was tried, or what was measured before and after. The message of the commit that broke
everything is the subject and nothing else:

```
ana@lab:~/triage$ git log -1 --format=%B 31a6a59
Make the examples easier to read
```

## Six months later

Picture somebody who joins in February and opens `prompts/triage.txt` for the first time. The
examples are long lines of JSON with every quote escaped, and they are hard to read. **The obvious
improvement is the one `31a6a59` made**, and nothing near the prompt tells them it was made already,
took the score to zero and was reverted three days later. The log has the two commits, but nobody
reads a log looking for a reason not to do something. The person who knew has moved team, and the
explanation, if there was one, is in a chat thread nobody can find.

Lesson 14 put a number beside every commit. **A number says that a change was bad; it does not say
what to avoid next time**, or which of the prompt's odd-looking choices are load-bearing. That needs
words, written down when the reason is still known, and kept where a reader of the prompt will find
them.

## Three notes, three questions

The rest of this lesson writes three kinds of note, each answering a different question about the
prompt:

| note | the question it answers | written when |
|---|---|---|
| decision record | why is it like this? | a choice is made between options |
| failure log | what has gone wrong before, and what stops it again? | a failure is found |
| prompt card | what is this, how good is it and what does it cost? | it ships, and at every change |

None of them exists in the lab. They are files you would add to the repository beside the prompt,
and the versions shown in this lesson were written by the course to show the shape. A longer commit
message would help too, but it is scattered across the history and read only by somebody already
running `git log`. **Notes beside the prompt are read by whoever opens the prompt.**
