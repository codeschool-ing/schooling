---
title: Where the analyst stops and the architect starts
version: 1
---

**The business analyst owns the question *what is needed and why*; the architect owns *how the
system will provide it, and what that costs*.** The two meet in the middle, at solution requirements
and design options, and most of the trouble between them happens where nobody decided who owns that
middle.

## The overlap, concretely

| | the analyst | the architect |
| --- | --- | --- |
| needs and business goals | leads | listens; asks what the goal is worth |
| stakeholders | identifies, maps, engages | adds the technical ones: Platform, Payments, the auditors' tools |
| functional requirements | elicits and writes | checks that each can be built and tested |
| quality attributes | elicits the business's numbers | turns them into scenarios, rates difficulty |
| design options | describes the business impact of each | proposes them, and records the decision |
| transition requirements | elicits | designs the migration and the parallel run |

## Three failures at the border

- **The analyst designs.** A requirement that says *the job reads the settlement file from an SFTP
  folder every night at 03:00* has decided the architecture inside a requirements document. The
  architect's question back is *what is the need?*, which is lesson 6's *what, not how*.
- **The architect ignores the business.** A technically excellent reconciliation that matches
  everything the gateway sends, and nothing that happens at the counter, meets every solution
  requirement and fails the business one.
- **Nobody owns the quality numbers.** The analyst assumes the architect will set them; the architect
  waits for the business. *Completes by 07:00 on a São João day* was written only because Tainá asked
  Joana when she starts work.

## When there is no analyst

At Carcará, as in most companies of its size, there is one analyst, Joana, and she works mostly for
Finance. On the other teams **the architect or a tech lead does business analysis without the title**.
Doing it on purpose means borrowing the minimum from this lesson: the six core concepts on one page,
a stakeholder list that includes the people nobody invited, at least one observation rather than
only interviews, the four classes so that transition requirements are not forgotten, and MoSCoW with
the *won't* written down.

**Draw it yourself.** Pick a change you know, at work or in a course project. Fill in the six core
concepts on one page, list the stakeholders and place them on an influence and interest map, and
write one requirement of each of the four classes. The class you find hardest to fill is usually the
one your project is missing.
