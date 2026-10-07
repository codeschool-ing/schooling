---
title: Accepting a risk
version: 1
---

Accepting a risk is a legitimate decision. Every organisation carries risks it has chosen not to
reduce, because the controls cost more than the losses or because the business would not work with
them in place. **What makes an acceptance legitimate is that the right person made it, in writing,
knowing what they were accepting, for a limited time.** Without those four things it is not an
acceptance; it is a risk somebody hoped would go away.

### The right person

Accepting a risk spends the business's money in advance, in the form of losses it has agreed to
bear. So the person who accepts it must have **the authority to spend that much**, and that
authority grows with the size of the risk:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-authority\" aria-label=\"Who may accept a risk at Vereda, by its expected loss per year. Up to 10,000 reais: the team lead, ana. From 10,000 to 50,000: the operations director, daniel. Above 50,000, or any risk to patients’ health data that the LGPD calls high: the owners, together. T14, at 9,000, sits in the first band, and daniel signed it anyway because its bad year is large.\"><rect x=\"250.0\" y=\"30.0\" width=\"140.0\" height=\"44.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"52.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">up to R$ 10,000 a year</text><text x=\"400.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">team lead (ana)</text><rect x=\"250.0\" y=\"90.0\" width=\"240.0\" height=\"44.0\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R$ 10,000 to 50,000</text><text x=\"500.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">operations director (daniel)</text><rect x=\"250.0\" y=\"150.0\" width=\"340.0\" height=\"44.0\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"172.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">above R$ 50,000, or high LGPD risk</text><text x=\"600.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the owners, together</text><circle cx=\"300.0\" cy=\"52.0\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1.5\"></circle><text x=\"250.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the dot: T14, R$ 9,000 a year, signed by daniel because of its bad year</text></svg>", "caption": "The bigger the risk, the more senior the signature. A rule like this is what stops a developer from accepting, alone, a risk the business would never have agreed to."}
```

A developer cannot accept, alone, a risk worth R$ 75,000 a year, however sure they are that it is
fine. The threshold is a decision daniel made once, and it is written in the same repository as
the decisions it governs.

### What the acceptance says

An acceptance that just says "accepted" is useless six months later, when nobody remembers why. It
records five things:

1. **the risk**, with its estimate, so the person reading it later knows what was accepted;
2. **why it is accepted**: usually that the controls cost more than they save, with the numbers;
3. **what is in place instead**, the compensating controls that make living with it reasonable;
4. **who accepted it**, by name, and when;
5. **when it will be looked at again**, and what would bring that date forward.

The fifth point has two halves, and both matter. A review date, so that the acceptance expires
rather than becoming permanent by default. And **triggers**, events that make the acceptance stale
before its date: for T14, a published flaw in the console's PDF viewer, or a clinic computer
infected by anything.

### T14, accepted

daniel signed T14's acceptance on 1 October 2026, for six months. On the numbers, ana could have
signed it, since R$ 9,000 a year is in ana's band. daniel took it because the bad year, nearly
R$ 400,000, is a business question, and because the alternative being priced, insurance above R$
50,000, is a contract only daniel can sign. The full record is in the section after next.
