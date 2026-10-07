---
title: Measures that turn into surveillance
version: 1
---

The fastest way to make delivery measures useless is to use them to judge individuals. It is also the most tempting, because the data is there: the version control system knows who committed what, the board knows who moved which card, the deploy log knows whose change failed.

## What goes wrong

**The numbers describe the system, not the people.** A developer's commit count depends on how their work was split, what they were assigned and how much of their week went to reviewing other people's changes and fixing an incident. A change failure attributed to the person who deployed it was usually caused by a test nobody wrote, a review that missed something and a deploy process that made rollback hard. Ranking people by those numbers measures their luck in assignments, not their contribution.

**People respond to what is measured.** This is Goodhart's law again, with a person at the end of it. Measure commits, and commits get smaller and more frequent. Measure lines of code, and code gets longer. Measure change failure rate per person, and people stop deploying anything risky, or start deploying through somebody else. Each response is rational for the individual and harmful for the team.

**Trust goes first.** A team that knows its numbers are used to rank its members stops discussing bad weeks honestly, and the improvement loop of this lesson's first section stops working, because nobody volunteers the finding that would make them look bad.

## SPACE

In 2021 Nicole Forsgren and colleagues from GitHub and Microsoft published the **SPACE** framework, an argument that developer productivity cannot be captured by any single number and needs several dimensions at once: **S**atisfaction and well-being, **P**erformance, **A**ctivity, **C**ommunication and collaboration, and **E**fficiency and flow. Its practical advice is to measure at least three dimensions together, to include perceptions gathered by asking people as well as data from tools, and to be wary of activity counts above all. The `delivery-metrics` course gives SPACE, and the trap of measuring an individual's productivity, a lesson of their own, its eighth.

## Rules that keep measures honest

A lead or an architect can hold the line with a few rules, stated openly:

- **Team-level only.** The measures describe the team; nobody's name appears on a delivery chart.
- **The team sees them first.** Numbers that go to management before the team has looked at them become a report card.
- **Trends, not targets.** "Our lead time doubled this quarter, why?" is a useful question; "lead time must fall 20%" is an invitation to game it.
- **Never in a performance review.** Individual performance is a conversation about behaviour and contribution, which the `people-leadership` course covers, and delivery numbers are the wrong evidence for it.
