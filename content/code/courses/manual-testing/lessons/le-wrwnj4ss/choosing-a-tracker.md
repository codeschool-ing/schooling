---
title: Choosing a tracker, and the report that fits all of them
version: 1
---

Most testers do not choose a tracker. They arrive at a company that chose one years ago, and their
job is to use it well. So this section starts with the skill that travels, putting lesson 15's
report into whatever tracker is in front of you, and ends with the questions to ask on the day
somebody does ask you to choose.

## The report, mapped

Here is where each part of lesson 15's report usually lands, in any of the four products of this
lesson:

| report | where it goes in a tracker |
|---|---|
| title | the issue's summary, or the card's title |
| environment | an environment field where the tracker has one, as Jira does; otherwise the first lines of the description |
| preconditions, steps, expected, actual | the description, in a fixed layout with a heading for each |
| reproducibility | the description, after the actual result |
| evidence | the transcript as text in the description, in a code block; a screenshot or recording as an attachment |
| severity | a custom field the team adds; on a board, a label |
| priority | the built-in priority field in Jira and YouTrack; on a board, a label or the card's position |
| version found | an *affects version* field, or a label |
| links | duplicates, the requirement, the change that caused a regression: the tracker's links, or the description |

**Four of lesson 15's nine fields go into one free-text field**, the description, and that is where most
reports in any tracker go wrong. A tracker checks that a summary exists; it cannot check that the
description holds steps a stranger can replay. So **a team agrees a description template**, the same
headings in the same order on every defect, and some trackers can start each new bug with it. With a
template, the reader of section 02 of lesson 15 finds the steps in the same place in every report.
Without one, each tester invents a layout and every report is read from the top.

Here is the description of the traceback report from lesson 15, as it would be pasted into any of
the four:

```localised
Preconditions
boxoffice 1.1, freshly started (/health answers "ok boxoffice 1.1").

Steps
1. Open http://127.0.0.1:8000/book?show=S2
2. E-mail: member@example.org
3. Show: leave it on Hamlet
4. Tickets: two
5. Press Book.

One-line reproduction
curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book

Expected
The form again, with "You can book 1 to 6 tickets." (R4, R7)

Actual
500, and a Python traceback ending:
ValueError: invalid literal for int() with base 10: 'two'

Reproducibility
Every time; also with an empty quantity and with 2.5.
```

## When you are the one choosing

Five questions decide most choices, and none of them is about which product has more features.

**Who files reports?** Only the team, or also customers, staff at a box office, people outside the
company? A tracker the reporters cannot reach, or find too hard to use, collects fewer reports, and
the missing ones are the ones customers would have sent.

**Does the lifecycle need to be enforced?** A team of two who sit together can keep lesson 16's
rules as a habit, and a board is enough. A team of forty across three products cannot, and needs a
tracker that refuses a move the rules forbid.

**What has to connect to it?** The code host, so a fix links to its issue; the test-case tool of
lesson 18, so a failed case becomes a defect with one click; the wiki where the requirements live.
A tracker nothing connects to becomes a second place to type the same thing.

**Can it answer lesson 16's questions?** Age of open defects by severity, reopen rate, escaped
defects: if the tracker cannot search for them, nobody will count them by hand for long.

**Can you leave?** Every tool is replaced eventually. A tracker whose issues, history and
attachments can be exported in a readable format can be left; one that cannot keeps the team's
history hostage.

Two questions are deliberately not in that list. **Price** matters and changes too often for a
course to quote: the vendors' own pages are the only current answer, and each offers a trial.
**Popularity** is a fair tiebreaker, because a widely used tool is easier to hire for, and a poor
reason on its own, because the tool every company uses is configured differently in every company.

For boxoffice, a theatre with one developer and one tester, a board with one list per state and a
label per severity would carry everything this course has reported so far. The day the theatre
hires a second developer and sells a second venue's tickets, the five questions are worth asking
again.
