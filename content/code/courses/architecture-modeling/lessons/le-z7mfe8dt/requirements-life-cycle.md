---
title: The life of a requirement: trace, prioritise, change, approve
version: 1
---

**A requirement is not finished when it is written. It is traced, prioritised, changed and approved,
and BABOK's Requirements Life Cycle Management area is about doing that deliberately.** Most of it is
lesson 6's traceability with a governance layer on top.

## Prioritising with MoSCoW

Of the prioritisation techniques in the guide, **MoSCoW** is the one you will see most:

- **Must have**: without it, the solution does not meet the need. *Match card and Pix payments.*
- **Should have**: important, but there is a workaround. *Match refunds automatically*: Joana can
  still match them by hand for a while.
- **Could have**: desirable, done if time allows. *A chart of mismatches per week.*
- **Won't have this time**: agreed to be out of scope for now, written down so it is not forgotten.
  *Reconciling cash at the stations.*

The fourth category is the important one. **Writing down what will not be done** turns a silent
omission into a decision somebody can question, which is lesson 5's argument about recording rejected
options, applied to scope.

A practical rule, from the DSDM method where MoSCoW comes from: if the Musts are more than about
60% of the effort, the plan has no room for anything to go wrong.

## Change control

Requirements change, and they should: a requirement that never changes was probably never examined.
What BABOK asks for is that **a change is assessed before it is accepted**: what does it affect,
upstream and downstream along the trace? When the payment company announced its new settlement file
format, the trace from *read the settlement file* led to two solution requirements, one transition
requirement and ADR-0019, so the cost of the change was known in an afternoon.

## Approval

Each requirement, or each set, has an approver, from the RACI in the stakeholders section. Approval is
not a signature on a long document; it is **a recorded decision that this version of these
requirements is the basis for the work**, so that a later change is visible as a change. In a
repository-based team it can be as light as a merged pull request on the requirements file, with the
approver as reviewer, which is the same mechanism as lesson 5's decision records.
