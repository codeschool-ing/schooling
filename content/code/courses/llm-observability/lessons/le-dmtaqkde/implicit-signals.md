---
title: What customers do, as well as what they say
version: 2
---

Most customers never click a thumb. All of them do something next, and some of what they do is a
verdict on the reply. The two this week's simulated customers do are the ones support teams watch
most:

- **Asking again in other words**, in the same session, soon after. Somebody who got what they needed
  does not rephrase the question.
- **Asking for a person.** The clearest admission that the assistant did not help, and the most
  expensive, since a person's time is the cost the assistant exists to save.

Both are in the same `signals.py` table, as rates per hundred requests:

```
ana@dev:~/obs$ python signals.py
release    requests  rated  down  down % rephrased  person  per 100 requests
2026.09.4       134     32     5     16%       6.7     0.0
2026.10.1       141     26     4     15%      12.8     2.8
```

**Rephrasing nearly doubled, from 6.7 to 12.8 per hundred, and asking for a person went from none at
all to 2.8.** These are counted over every request, not over the quarter who rated, so they move on
far less noise than thumbs do, and here they saw what the thumbs missed. They are also harder to
game: no screen design changes how often a customer whose answer was a refusal asks again.

## Detecting them in real traffic

In this week the rephrasings are labelled, because `replay.py` wrote them. Real traffic arrives
unlabelled, and they have to be inferred:

- **a second question in the same session within a couple of minutes**, which is easy, and catches
  follow-up questions too;
- **whose embedding is close to the first one's**, which separates "how long do I have to return a
  book" followed by "return window for books" (a rephrasing) from the same first question followed by
  "and who pays the postage" (a follow-up). The similarity threshold is a choice like the floor, made
  the same way: on a sample somebody labelled by hand.

Asking for a person is usually an event the application already has: a button, a handover to the
support queue. It needs the trace id of the last reply attached, so that the reply that failed is the
one that gets counted, and that is a one-line change wherever the button is.

**The rule that ties these together:** a signal is only useful if it can be joined to the reply it
judges. A thumb with no trace id is a satisfaction survey. A handover with no trace id is a staffing
number. With the id, both are evaluations of particular answers, and lesson 13 turns the worst of
them into test cases.
