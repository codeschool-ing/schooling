---
title: Choosing a door
version: 1
---

**Each door is best at one kind of work, and a company that uses each for its own kind has fewer surprises.** The
API under them is the same; what differs is what each leaves behind.

| door | best for | what it leaves behind |
|---|---|---|
| **the console** | looking: exploring a service, reading a resource, finding the setting nobody remembers | nothing but the audit log |
| **gcloud** | doing one thing now: a runbook step, a query, a script that runs once | a line in a shell history, and the audit log |
| **Terraform** | anything that should still exist tomorrow | files in a repository, reviewed, and a state that knows what it made |
| **a client library** | a program that acts on its own, lesson 24 | the program's own code |

The planner's rule follows from the last column: **a resource that matters is declared**, so that it can be
reviewed before it exists, recreated after it is lost, and compared with what exists, lessons 25 and 26.
gcloud and the console remain the tools for reading, for incidents and for experiments in the sandbox, and an
experiment that turns out to matter is written into Terraform before it is relied on.

## This course, door by door

The course has used all four, and the order it used them in is the order they are learnt:

- **gcloud** from lesson 1, against the emulator and against Google's refusals, for everything that could be run;
- **Terraform** from lesson 2, planned against Google's APIs without asking them anything, and applied for real
  only against the emulator, in lessons 25 and 26;
- **the API itself**, with `curl`, in lessons 24 and 26, and its discovery document, in lesson 25;
- **the console**, never on screen, because the screens change and the requests under them do not; every
  lesson that would have shown one shows the request instead.

**What the course could not do is the step that needs an account**, and lesson 1's section on a real account is
where it starts: multi-factor authentication first, a budget before the first resource, the planner's tree,
and every file this course planned, applied for real, one lesson at a time.
