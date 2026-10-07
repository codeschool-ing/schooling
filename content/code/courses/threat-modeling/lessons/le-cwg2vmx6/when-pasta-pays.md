---
title: When PASTA pays for itself
version: 1
---

PASTA costs more than STRIDE: more stages, more people, more documents, and a business owner who
has to give up a morning. The cost is worth paying when one of these is true:

| situation | why PASTA helps |
|---|---|
| the system's risk is mostly **business** risk: money, regulation, reputation | stages 1 and 7 tie every threat to what the business stands to lose |
| the people who decide what gets fixed are **not technical** | the ranking comes with reasons in their own terms |
| the organisation has **threat intelligence** worth using | stage 4 has a place to put it |
| findings from scanners and pentests need **joining** to the model | stage 5's CWE column is the join |
| the system is **large and changes slowly** | the documents stay valid long enough to pay back their cost |

And it is the wrong choice when:

- **the team needs an answer this week** for one feature. STRIDE on the feature's flows is an hour.
- **nobody from the business will come.** Stages 1 and 7 done by engineers alone are guesses about
  somebody else's priorities, and the result looks authoritative while being exactly as subjective
  as an unranked list.
- **the system changes every sprint.** Seven documents per change become a reason not to model at
  all, which is the worst outcome of any.

### What Vereda kept

Vereda is four clinics and a part-time security consultant, and it does not run full PASTA for
every change. What it kept is the part that cost least and changed the most:

1. **Stage 1, revised once a year with daniel**: the five objectives and what failing each costs.
2. **STRIDE for stages 3 to 5**, per element on the whole system and per interaction on the
   boundaries that matter, as in lesson 3, with a CWE column when a weakness is known.
3. **Stage 7 for anything new on the list**: which objective it threatens, and where it sits in
   the ranking.

That is a common shape for a small organisation, and it has a name in practice, if not in the
book: *STRIDE inside a PASTA frame*. Lesson 15 turns the third step into part of how features
are refined.
