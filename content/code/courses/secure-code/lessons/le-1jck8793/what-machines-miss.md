---
title: Where the checks run, and what they miss
version: 1
---

`check.sh` is written so that the same command runs on a laptop and on a server. **The server is
where it counts**: a pipeline that runs it on every pull request, and blocks the merge when it
fails, is a check nobody can forget or skip.

::: track devsecops
That pipeline is the subject of your track's `secure-pipeline` course, which builds it on your own
machine and adds what this lesson does not: secret scanning, container image scanning and the
rules for when a failing check may block a release. This lesson introduces the checks; that course
operates them.
:::

::: track *
Any continuous integration service runs a script like this one on each change; the lesson keeps
it to one command precisely so that moving it there is one line of configuration.
:::

### What these three tools cannot see

| what | why the tools miss it | what catches it |
|---|---|---|
| a route that never checks whose data it serves | nothing in the code is a "risky call"; the flaw is a line that is absent | a test that states the refusal, and the review of lesson 18 |
| a requirement nobody wrote | there is no code to scan | reading the story, lesson 1 |
| a flaw that only appears when the application runs | static tools read text, not behaviour | tests against the running application |
| an advisory not yet published | pip-audit reports what is known | the routine of lesson 17, run again tomorrow |

The third row has a family of tools of its own: **dynamic application security testing**, or
DAST, which sends requests to a running application and examines the answers. OWASP ZAP is the
best-known free one. It belongs against a copy of your own application in a test environment, and
it was not run for this course.

### A green run is a floor

A passing `check.sh` says the tests you wrote pass, no risky pattern bandit knows is present, and
no published advisory matches your pins. That is worth a great deal, and it is a floor, not a
certificate. **What sits above the floor is what this whole course has been about**: knowing which
refusals an application owes, and writing the test that asks for each one.
