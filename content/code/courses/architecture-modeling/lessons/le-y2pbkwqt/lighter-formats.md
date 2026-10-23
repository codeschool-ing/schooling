---
title: Lighter formats, and when a record is too much
version: 1
---

**The full record is the right weight for a decision that is expensive to reverse. For smaller ones,
lighter formats keep the reasoning without the ceremony**, and a team that has only the heavy format
ends up recording nothing.

## The Y-statement

Olaf Zimmermann and colleagues proposed a one-sentence form, named for the shape it makes when laid
out in lines:

```localised
In the context of   <the situation or use case>,
facing              <the concern or force>,
we decided for      <the chosen option>
and neglected       <the alternatives>,
to achieve          <the benefit or quality>,
accepting           <the downside>.
```

Carcará's seat-hold decision in that form:

> In the context of **holding seats while a passenger pays**, facing **hold traffic that is 40% of the
> booking database's writes at peak**, we decided for **one Redis key per seat with a ten-minute
> expiry** and neglected **tuning the database and a separate inventory service**, to achieve **a
> booking database with headroom before São João**, accepting **that a Redis restart loses the holds
> in flight**.

Every part of a full record is there, compressed. **A Y-statement is a good test even when you write
the full record**: if you cannot fill in the *accepting* line, you have not yet found the decision's
cost.

## Other light forms

- **A decision table inside a design document.** One row per decision: the question, the options, the
  choice, the reason, the date. Good for the dozen small decisions a feature makes on the way.
- **A pull request description that links to the forces.** For a decision local to one service, the
  PR that implements it, with a paragraph of *why*, may be the right home. It is searchable and it
  sits next to the change.
- **A comment in the code**, for a decision about one function: *we sort in memory here because the
  query planner picks a sequential scan above 10,000 rows; measured 2025-03.* It dies with the code,
  which is correct for a decision about the code.

## Choosing the weight

| the decision | its weight |
| --- | --- |
| crosses teams, hard to reverse, people will ask about it for years | a full record |
| inside one team, reversible in a sprint, still worth remembering | a Y-statement or a row in a decision table |
| inside one service, visible in the change | the pull request's description |
| inside one function | a comment beside it |

What matters is that the reasoning is somewhere a successor will find it. **An unrecorded decision
is not undecided; it is decided by whoever touches the code next**, with none of the forces in view.
