---
title: The checklist, and what it is for
version: 1
---

**A review checklist is a list of questions that experienced reviewers ask every time, written down
so that they are asked even when the reviewer is tired, new or in a hurry.** It does not replace
judgement; it makes sure judgement is applied to everything rather than to whatever caught the
reviewer's eye first.

## Carcará's checklist

Tainá's checklist grew out of the risks found in reviews, one question per kind of risk that had
reached production once. It has six groups:

| group | questions |
| --- | --- |
| **requirements** | Which quality scenarios does this change affect? Are their measures still met, and how do we know? Is any significant requirement left without a verification? |
| **decisions** | Which decisions does this rely on or change? Is there a record for each hard-to-reverse choice, with options and consequences? |
| **failure** | For each call across a network, what happens if it is slow, fails or answers twice? Where are the timeouts, and do they nest correctly? |
| **data** | Who owns each piece of data? What happens to existing data when the shape changes? Is personal data covered by the erasure and export paths? |
| **operations** | Who is paged when it breaks, and what do they see? How is it deployed, and how is it rolled back? What does it cost per month at peak? |
| **documents** | Are the affected diagrams updated in the same change? Does each have an owner and a date? Do the fitness functions cover the new rules? |

Every question traces back to something this course built: scenarios to lesson 6, records to lesson
5, failure to the sequence reading of lesson 2, documents to lesson 11. **A checklist is the course
compressed into questions**, and that is its value: a reviewer who knows the reasons behind each
question can judge when a *no* matters.

## Rules for a checklist that stays useful

- **Short enough to use.** Atul Gawande's *The Checklist Manifesto* argues for lists that fit on a
  page and cover the steps people actually skip. Carcará's has twenty questions.
- **Questions, not instructions.** *Are the timeouts nested correctly?* can be answered yes or no and
  discussed. *Use correct timeouts* cannot.
- **Each question earned.** A question is added when a risk of its kind reached production, and
  removed when nobody has answered *no* to it in a year.
- **Owned and dated**, like every page in lesson 11. A checklist nobody maintains becomes a ritual.

## The checklist is not the review

A team that runs through twenty questions and ticks them has done a checklist, not a review. **The
questions are where the review starts**: each *no* or *not sure* is a thread to pull, with the
scenarios in hand. The station link risk theme from this lesson did not come from a checklist
question; it came from following three different *not sure* answers until they met.
