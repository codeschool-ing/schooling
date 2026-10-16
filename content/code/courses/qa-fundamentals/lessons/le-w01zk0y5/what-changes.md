---
title: Four ways of working, one job
version: 1
---

**Scrum, Kanban, XP and SAFe answer different questions, and a real team usually mixes them.** Scrum says how
to plan and inspect in cycles. Kanban says how to see and limit the flow. XP says how to write the code. SAFe
says how many teams line up. None of them says the same thing about testing, and that is the useful part:
each one moves a different piece of the job.

| | Scrum | Kanban | XP | SAFe |
|---|---|---|---|---|
| what it describes | one team's cycle | the flow of work | engineering practices | many teams on one product |
| rhythm | sprints of a month or less | continuous, with cadences | short iterations, many loops | intervals of 8 to 12 weeks |
| where the tester sits | a Developer, no separate role | wherever the flow needs it | beside the customer and the programmers | in a team, plus a System Team across teams |
| who writes the automated checks | not said | not said | programmers, test first; the customer's tests with help | every team, plus end-to-end checks by the System Team |
| where quality is held | the definition of done | the policy on each column | the practices themselves | built-in quality, and the System Demo |
| the typical failure | a mini-waterfall inside the sprint | a queue in front of testing | trusting green checks | a hardening sprint at the end of every interval |

The last row is the one to remember. Each way of working has a characteristic way of sliding back into the
waterfall's testing phase, and a tester who knows which one to expect can spot it in the first week.

## What does not change

Read down the table again and look for what is the same in every column. It is the job this course has been
describing since lesson 1:

- **prevention first**: questions before the code, from lesson 2's four questions to PI Planning;
- **examples as the base**: acceptance criteria written as cases, whether the method calls them criteria,
  customer tests or column policies;
- **exploration on top of automation**: the checks confirm what someone wrote down, and a person looks for what
  nobody did;
- **defects as evidence about the process**: why was it possible?, asked at a retrospective, at a blocked card,
  at a red build.

At Cine Aurora, the team now runs the price work in two-week sprints, the box office requests on a Kanban board,
pairs and integrates continuously as XP says, and has never needed SAFe. Nobody planned that mix. It grew out of
fixing one problem at a time, which is how most teams end up with their way of working, and it is why a tester
is better off knowing the pieces than defending one method.
