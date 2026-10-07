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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l04-kept\" aria-label=\"The part of PASTA Vereda kept. Stage 1, the business objectives, revised once a year with daniel. STRIDE does the work of stages 3 to 5 on each change. Stage 7, the ranking by business impact, is applied to anything new on the list.\"><defs><marker id=\"l04-kept-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"210.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"125.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stage 1</text><text x=\"125.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">once a year, with daniel</text><path d=\"M230.0 80.0 L255.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-kept-tm-ah-paper-dim)\"></path><rect x=\"255.0\" y=\"40.0\" width=\"210.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stages 3 to 5</text><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">STRIDE, on each change</text><path d=\"M465.0 80.0 L490.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-kept-tm-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"40.0\" width=\"210.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">stage 7</text><text x=\"595.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">for anything new on the list</text><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">STRIDE inside a PASTA frame</text></svg>", "caption": "The business stages are the cheap ones to keep and the expensive ones to lose."}
```
