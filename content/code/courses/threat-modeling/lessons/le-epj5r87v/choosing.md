---
title: Choosing a method
version: 1
---

Five methods in three lessons is enough to make any team argue about which one to use. The
argument is mostly unnecessary, because **they answer different questions**, and most real models
use two or three of them for different parts of the work.

| method | it answers | reach for it when | its main limit |
|---|---|---|---|
| **STRIDE** | what can go wrong with each part? | always, as the first pass over a DFD | no ranking; blind to chains |
| **PASTA** | what matters most to the business, and why? | the people who decide are not technical, or risk is mostly business risk | expensive; needs the business in the room |
| **LINDDUN** | what harm does the system do to people's privacy, even working as designed? | the system holds personal data, and above all sensitive data | does not cover attacks on the system |
| **attack trees** | what is the cheapest route to this goal, and which control cuts it? | choosing between controls for one goal you care about | one goal per tree; only knows the routes drawn |
| **DREAD** | how bad is this threat, out of ten? | reading an old model that used it | scores do not agree between raters |

### What Vereda does

For a change to the portal, Vereda's routine has three steps, and each comes from a different
method:

1. **STRIDE** on the flows the change touches, per interaction where a boundary is crossed.
2. **LINDDUN** on any flow that carries personal data out of Vereda, or any new store that keeps it.
3. **An attack tree** only when a goal from stage 1 has a new route to it, to check whether the
   controls already in place still cut it.

PASTA's frame, as lesson 4 described, decides the order in which the findings are dealt with. DREAD
is not used. When a ranking is needed, lessons 9 to 11 give one with numbers that can be checked.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l05-routine\" aria-label=\"Vereda’s routine for a change, one method per step. First STRIDE, on the flows the change touches, per interaction where a boundary is crossed. Then LINDDUN, on any flow that carries personal data out of Vereda, or any new store that keeps it. Then an attack tree, only when a goal from PASTA’s stage 1 has a new route to it. PASTA’s frame orders the findings; DREAD is not used.\"><defs><marker id=\"l05-routine-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">STRIDE</text><text x=\"125.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the flows the change touches</text><path d=\"M230.0 75.0 L255.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-routine-tm-ah-paper-dim)\"></path><rect x=\"255.0\" y=\"40.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">LINDDUN</text><text x=\"360.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">personal data leaving Vereda</text><path d=\"M465.0 75.0 L490.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-routine-tm-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"40.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">attack tree</text><text x=\"595.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a goal with a new route</text><rect x=\"20.0\" y=\"135.0\" width=\"680.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">PASTA’s frame decides the order the findings are dealt with</text><text x=\"360.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">DREAD is not used: lessons 9 to 11 rank with numbers that can be checked</text></svg>", "caption": "Each step answers a different question, so dropping one leaves its question unasked rather than answered by the others."}
```

### Combining is normal

No method claims to be complete, and the ones that are honest about it say so in their own
documentation. STRIDE found T08 by asking about disclosure, and LINDDUN found three more things
about the same flow. The attack tree found that one control was wasted for one goal. Each
method's blind spot is another method's subject, and a model that used only one inherits that
method's blind spot whole.
