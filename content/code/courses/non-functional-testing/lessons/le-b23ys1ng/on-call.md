---
title: On call, runbooks and the postmortem
version: 1
---

An alert is a message to a person, and the person has to exist, be reachable, know what to do and
have permission to do it. **The rule is the cheap part; the rota is the expensive one.**

## A runbook for every page

The annotation `runbook_url` points at a page every alert should have before it is allowed to
page anybody. A runbook is written for the person who has just been woken up and has never seen
this alert before, and it answers four questions in order:

1. **What does this alert mean for customers?** "More than 2% of requests to the box office are
   failing. Some people cannot book."
2. **How do I confirm it?** The query from `expr`, the dashboard, `jq 'select(.level == "error")'`
   over the log, the synthetic probe's last results.
3. **What do I try first?** The known causes, most likely first, each with the command that checks
   it: the payment provider's status page, the last deployment and how to roll it back, the
   database's connections.
4. **Who do I call when that does not work?** A name or a rota, not "the backend team".

A page whose runbook says nothing useful should be a ticket until somebody writes one. A runbook
whose steps can be followed without judgement should become a script, and then, often, the alert
can run it and page nobody.

## Rotations and escalation

On call is a rota: one person at a time is the first to be paged, for a week or so, then hands over.
Three habits keep it humane enough to last.

- **A primary and a secondary.** The paging service calls the primary; if nobody acknowledges
  within, say, ten minutes, it calls the secondary, and after that a manager. That chain is the
  *escalation policy*, and it is what PagerDuty and Opsgenie hold for you.
- **Handovers that are written down.** What fired this week, what was done, what is still open. The
  next person starts with the context instead of rediscovering it at 03:00.
- **Pages counted and paid for.** A rota that pages its people every night is a rota that loses
  them. The count of pages per shift is a metric like any other, with a threshold.

Lesson 1's sentence said *reaches the person on call*, not *is sent*. **An alert that fires into
an Alertmanager nobody runs, or a phone nobody answers, has not reached anybody**, and the only way
to know that the chain works end to end is to test it: a deliberate page, on a schedule, that
somebody has to acknowledge.

## The postmortem, without blame

After an incident comes a written account of it, the **postmortem**. It says what happened, in
order and with times, and how it was detected and how long that took. Then it says what was done
and what the impact on customers was. Last comes what will change so that it does not happen
again, each change with an owner and a date.

**It is written without blame**, and that is a working rule, not a courtesy. The question is never
who made the mistake but why the system let a reasonable person make it: why a deploy with a broken
payment client passed every check, why the alert took eleven minutes when the requirement said
five. A postmortem that names a culprit teaches everybody to hide the next mistake, and a hidden
mistake is one the system cannot learn from. The outcome is almost always a change to the system: a
test, a check in the pipeline, an alert with a better threshold, a runbook step.

That is also where this course's tests come from in a team that has been running for a while. A
defect that only appeared with real users becomes, after its postmortem, a load test with the
traffic that caused it, a probe that walks the path that broke, a rule with a unit test. Production
teaches what to test next.

## What the four thirds have in common

This course had four subjects, and lesson 1 said each had its own tools and its own way of saying
*pass*. They also share one move, the one lesson 1 made first: **turn the adjective into a number,
or a named list, before measuring anything.**

| third | the adjective | what this course turned it into | what said *fail* |
|---|---|---|---|
| performance, lessons 1 to 11 | fast | a percentile, a threshold, a load, for an operation | the load test's thresholds, and the performance budget in the pipeline |
| accessibility, lessons 12 to 15 | accessible | WCAG 2.2 AA, the criteria by name | axe's findings, and the keyboard and screen reader checks a tool cannot make |
| security, lessons 16 to 21 | secure | the OWASP risks, checked on your own application, and no high finding left open | the scanner's report, read by a person, and the test that one customer cannot read another's booking |
| operability, lessons 22 to 24 | we will know when it breaks | an error ratio, a window and a time to reach a person | a rule with a unit test, and an alert that arrives |

In every row the tool was the easy part. The work was deciding, before running it, which result
would mean *fail*, writing that down where the next person could find it, and making a machine hold
it there: a threshold in a k6 script, an axe check in the pipeline, a `promtool` test beside the
rule. **A non-functional requirement nobody wrote down is a wish**, and every third of this course
was about doing the writing.
