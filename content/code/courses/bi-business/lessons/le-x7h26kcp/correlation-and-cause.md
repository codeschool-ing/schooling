---
title: Correlation, cause, and the honest sentence
version: 1
---

A diagnosis ends in a sentence with "because" in it, and that word claims more than most data can
show. **Two things moving together is a correlation. One making the other happen is a cause.** The
gap between them is where most confident diagnoses go wrong, and a BI analyst needs to recognise it
without the statistics that measure it, which are `statistics` lesson 18.

## Two things that move together

Here is a correlation Varanda's data shows every year. The months in which the company spends most
on online advertising, November and December, are also its two best months for sales. Lay spend and
sales side by side and they rise and fall together.

The tempting reading is that the advertising caused the sales, so more advertising in March would
make March look like December. **The data cannot say that, because something else drives both.**
Varanda spends more in November and December *because* those are the months people buy furniture
and gifts; the season raises the sales and the season raises the budget. A third thing that moves
both of the things you are comparing is called a **confounder**, and the season is the commonest one
in retail. If it were taken away, the correlation between spend and sales might shrink to almost
nothing, or it might not. The side-by-side cannot tell you which.

The same trap was open in October. At the Monday meeting somebody blamed the rain. Suppose October
2025 was the rainier of the two: then rain and the fall in online orders moved together. But rain
would push people from the stores towards the website, not away from it, and the stores grew. The campaign
explained the timing of the fall day by day; the rain explained nothing that the campaign had not.

## What makes a cause more believable

Without an experiment, a diagnosis never proves a cause. It makes one more or less likely, and the
things that make it more likely are the ones Lívia used:

- the timing fits: the missing orders match the campaign's eleven days, and they reappear
  in November, where the campaign went;
- the place fits: the fall is in the channel the campaign runs in, and nowhere else;
- the mechanism fits: fewer orders at the same ticket is what losing a campaign looks like, and a
  price change or a broken pipeline would have looked different;
- the other suspects were tested, and failed.

An experiment is the stronger evidence: run the campaign for half the customers and not for the
other half, and compare. Lesson 18 does that with a holdout group. A diagnosis of something that
already happened rarely gets one, which is why the wording matters.

## The honest sentence

Compare two versions of Lívia's finding:

| | the sentence |
|---|---|
| overclaims | "October fell because the campaign moved to November." |
| honest | "October's fall is in online orders only, at an unchanged ticket, and it matches the eleven campaign days of October 2024; ordinary days grew 12.4%. We checked the calendar, prices, stock and the data pipeline, and none changed. October and November together grew 3.9%, below the year's 5.7%, and that gap is not yet explained." |

The second is longer and it is the one Helena can act on. It says **what was found, what it is
consistent with, what was checked and ruled out, and what is still open**. "Consistent with" is not
a hedge for its own sake. It tells the reader that the evidence fits this cause and that nobody ran
an experiment. And "we checked" turns a list of suspects into a list of facts. Lesson 8 takes the
same habit forward in time: a forecast, like a diagnosis, has to say how sure it is.
