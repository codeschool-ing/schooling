---
title: How reviews go wrong
version: 1
---

**Most failed reviews fail for social reasons rather than technical ones**: the wrong people, the
wrong moment, the wrong purpose. Five patterns are common enough to name.

## The rubber stamp

The review happens after the design is built, or after the contract is signed, and everybody in the
room knows nothing will change. It produces *approved* and nothing else. **The cure is timing**:
review before the commitment, as this lesson's first section said, or say honestly that it is a
retrospective and treat it as one.

## The gate

The review is a hurdle every team must clear, run by people who are not responsible for the outcome.
Teams learn to present designs that pass rather than designs that work, and to avoid the review
when they can. The architecture board of lesson 8 risks becoming this; **the cure is that the
reviewers' answers are predictable from written principles**, as that lesson put it, and that the
review finds problems for the team, not about it.

## The ivory tower

The reviewers have not seen the system run and judge it against a picture in their heads. Their
findings are about patterns rather than about scenarios, and the team cannot act on them.
`architecture-role` lesson 17 named this antipattern for architects in general. **The cure is
scenarios**: every finding tied to one, so that a finding nobody can tie to a scenario is recognised
as a preference.

## Bikeshedding

The review spends an hour on the naming of an endpoint and five minutes on the database failover,
because everybody has an opinion about names and few have one about failover. The term comes from C.
Northcote Parkinson's example of a committee that approves a power plant quickly and argues at length
about the bicycle shed. **The cure is the utility tree**: time goes to the (H, H) scenarios first, by
agenda.

## The missing voice

The review includes architects and engineers and nobody from operations, support or the business,
so the scenarios are the architects' scenarios. ATAM's step 7 exists because of this. At Carcará,
the most important scenario of the São João review came from a station agent. **The cure is to
invite the people who live with the system**, even for an hour, even to a light review.

## A review of the review

After each review, Tainá asks the team two questions: *did anything we found change what you did?*
and *was there something we should have looked at and did not?* The answers decide whether the next
review is longer, shorter or different, which is lesson 11's rule applied once more: **a practice
that is not checked becomes a ritual**.
