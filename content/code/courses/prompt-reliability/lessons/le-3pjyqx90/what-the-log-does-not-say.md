---
title: What the log does not say
version: 2
---

It is tempting to treat the history as the documentation: every change is in git, with a date and
a message, so anybody who wants to know can look. **The history says what changed and when. It
almost never says why**, and the why is what the next person needs.

Here is the whole record of `prompts/triage.txt`, one line per commit, as lesson 14's `history.sh`
made it:

```
ana@lab:~/triage$ git log --format='%h %ad %s' --date=short -- prompts/triage.txt
85dfa4e 2026-08-17 Put the examples back in JSON
86913c0 2026-08-14 Make the examples easier to read
c8f1927 2026-08-11 Escape the message so it cannot close its own tags
a0f1d2a 2026-08-10 Put the message in tags and say it is data
5b2d8d0 2026-08-07 Ask for the JSON object and nothing else
ab97290 2026-08-05 Add three examples of the answer
61d470e 2026-08-04 Ask for JSON, name the fields and list the labels
341f8f8 2026-08-03 First triage prompt
```

Every subject is a fair description of its diff. None of them says what problem it solved, what
else was tried, or what was measured before and after. The two commits lesson 14 ended on carry
nothing but their subjects:

```
ana@lab:~/triage$ git log -1 --format=%B 86913c0
Make the examples easier to read

ana@lab:~/triage$ git log -1 --format=%B 85dfa4e
Put the examples back in JSON
```

## Six months later

Picture somebody who joins in February and opens `prompts/triage.txt` for the first time. The
examples are long lines of JSON with every quote spelled out, and they are hard to read. **The
obvious improvement is the one `86913c0` made**, and nothing near the prompt tells them it was made
already, scored three messages better on dev, and was undone three days later by somebody who wrote
down what they did and not why. The log has the two commits, but nobody reads a log looking for a
reason not to do something, and here there is no reason in it to find. The person who knew has moved
team, and the explanation, if there was one, is in a chat thread nobody can find.

Lesson 14 put a number beside every commit. **A number says what a change did on one test set; it
does not say what was weighed against it**, or which of the prompt's odd-looking choices are
load-bearing. That needs words, written down when the reason is still known, and kept where a reader
of the prompt will find them.

## Three notes, three questions

The rest of this lesson writes three kinds of note, each answering a different question about the
prompt:

| note | the question it answers | written when |
|---|---|---|
| decision record | why is it like this? | a choice is made between options |
| failure log | what has gone wrong before, and what stops it again? | a failure is found |
| prompt card | what is this, how good is it and what does it cost? | it ships, and at every change |

None of them is a program. They are files you would add to the repository beside the prompt, and
the ones in this lesson were written by the course from the runs it shows. A longer commit message
would help too, but it is scattered across the history and read only by somebody already running
`git log`. **Notes beside the prompt are read by whoever opens the prompt.**
