---
title: Presenting risk with the numbers it rests on
version: 1
---

**A review's findings are only as strong as the numbers behind them, and a presentation is where
those numbers are either shown or lost.** Lesson 13 ended with a list of risks and a theme. This
section is about putting them in front of people who will decide on them.

## Lead with the theme

The directors did not see fourteen risks. They saw **one theme**, the station link, with the six
capabilities that depend on it, and the budget that Celeste's decision needed. The individual risks were in the
report, which they had, and on one backup slide, which nobody asked for.

For the engineers the order reversed: the theme in one slide, then the findings their teams owned,
each with its scenario and its owner. **The same review, presented at two altitudes**, which is the
rule of the first section of this lesson applied to findings.

## A number with its source

Every number on a slide needs a source the audience could check, or it is an opinion with digits.
Lesson 6's scenarios provide them:

| claim on the slide | the number | where it comes from |
| --- | --- | --- |
| the purchase path holds at the peak | 2,000 purchases a minute | QS-01, and a load test at 4,000 holds a minute |
| a station without its link stops selling | 26 stations, 1 link each | the inventory of station equipment |
| São João is the risk, not a normal Friday | about 4 times a normal day's tickets | last year's sales by day |

**Put the source on the slide, small, under the number.** It answers the first question before it
is asked, and it shows that the number was measured rather than hoped.

## The risk in the reader's unit

An engineer reads *one link per station* as a risk. A director reads it as nothing until it is put
in what the director counts: **passengers, money and days**. *If a station's link fails at 06:00 on
the Friday before São João, about forty people in that queue cannot buy a ticket there until it
comes back.* The architecture is the same; the unit is the reader's.

How to translate technical risk into business risk in general, with likelihood, impact and cost, is
`architect-communication` lesson 4. What belongs to this course is the thread back from that
sentence to the model: the forty people come from a scenario, the scenario names the element, and
the element is on the slide.

## Say what is uncertain

A presentation that claims more certainty than the review found will be found out at the first
question. *We measured the purchase path; we have not measured what happens when two stations lose
their links at once* is a stronger sentence than a confident one, because it tells the directors
exactly where their money buys certainty.
