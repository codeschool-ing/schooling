---
title: Beyond the money
version: 1
---

A ranking by reais per real is the right default and the wrong final word. **Some reasons to do a
control, or not to, do not fit in expected loss**, and a plan that ignores them is a plan somebody
will overrule for good reasons. Five come up at Vereda.

| reason | what it changes | at Vereda |
|---|---|---|
| **the law** | a control required by law is done whatever its ratio | the LGPD's necessity principle: personal data processed only as far as needed, which C11 serves for T09 |
| **a contract** | a customer or partner requires it | the payment gateway's terms require the webhook signature to be checked |
| **dependency** | one control is worthless without another first | the console's second factor needs staff to have a phone or key, which C1 includes |
| **the bad year** | a rare, large loss the business could not absorb | T14's R$ 388,419 one year in a hundred, which makes transfer worth pricing |
| **friction and trust** | a control people resent is switched off; one patients notice changes how they see the clinic | the reminder text change (C8) is invisible; a second factor for patients would not be |

### C11, decided on the law

C11 failed on the arithmetic: after C1 and C2, receptionists without clinical notes saves R$ 2,250
of T03 for R$ 3,500. But C11 also answers T09, receptionists reading notes they never need, which
was not in `risks.csv` at all, because its harm is to patients' privacy rather than to Vereda's
money. The LGPD's principle of necessity says personal data is processed only as far as its purpose
requires, and a receptionist's purpose does not require clinical notes. **C11 is done because the
law asks for it**, and the plan says so in those words rather than inventing a loss estimate to make
the ratio come out above 1.

That last point is a habit worth keeping. When a decision is made for a reason that is not money,
**write the reason**, and do not dress it in numbers. A ratio fiddled to justify a decision already
taken is how a quantitative method loses everybody's trust.

### Quick wins and visible wins

Two more reasons appear in every planning meeting and are worth naming so they can be weighed
rather than argued about:

- **Quick wins.** C8 is a change to one message template, done in an afternoon. Doing it first
  costs nothing in the plan's order and shows the team that the model produces results.
- **Visible wins.** Something a patient or the owners can see, such as a notice of new sign-ins
  (R18), builds the trust that pays for the invisible controls. It is a legitimate reason to move
  an item up, as long as it is named as that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l11-wins\" aria-label=\"Two reasons that move an item up the plan, named so they can be weighed. A quick win: C8, one message template changed in an afternoon, which costs nothing in the plan’s order and shows the model producing results. A visible win: a notice of new sign-ins, R18, which patients and owners can see and which builds trust for the invisible controls.\"><rect x=\"40.0\" y=\"30.0\" width=\"300.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a quick win</text><text x=\"190.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">C8</text><text x=\"190.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one template, one afternoon</text><text x=\"190.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shows the model works</text><rect x=\"380.0\" y=\"30.0\" width=\"300.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a visible win</text><text x=\"530.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">R18</text><text x=\"530.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a notice of new sign-ins</text><text x=\"530.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trust for what nobody sees</text><text x=\"360.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">legitimate reasons, as long as the plan says that is why</text></svg>", "caption": "A reason that is named can be argued with. A reason that is not ends up as “it felt more urgent”."}
```
