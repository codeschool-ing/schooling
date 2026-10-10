---
title: The undercurrents
version: 1
---

**Some concerns belong to no single step of a pipeline, because they run under every step.** Joe Reis
and Matt Housley, in *Fundamentals of Data Engineering* (O'Reilly, 2022), call them the
**undercurrents**, and the word is theirs. They name six. The tempting picture is a set of later
phases: build the pipeline, then secure it, then document it, then automate it. Each undercurrent is
a question asked at every stage instead, and a stage that skipped it hands the gap to the next one.

| undercurrent | the question it asks everywhere | at Roda Livre |
|---|---|---|
| **security** | who can read and change this, and is it the fewest people who need to? | the payments feed readable by two people, not by every analyst |
| **data management** | what does this mean, where did it come from, who owns it, is it right? | one table agreed to be *the* list of rides, with a named owner |
| **DataOps** | is it automated, watched, and quick to recover when it breaks? | the morning check that yesterday arrived, run by a program and not by Davi |
| **data architecture** | how do the pieces fit, and what did each choice trade away? | where the analytical tables live, which this lesson scores |
| **orchestration** | what runs when, in what order, and what happens when a step fails? | the per-station report starting only after the rides have landed |
| **software engineering** | is it code in version control, reviewed and tested? | the load script in git, with a test that feeds it a renamed column |

## Why "under" and not "after"

Take security. A decision made when the rides are first copied, say that the copy keeps each
customer's phone number, does not stay at that stage. Every table built from the copy now holds the
number too, every report that reads those tables can show it, and every person with access to any of
them can read it. **Fixing it at the end means finding every copy**; deciding at the start that the
copy never takes the number means there is nothing to find.

Orchestration is the same shape in another direction. A schedule is not a stage of its own: the
copy, the cleaning and the report each need a time to run and a rule for what to do when the step
before them is late. `pipelines-etl` is the course on that.

## Where they appear in this course

The lifecycle the undercurrents run beneath is lesson 3: generation, ingestion, storage,
transformation and delivery, drawn end to end with these six underneath. They come back by name as
the course goes on:

- security and data management are lesson 7's checks at the door and its section on privacy;
- DataOps is every place a program checks its own work, starting with the freshness check in this
  lesson;
- data architecture is the second half of this lesson, and lessons 9 and 10;
- software engineering is the habit lesson 1 started: every program in this course is a file you can
  read, keep in git and run again.

The list is one book's way of carving up the work, and other authors carve it differently. Its use
is as a checklist: **for any stage, ask the six questions**, and the one nobody can answer is
usually the next incident.
