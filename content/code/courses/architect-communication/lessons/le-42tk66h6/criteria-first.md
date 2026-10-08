---
title: Agree the criteria before the options
version: 1
---

**When two engineers disagree about a design, agree what a good answer must do before discussing any
answer.** Arguing about options first means each side defends the option it arrived with, and every
argument is a judgement about criteria that were never stated. Agreeing the criteria first turns
the argument into a comparison.

## The second disagreement

The quota settled one argument and revealed another. Logistics wanted to stop reading checkout's
tables directly and asked for an event stream of new orders. Paulo wanted a message broker; Bruna
wanted checkout to write the events to a table in its own database, an *outbox*, that logistics would
read. Both are reasonable designs, both have advocates in every engineering team, and the
conversation was heading for the same thread as before.

Lívia asked them to write, together, what the solution must do, before either design was mentioned
again:

| criterion | weight | why |
|---|---|---|
| no order event is lost, even if a service crashes | must | orders are money |
| checkout's latency does not rise at peak | must | the whole point of this year's work |
| logistics receives an order within 10 seconds | 3 | route planning runs in batches; seconds do not matter |
| operable by the current platform team | 3 | there are three people on it |
| other teams can consume the events later | 2 | data team has asked |
| cost under R$ 3,000 a month | 2 | the budget line approved in March |

**Writing the weights was where the real disagreement surfaced**: Paulo had been weighting "other
teams can consume the events" very high, because he expected three more consumers soon; Bruna had
been weighting "operable by the current team" highest, because her team would be paged. Neither had
said so. Once it was on the table, they could argue about it directly, and the data team settled it
by saying they would not need events for at least a year.

## Scoring, and its limits

Scored against the table, the outbox came out ahead on operability and cost, the broker on future
consumers. With the weights agreed, the outbox won, and Paulo agreed it did, given the weights.

A decision matrix is a tool for making the disagreement visible, not a machine that produces
answers. **If the numbers come out against a choice everybody believes in, the weights are probably
wrong, and the useful conversation is about which one.** And close scores mean the options are
genuinely close: pick one, write down why, and stop arguing.

## Write it down

The outcome went into a decision record, lesson 2's format: the context, the criteria and weights,
the options considered, the decision, and what would make it worth revisiting ("a third consumer of
order events, or the outbox table growing past what one database can hold"). Paulo's preference for
a broker is recorded as an alternative considered, with the reason it lost **at these weights**.
When the weights change, he has a document to point at rather than a grievance.
