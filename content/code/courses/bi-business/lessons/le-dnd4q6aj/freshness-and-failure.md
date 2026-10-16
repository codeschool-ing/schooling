---
title: Freshness, and the board that fails
version: 1
---

An operational board is acted on within minutes of being read. That makes it the most useful screen
a company has and also the most dangerous one, **because a wrong number on it turns into a wrong
action before anybody checks it**. Two properties protect it: data fresh enough for the decision, and
a board that says so plainly when its data has stopped arriving.

## Fresh enough is set by the decision

The usual wish is for real time. It is rarely what the decision needs. Marcos looks at the board and
acts every fifteen to thirty minutes, so data copied from the drivers' app every ten minutes is fresh
enough: by the time he could act on a newer picture, the next copy has arrived. Copying every few
seconds would take a different kind of pipeline, cost more to build and run, and change nothing he
does.

**The rhythm of the decision sets the freshness, not the other way round.** It is lesson 2's argument
about the value of information, applied to time: data that arrives sooner is worth paying for only if
somebody would act differently because of it. The monthly review in lesson 15 is perfectly served by
yesterday's data, and a board for the bed manager of a hospital (lesson 19) by data a few minutes old.

## The time of the data, on the screen

Every operational board carries the time its data describes: "data from 11:00 · 2 min old". The age
matters more than the time, because nobody at a loading bay subtracts clock times in their head.
**And it is the time of the data, never the time the page was opened.** A browser always shows the
present, so a page loaded at 11:05 that shows the 09:20 picture looks exactly as current as one that
is right.

## The morning it stopped

On Tuesday 3 February 2026 the company behind the drivers' app changed the format of its export
overnight. Tiago's pipeline, which copies the deliveries into Varanda's database every ten minutes,
copied nothing from 09:20 onwards and reported no error, because from its side there was simply
nothing new to copy.

The board kept showing the 09:20 picture. At 09:20 nobody was behind yet, so every route sat close to
its plan and the exceptions list was empty. For **105 minutes** the most watched screen in the
warehouse said that all was well, until a customer in Betim rang the Contagem store at 11:05 to ask
where her sofa was. **A frozen board does not look broken. It looks calm**, and calm is exactly what
Marcos had no reason to question.

## A board that knows its own age

The fix was not a better pipeline; pipelines stop. It was a rule on the board: **if no copy has
arrived for 20 minutes, the numbers go and a warning takes their place.** Twenty is twice the copy
interval: one missed copy can be a hiccup, two in a row is a failure. The warning says what is known
and what to do:

> No new data since 09:20 (105 min ago). The numbers below are hidden. Call the drivers directly.

Hiding the numbers is deliberate. A board that shows old numbers in grey with a small warning in the
corner is still read as current from the loading bay. The same rule sends a second alert, to Tiago,
because he owns the pipeline and Marcos cannot fix it. An alert that goes to somebody who can only
watch is the notification of the previous section, once again.

## The other two ways a board goes wrong quietly

A copy that stops is the easy failure, because it can be timed. Two others give numbers that look
fine:

- **Some of the data is missing.** One driver's phone runs out of battery and route 9 stops sending.
  Its stops vanish from every count. The chips under the exceptions exist for this: the board expects
  fourteen routes and 286 orders, and shows a warning when fewer arrive.
- **Some of the data arrives twice.** A copy that runs twice after a restart puts every order in the
  database two times, and the board announces 572 orders for the day. The check is the same kind: a
  total that jumps against the plan for the day is a data problem until shown otherwise.

None of these checks needs a statistician. Each one compares what arrived with what was expected, and
**says so on the screen instead of showing a number that is wrong**. The engineering side — retries,
alerts on the pipeline itself, the job that failed at three in the morning — is `pipelines-etl`
lesson 10, and who owns the quality of the data is `data-governance` lesson 9.

## What the three sections add up to

The question decides the board: Marcos's question gave a list of exceptions, not a chart of months.
The threshold decides the alert, and it is chosen by counting what each line would have done on a
real day. And the board has to know when it is wrong, because the people who use it act at once.
Lesson 15 moves up a level, to a manager who reads her screen once a month and has days, not
minutes, to act.
