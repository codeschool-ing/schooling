---
title: Saying how sure you are
version: 1
---

**A risk estimate is a judgement, not a measurement, and the reader is owed both the number and
how much to trust it.** Engineers tend to fail in one of two directions here: they refuse to give
a number because they cannot be sure, or they give a single confident number they cannot defend.

## Give a range, and say what it rests on

"Two to four times a year" is more useful than "three times a year" and much more useful than "we
cannot predict that". A range does three things a single number cannot:

- it **shows the uncertainty**, so the decider can plan for the high end if the cost of being wrong
  is large;
- it **invites the right question**, "what would put us at the high end?", instead of a challenge to
  the number itself;
- it **survives being wrong**: if the event happens once next year, the estimate was not
  disproved, and the writer is not discredited.

`process-management` lesson 9 teaches three-point estimates (optimistic, likely, pessimistic) for
effort. The same habit works for risk: a low, a likely and a high, each with a sentence of
reasoning.

## Separate what is measured from what is judged

In Lívia's tables, every row is one of two kinds, and the document says which:

| measured | judged |
|---|---|
| 9,000 checkouts per Friday evening | two to four full stops a year |
| 2% fail | about thirty minutes until somebody intervenes |
| 60% of failed customers come back | that the replica removes the problem "for the foreseeable growth" |

**Mixing the two without labels is how a careful estimate gets dismissed.** A reader who finds one
judgement presented as a fact will treat every number in the document as a judgement.

## Say what would change your mind, and what it costs to find out

The strongest sentence in an uncertain estimate is the one that says how to make it less uncertain:

> We do not know how close to the limit a normal Friday in May will be, because volume grows with
> the season. Two weeks of measuring connections per service, which costs nothing but a dashboard,
> would tell us whether April is urgent or whether the work can wait until June.

That is a third option beside "approve" and "reject": **pay a small, known amount to reduce the
uncertainty before the big decision.** Decision-makers like it, because it is usually cheap and it
lets them decide on better information. It is only honest when the information would actually
change the decision. Measuring something whose answer would not change anything is delay with a
spreadsheet attached.

## Confidence words, and what they mean

Words like "likely" and "probably" are read very differently by different people. Studies of how
readers interpret them, starting with Sherman Kent's work for the CIA in the 1960s, found the same
phrase taken to mean anything from a small chance to a near certainty. Kent proposed attaching rough
percentages to the words, and many intelligence and risk teams now do. This is the version Marola
uses in its incident and risk documents:

| word | roughly |
|---|---|
| almost certain | over 90% |
| likely | 60 to 90% |
| about even | 40 to 60% |
| unlikely | 10 to 40% |
| remote | under 10% |

Whatever scale is used,
**define it once and use it consistently**: "likely" should mean the same thing in the risk
register in March as in the incident report in May.
