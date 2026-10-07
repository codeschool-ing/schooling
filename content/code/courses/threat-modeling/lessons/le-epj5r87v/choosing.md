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

### Combining is normal

No method claims to be complete, and the ones that are honest about it say so in their own
documentation. STRIDE found T08 by asking about disclosure, and LINDDUN found three more things
about the same flow. The attack tree found that one control was wasted for one goal. Each
method's blind spot is another method's subject, and a model that used only one inherits that
method's blind spot whole.
