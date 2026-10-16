---
title: Two questions, and what answers them
version: 1
---

Whoever answers for a team gets asked two questions more often than any other: **"when will it be ready?"** and **"how are we doing?"** Most teams answer both with an opinion. The opinion is usually given in good faith, by somebody close to the work, and it is usually wrong in the same direction: things take longer than the person closest to them believes.

This course answers both questions with something else: **the record the team already keeps**. A board records when each item was started and when it finished. A pipeline records every deployment and whether it failed. An incident tracker records when a problem began and when it ended. Nothing in this course asks a team to collect a new kind of data. It asks them to read what they have, and to stop answering from memory.

## What the course covers

The twenty lessons fall into five parts, and each part leans on the one before it.

| lessons | the subject | the question it answers |
|---|---|---|
| 1 to 4 | **flow**: work in progress, cycle time, cumulative flow, limits | where does the time go? |
| 5 to 8 | **the four DORA metrics**, what they miss and how they are gamed | how good is our delivery? |
| 9 to 12 | **forecasting**: estimates, Monte Carlo, roadmaps, capacity | when will it be ready? |
| 13 to 18 | **incidents and on-call**: severity, command, postmortems, error budgets, the pager | what happens when it breaks? |
| 19 and 20 | **reporting**, and what the numbers may be used for | what do we tell the people above us? |

The course assumes `process-management`, so a board, a work-in-progress limit and a story point are not explained again. What that course introduced in one lesson, this one measures in twenty.

## The team you will measure

Every number in the course comes from one team, and **the team does not exist**. It is the Billing team of a company that sells a point-of-sale system to small shops: five developers, Caio, Duda, Inês, Rafa and Téo, and a tech lead, Bia. They own invoices, card charges and the monthly statement, which means that when they break something, a shop owner is charged twice.

Their history runs from 1 June to 30 September 2026, and it is written by a short program you will run on your own computer in this lesson's fifth section. The program simulates the team's board one working day at a time, with fixed random numbers, so your copy of the history is identical to the one the lessons quote. Because the team is simulated, you can also change how it works and watch what happens to the numbers, and lesson 4 asks you to do exactly that.

In June and July the team worked the way many teams do. Each developer kept up to three items open and switched between them, and Bia reviewed everything before it merged. On **3 August** they changed two rules: one item per developer, and reviewing a colleague's work comes before starting anything new. A good part of the course is about what that change did, what it did not do, and how you would know.

## Why history beats opinion

A history is not a better guess. It is a different kind of answer. An estimate says what somebody expects; a history says what the system actually produced, including every interruption, every review that waited a day and every item that turned out to be twice the size anybody thought. **None of that is in an estimate, and all of it is in the dates.**

That is also the limit of the method. A history describes the system that produced it. If the team changes how it works, the old history describes a team that no longer exists, and the Billing team's 3 August is exactly that kind of change. Knowing which part of the record still applies is half of the skill, and it starts in this lesson.
