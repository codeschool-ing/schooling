---
title: A smoke list for boxoffice
version: 1
---

A smoke list is often built by taking the most important test cases and running them first. That
produces a list that is too slow, needs judgement to read, and fails for reasons that have nothing
to do with whether the build works. **A smoke check is chosen for a different quality: a failure
of it on its own means the build is not worth testing**, and a pass is decided in seconds by
somebody who has never seen the product.

## What makes a good smoke check

Each item on the list has to meet five conditions:

- it touches one major area, so that the list as a whole covers them all;
- it follows that area's main path, with ordinary data, and nothing unusual;
- its expected result is written down and can be seen at a glance, a page title, a line, a number;
- it does not depend on any other check having passed, apart from the server being up;
- it gives the same answer whenever it runs, whatever the day and the time.

The last condition is easy to break without noticing. boxoffice closes booking for a show one hour
before it starts, and The Seagull starts at 20:00 on the day the application starts. A smoke check
that books The Seagull passes all afternoon and fails every evening after 19:00, for a reason that
says nothing about the build. **That is why boxoffice's booking check uses Hamlet**, a week away,
which can be booked at any hour.

## The five checks

| check | what it proves | requirement |
|---|---|---|
| `/health` answers `ok boxoffice` | the server is up, and which version it is | the plan's entry criterion |
| the home page lists the three shows | the catalogue of shows loads and is drawn | R1 |
| the sign-up page loads | the sign-up form is served | R2 |
| the member books two tickets for Hamlet | an order is created, the heart of the product | R4 |
| the outbox opens | the test build's mail stop answers | lesson 1 section 04 |

Each one is the shallowest version of a whole area. The home page check looks for three titles and
not for their dates, prices or seats, which are R1's cases. The sign-up check asks whether the form
is there, not whether an account can be created with it; creating one would need a new address on
every run, and the confirmation link that follows is lesson 22's. The booking check is the one
deeper step on the list, because booking is what the theatre bought the system for, and a build
where nothing can be booked is not worth an afternoon of discount cases.

## What is left out, on purpose

Just as much of the product is outside the list, and each omission has a reason:

| left out | why it is not smoke |
|---|---|
| prices and discounts | many cases, with arithmetic to check; lesson 5's decision table |
| wrong input | dozens of values and judgement about each message; lesson 4 |
| the life of an order | several steps that depend on each other; lesson 5's state transitions |
| the phone layout | needs a browser at a set width and a person looking; lesson 7 |
| the confirmation e-mail and link | needs a new account and a second step; lesson 22 |

None of these is less important than the five on the list. They are the subject of the testing
that smoke decides whether to start, and **a defect in any of them makes a build worse, not
untestable**.

## How long a list

For boxoffice, five checks and about two minutes by hand. A larger product has a longer list, ten or
twenty checks for a web shop with search, basket, payment and accounts, and the same rules: one
check per area, main path, seconds each. Teams that find their smoke list creeping towards fifty
items have usually let cases in, and the cure is to ask of each item whether its failure alone
would stop testing.

The list belongs with the test cases, under version control or in the case tool the team uses, and
it changes when the product does. When a new area arrives, a reviews page for each show, say, the
question is whether the product is still worth testing if that area is dead. If yes, it needs no
smoke check. If no, it gets one.
