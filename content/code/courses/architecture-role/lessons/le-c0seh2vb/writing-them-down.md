---
title: Writing requirements so they can be checked
version: 1
---

**A requirement nobody wrote down is renegotiated every time somebody remembers it differently.**
Write each significant one as a scenario with a measure, keep all of them on one page, name the
person and the goal behind each line, and read the page back to whoever asked. The page is short,
and it is the thing every later decision about the feature points at.

The common failure is not that nothing is written. It is that what gets written is the request
itself, adjectives included — "the booking flow must be fast and highly available" — in a document
that looks finished and cannot be checked. Six months later the flow takes 40 minutes to confirm a
truck, and everybody involved can argue that it is fast.

## A quality attribute as a scenario

Lesson 6 gave quality attributes a six-part form: source, stimulus, environment, artefact, response
and response measure. It was used there to compare designs. Here it does a different job: **it turns
what Helena said into a sentence a test, a dashboard or a reviewer can hold the design to.**

Helena's "fast", after the questions of the previous section:

| part | the confirmation scenario |
|---|---|
| source | a shipper |
| stimulus | requests a truck for a full load on a main corridor |
| environment | business hours, on an ordinary weekday |
| artefact | the booking flow: Shipper app, Matching and Driver app |
| response | a driver commits to the load and the shipper is told a truck is coming |
| response measure | within 15 minutes for 90% of requests and within 60 minutes for 99%, measured each month |

Each part earns its place. **The environment stops the number being read as a promise for every
hour of the year**: a Saturday-night part load is outside it on purpose. The artefact names what is
being measured, which here crosses three teams, and that alone says the scenario needs an architect.
The response says "committed", not "arrived", because that is what the dispatcher at the event
storming said she was waiting for. And the measure has two thresholds, because a 90% target says
nothing about the tenth shipper, and the tenth shipper is the one who phones a competitor.

The table is the long form. Once the parts are clear, most scenarios fit in a sentence, and the
sentence is what goes on the page:

> When the database server behind the booking flow fails during business hours, the flow is
> serving shippers again within 10 minutes and no confirmed booking is lost; downtime in business
> hours adds up to no more than 109 minutes a month.

> When a driver with no signal records a delivery proof, the Driver app keeps it on the phone and
> it reaches Tracking within 5 minutes of the phone getting a connection back, with nothing lost.

Notice what the second one does not say. It does not mention a local database on the phone, a sync
protocol or a queue. **A requirement says what has to be true, not how to make it true.** The how is
the design, and keeping it out of the requirement leaves Diego's team free to find a better one.

## Requirements that pull against each other

Written down, two requirements can be seen to collide, which is much cheaper on paper than in
production. Offering a load to several drivers at once is the obvious way to meet the 15 minutes.
But Diego knew something the shippers' side did not: **a driver who taps "accept" and is told the
load has gone feels cheated**, and drivers who are cheated often enough stop opening offers.

So the driver's side got a requirement of its own: a driver who taps "accept" learns within 2
seconds whether the load is theirs, and the share of acceptances that end in "already taken" stays
under one in five. Now the two can be traded openly. Offering each load to twenty drivers at once
would confirm trucks fastest and lose the most acceptances; offering it to one is today's 47
minutes. The design Kátia proposed offers it to three at a time, nearest first.

The trade is a business decision, and **it went to Helena, with both numbers on one page.** The
architect's part was to make the conflict visible and say what each choice costs, which is the same
division of work lesson 13 makes the centre of the whole conversation about quality, deadline and
cost.

## The one page

Everything significant about the request fits on one page, and Renata kept it to one. Here is the
part that holds the requirements:

| id | requirement | asked by | why | measure |
|---|---|---|---|---|
| R1 | a driver commits to a full load on a main corridor soon after the request | Helena | conversion from 30% to 40% of quotes | 90% within 15 min, 99% within 60 min, business hours |
| R2 | a driver who accepts learns whether the load is theirs | Diego | drivers keep opening offers | answer within 2 s; under 1 in 5 told "taken" |
| R3 | the booking flow survives the loss of its database server | Helena | bookings are lost when it is down | back within 10 min, nothing confirmed lost, at most 109 min down a month in business hours |
| R4 | a delivery proof is recorded with no signal | Diego, Bruno | drivers are paid on proof | reaches Tracking within 5 min of reconnecting, nothing lost |

Below it, the constraints, which are not up for discussion in this project and are written down so
that nobody rediscovers them halfway through:

- a quote is never below the ANTT minimum freight floor for its route and vehicle;
- a truck does not leave before SEFAZ has authorised the CT-e;
- live before the harvest peak, on 2 February;
- built by the Matching team as it is, six engineers, with help from the Driver app team.

A few rules made the page work:

- **Every line names a person and a goal.** When somebody wants to relax R2 to speed up R1, the page
  says whom to ask and what they will lose.
- **Numbers, not adjectives.** "Fast" and "highly available" appear nowhere on it.
- **No solutions.** "One screen" was Helena's first sentence, and it is not on the page. It became
  one of the design options for showing the shipper what is happening while a driver decides, which
  is where it belongs.
- **A date and a version at the top**, because the page will change and a reader has to know which
  one they are holding.

The requirements also carry ids, and the ids are for later. An architecture decision record, which
lesson 5 introduced, cites them in its context: "to meet R1 and R2, Matching offers each load to
three drivers at once". Whoever reads the decision in two years can then find the requirement that
caused it, and whoever changes the requirement can find the decisions that rest on it.

## Reading it back

Renata sent the page to Helena and booked thirty minutes to read it together, line by line. **Reading
back is where misunderstandings are cheapest to find**, and this one found one. The first draft of
R1 named the twelve corridors that carry most loads today. Helena pointed out that the list changes
with the season: in February the grain routes from the north of Paraná overtake half of them. R1 now
says "the corridors that together carry 80% of the month's loads", which is how Helena thinks about
it and stays true when the list moves.

The point of the meeting is not a signature. **It is two people agreeing on the same numbers**, so
that when a design is presented the conversation is about whether it meets R1 rather than about what
R1 meant.

## After it ships

A requirement with a measure can be measured, and should be. R1 is a chart now: the share of
requests confirmed within 15 and within 60 minutes, per week, on the main corridors. The
instrumentation is the kind `scale` lesson 7 taught. **A requirement nobody measures after launch is
a wish**, and the first time it slips nobody will know until a shipper complains.

The page itself is a living document of the kind lesson 8 is about: it has an owner, a date, and a
reason to be updated when something changes. `architecture-modeling` lesson 6 goes further into
quality attributes and how fuller requirement documents are organised. For an architect, one page
of numbers that the business recognises as its own is worth more than fifty that it does not read.
