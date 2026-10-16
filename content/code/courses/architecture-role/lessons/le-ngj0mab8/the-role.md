---
title: What the architect does
version: 1
---

Three pictures of the architect are common, and each holds a piece of the truth wrapped in a
mistake. **The architect is the most senior programmer**, promoted for being good at code. **The
architect is the person who draws the diagrams.** **The architect is the one who approves
everything.** The first confuses a reward with a job, the second confuses a view with the
architecture (lesson 2), and the third describes a bottleneck rather than a role.

A better description fits in one sentence, and it is the one this course was built around: **the
architect is whoever decides, documents and answers for the structural choices.** Each of the three
verbs carries part of the job.

## Decides

*Decides* does not mean that the architect makes every structural decision personally. At a company
of Carreto's size that would be impossible, and the next section argues it would be undesirable too.
It means that **the architect makes sure the structural decisions get made — by the right people, at
the right moment, with the right information** — and makes some of them directly.

Lesson 1 gave the test for which decisions are structural: the cost of changing them, and whether
they cross team boundaries. Lesson 2 added the timing: the last responsible moment. Between them
they describe most of an architect's attention. A decision inside one team, cheap to reverse,
belongs to that team. A decision that three teams will build on for years needs somebody whose job
is to see it coming.

## Documents

*Documents* means that a decision outlives the meeting where it was made. **A decision nobody wrote
down will be made again**, by somebody who does not know it was made, and possibly the other way.
Writing it down also forces the reasoning into the open: a decision that cannot be explained in a
page is usually a decision that has not been understood yet. Lesson 5 introduces the architecture
decision record and lesson 8 is about keeping documentation alive. The habit starts here.

## Answers for

*Answers for* means that when a structural decision goes wrong, the architect is one of the people
who explains what happened, why the decision looked right at the time, and what changes now. It is
the least visible of the three verbs and the one that gives the other two their weight. Section 04
of this lesson is about it.

## Why Carreto created the role

For years Carreto had no architect, and it worked. With one team, the structural decisions were made
by the people writing the code, in the same room. With seven teams there are **21 pairs of teams**,
and every pair can make a decision that affects the other without either noticing. The seams between
teams have no owner.

Tomás Viana, the CTO, created the role after three incidents in one quarter had the same shape. In
the worst of them, Matching and Payments each changed how a load's status was stored in the same
week. Each change was reviewed, tested and correct on its own; together they made Payments read
certain cancelled loads as delivered, and the problem was found by a shipper, not by Carreto. **No
team had done anything wrong, and no person had been responsible for the place where the two changes
met.** That gap is what Tomás gave Renata.

## Renata's first week

Renata spends her first week as architect finding out what the job is at Carreto, not doing it.

**Monday.** She meets Tomás and asks what he expects. His answer is short: fewer incidents at the
seams, decisions that people can find afterwards, and teams that are not slowed down by her. She
writes the three down; they are the only definition of success she has.

**Tuesday.** She asks each tech lead which open questions involve another team. She gets nine. Two
are about the `loads` table, one is about whether Matching should get its own database, one is about
authentication between services, and five are smaller. None of the nine has an owner.

**Wednesday.** She reads the system rather than the documents: deployment manifests, connection
strings, the broker's consumers, a day of traces. This is where the onboarding slide of lesson 2
comes apart.

**Thursday.** Kátia Lemos, tech lead of Matching, asks her to decide whether Matching should move to
its own database. Renata is tempted to answer — she has an opinion, and answering would show that
the new role does something. She asks Kátia for a week, and for a page describing the problem first.
The next section explains why.

**Friday.** She writes one page and sends it to all fifty engineers: what the role is for, what it
is not, and the nine open questions with a proposed owner for each. The page says plainly that she
will not approve pull requests, will not manage anybody, and will not decide product priorities.

## What fills an architect's weeks

Renata's first week is unusual, but the activities in it recur. Most of the rest of this course is
one of them:

| activity | where the course treats it |
|---|---|
| working at different scopes, from one service to the whole company | lesson 4 |
| making and recording technology and structural decisions | lessons 5 and 6 |
| finding out what the business actually needs | lesson 7 |
| documenting, and keeping it true | lesson 8 |
| setting standards and checking them automatically | lesson 9 |
| working with teams, product and other stakeholders | lesson 10 |
| advising and growing other engineers | lesson 11 |
| removing complexity rather than adding it | lesson 12 |
| balancing quality, deadline and cost; estimating | lessons 13 and 14 |
| still writing code | lesson 15 |

Two things are absent from the table on purpose. **The architect is not the manager of the engineers
whose systems they shape, and does not own what the product does.** Those belong to other people,
and lesson 16 draws the boundaries between the architect, the tech lead and the senior engineer. The
table is what is left when those are taken out, and it is enough for a full-time job.

## The role is defined by the seams

What makes the role necessary at Carreto is not that its engineers lack skill. **It is that
structural decisions now happen between teams, and between teams is where nobody was looking.** An
architect who spends every day inside one team's code has become that team's senior engineer. One
who never looks at any code has become the diagram-drawer of the opening paragraph. The job is at
the seams, and it needs both the view across and enough depth in each part to be believed. Where
that belief comes from is the subject of the next section.
