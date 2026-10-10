---
title: Watching the monitoring itself
version: 1
---

The tuned rules caught three incidents in two days of data. The failure they cannot catch is **the day
the data stops arriving**. If the job that writes the hourly counts dies, `monitor.py` reads an old
file, finds nothing unusual in it and says nothing, which looks exactly like a quiet, healthy day.

## Silence is a signal

So the monitoring has one rule about itself: **an hour with no counts is an alert**, with the same
severity as the worst thing it would have missed. A heartbeat, a line written every hour whatever
happens, makes the absence visible. The same goes for each control: a canary check that stopped
running reports zero canaries for ever, and a count of zero after a deployment is worth one look to
make sure the check is still in the path.

## An alert says what to do

A page at three in the morning is read by somebody half awake. **Every alert carries a link to its
runbook**: what the alert means, what to look at first, and what can safely be done before anybody else
is awake. For the refused replies of this lesson, the first look is `prompts.py status` and the latest
deployment, and the safe action is lesson 20's rollback. For the canary, it is the call the alert
names, traced with `trace.py`. Lesson 24 writes those runbooks.

## The alert list is reviewed like code

Rules age like the threat register of lesson 13. A rule that has not fired in a year may be watching
something that no longer exists, or be broken; a rule that fires every week and is always dismissed is
training the team to dismiss it. Every month or so, somebody reads the list with the history of what
fired:

| question | if the answer is no |
|---|---|
| did every page last month need a person at that hour? | lower it to a ticket, or fix its shape |
| was every incident announced by a rule? | write the rule that would have |
| does every rule have a runbook and an owner? | write it, or delete the rule |

`alerts.json` lives in the repository with the rest of the assistant's configuration, so a change to a
threshold is a pull request somebody reviews, with the reason in its description, rather than a field
edited in a dashboard at the end of a long night.
