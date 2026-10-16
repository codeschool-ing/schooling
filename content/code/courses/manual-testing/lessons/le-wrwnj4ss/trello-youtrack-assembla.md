---
title: Trello, YouTrack and Assembla
version: 1
---

The other three products in this lesson are three different answers to the same five needs of
section 01, and each is easiest to understand by what it leaves out compared with Jira. None of
them was run for this course; what follows is the kind of tool each one is.

## Trello: a board and nothing more

**Trello is a board first and a tracker only if you make it one.** It is made by Atlassian, like
Jira, and its whole model is three things: a **board**, the **lists** on it, and the **cards** in
each list. A card has a title, a description, comments, attachments, coloured **labels**, members
and a checklist, and it moves from list to list by being dragged.

To track boxoffice's defects in Trello, you would make one list per state of lesson 16, *new*,
*triaged*, *in progress*, *fixed*, *ready for retest*, *closed*, one card per report, and a label per
severity. That works, and for a team of two it may be all they need.

What it gives up is enforcement. **Any card can be dragged to any list by anybody**, so nothing
stops a card going from *new* straight to *closed*, and the rule that only the tester closes a
defect lives in the team's habits. Fields beyond the basic ones are possible but loose, and the
counts of lesson 16, age by severity or reopen rate, are harder to get out of a board than out of a
tracker built around searches. Trello suits a small team, one product and a lifecycle everybody
already agrees on.

## YouTrack: a tracker with the same ambitions as Jira

**YouTrack is a full issue tracker made by JetBrains**, the company behind several widely used
programming tools. It has the same parts as Jira: projects, issues with an id, typed fields that a
team can extend, configurable workflows, boards and saved searches typed as queries. A team that
already writes its code in JetBrains' tools gets a tracker from the same company, which is one
common reason it is chosen.

For a tester, moving between Jira and YouTrack is mostly a matter of new names for the same things.
The report of lesson 15 fits either one field for field, and a team using either can enforce the
lifecycle of lesson 16 in the tool rather than in habit.

## Assembla: tickets next to the code

**Assembla is a hosted service for source code with tickets beside it.** Its emphasis is the
repositories, and it is known for hosting Subversion and Perforce as well as Git, which matters to
teams such as game studios whose projects hold large files that Git handles poorly. Tickets, with
their fields and a board view, sit next to that code and link to the changes that fix them.

A tester meets Assembla where a company chose it for its repositories and took the tickets that came
with it. The ticket side is a tracker in the sense of section 01, and the same report goes into it
the same way.

## The pattern

Laid side by side, the four make one point:

| | what it is first | the workflow | where a tester meets it |
|---|---|---|---|
| **Jira** | an issue tracker, and a platform for add-ons | configured per project, and can refuse a move | software companies of every size |
| **Trello** | a board of cards | none of its own: any card to any list | a small team with one product |
| **YouTrack** | an issue tracker | configured per project, and can refuse a move | a team that chose an alternative to Jira |
| **Assembla** | code hosting, with tickets beside it | ticket states set per project | a team that chose it for the repositories |

Feature lists make them look alike. **What separates them is what each one refuses.** A
tracker that refuses a move the team's lifecycle forbids turns a rule into a guarantee; a board that
allows anything leaves the rule as a habit, which holds until the week the team is busy.
