---
title: Paying for portability, or not
version: 1
---

Avoiding a lock-in is never free, and that is the half the slogan leaves out. **Portability is
work you do now so that a switch would cost less later**, and it has a price like any other work.
The decision is a comparison of two numbers: what portability costs, against the expected cost of
the lock-in it removes.

## What portability costs at Coreto

**For the document database: R$ 63,000 over three years.** The Catalogue team would put an adapter
between its code and the database — one module of Coreto's own that every query goes through, so
the vendor's query interface appears in one place instead of many. Building it is 300 hours. Then
it needs 40 hours a year to keep up: every feature that needs a new kind of query needs it in the
adapter first. Over three years that is 300 + 3 × 40 = 420 hours, at R$ 150.

It also has a cost no sheet holds. An adapter written to work with any database exposes only what
every database can do, so the features that made this one attractive are harder to use.

**For the payment gateway: R$ 24,000.** The Payments team would put a payment interface of
Coreto's own between checkout and the gateway, and make sure the contract allows the stored cards
to be exported to another gateway. Building the interface is 160 hours, and it needs nothing a year
after that: payment operations — charge, refund, cancel — change rarely, so the interface stays
put once it exists.

## The sheet, finished

Add column E to the sheet from the previous section, and the decision in column F:

| | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| 1 | Lock-in | Switching cost | Probability | Expected cost | Portability | Decision |
| 2 | Managed document database | 210000 | 10% | 21000 | 63000 | |
| 3 | Payment gateway | 135000 | 35% | 47250 | 24000 | |

In F2 and F3, the comparison written as a formula, so it changes if an estimate does:

```localised
=IF(E2<D2,"pay for portability","accept the lock-in")      accept the lock-in
=IF(E3<D3,"pay for portability","accept the lock-in")      pay for portability
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Two cases, two bars each. Managed document database: expected switching cost R$ 21,000, portability over three years R$ 63,000, so accept the lock-in. Payment gateway: expected switching cost R$ 47,250, portability R$ 24,000, so pay for portability.\"><text x=\"20\" y=\"34\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Managed document database</text><text x=\"220\" y=\"62\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">expected switching cost</text><rect x=\"230\" y=\"46\" width=\"126\" height=\"22\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"364\" y=\"61\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 21,000</text><text x=\"220\" y=\"92\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">portability, three years</text><rect x=\"230\" y=\"76\" width=\"378\" height=\"22\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"616\" y=\"91\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 63,000</text><text x=\"230\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">→ accept the lock-in</text><text x=\"20\" y=\"159\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Payment gateway</text><text x=\"220\" y=\"187\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">expected switching cost</text><rect x=\"230\" y=\"171\" width=\"283.5\" height=\"22\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"521.5\" y=\"186\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 47,250</text><text x=\"220\" y=\"217\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">portability, three years</text><rect x=\"230\" y=\"201\" width=\"144\" height=\"22\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"382\" y=\"216\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 24,000</text><text x=\"230\" y=\"247\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">→ pay for portability</text></svg>", "caption": "Each lock-in as two bars: what it is expected to cost (switching cost × probability) and what avoiding it costs over three years. The shorter bar decides."}
```

**The database lock-in is accepted, and the gateway's is bought out.** For the database, avoiding
the lock-in would cost R$ 63,000 to remove an expected R$ 21,000: three times as much. For the
gateway, R$ 24,000 removes an expected R$ 47,250: about half. The same arithmetic gives opposite
answers, and the answer is decided by the probability as much as by either cost.

## How far would the probability have to move?

The probability is the weakest number in the sheet, so the most useful thing to know about each
decision is where it would flip. Portability is worth paying for when the expected cost exceeds
it, so the break-even probability is portability divided by switching cost:

| | portability | switching cost | break-even probability | Coreto's estimate |
|---|---|---|---|---|
| document database | R$ 63,000 | R$ 210,000 | 63,000 ÷ 210,000 = 30% | 10% |
| payment gateway | R$ 24,000 | R$ 135,000 | 24,000 ÷ 135,000 = 17.8% | 35% |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two small charts. Each has the probability of switching from 0% to 50% across and money up. A rising line is the expected cost; a flat line is the cost of portability. For the document database they cross at 30% and Coreto’s estimate is 10%, left of the crossing. For the payment gateway they cross at about 18% and the estimate is 35%, right of the crossing.\"><text x=\"70\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">document database</text><path d=\"M70 230 L330 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M70 230 L70 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"70\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0%</text><text x=\"200\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25%</text><text x=\"330\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50%</text><text x=\"200\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">probability of switching</text><path d=\"M70 230 L330 62\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"326\" y=\"54\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">expected cost</text><path d=\"M70 129.2 L330 129.2\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"326\" y=\"145.2\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">portability</text><path d=\"M226 129.2 L226 230\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><text x=\"230\" y=\"224\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">break-even 30%</text><circle cx=\"122\" cy=\"196.4\" r=\"4.5\" fill=\"var(--paper)\"></circle><text x=\"130\" y=\"212.4\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estimate 10%</text><text x=\"420\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">payment gateway</text><path d=\"M420 230 L680 230\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M420 230 L420 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"420\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0%</text><text x=\"550\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25%</text><text x=\"680\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50%</text><text x=\"550\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">probability of switching</text><path d=\"M420 230 L680 122\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"676\" y=\"114\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">expected cost</text><path d=\"M420 191.6 L680 191.6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"676\" y=\"207.6\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">portability</text><path d=\"M512.56 191.6 L512.56 230\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><text x=\"516.56\" y=\"224\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">break-even 17.8%</text><circle cx=\"602\" cy=\"154.4\" r=\"4.5\" fill=\"var(--paper)\"></circle><text x=\"594\" y=\"145.4\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estimate 35%</text></svg>", "caption": "Expected cost rises with the probability of switching; portability costs the same whatever happens. Paying for portability is worth it right of the crossing: 30% for the database, about 18% for the gateway. The dot is Coreto’s estimate."}
```

**Both estimates sit far from their break-even.** The database's chance of a switch would have to
triple, from 10% to 30%, before the adapter paid for itself. The gateway's could fall from 35% to
18%, and the interface would still be the right call. When an estimate is that
far from the line, nobody needs to argue about whether it is exactly right — and when one sits
close to the line, the break-even says so, and tells you which number to go and check.

## Accepting a lock-in on purpose

Accepting the database lock-in is a decision, and a decision left unwritten looks, a year later,
exactly like an accident. Davi wrote both down with what would reopen them:

> **Managed document database: lock-in accepted.** Switching would cost R$ 210,000; we put the
> chance at 10% in three years, an expected R$ 21,000. An adapter would cost R$ 63,000. Revisit if
> the provider announces a price rise or retires the product, or if the chance of leaving looks
> like more than 30%.
>
> **Payment gateway: pay for portability.** Switching would cost R$ 135,000; we put the chance at
> 35%, an expected R$ 47,250. A payment interface of our own and card export in the contract cost
> R$ 24,000. Worth it above a 17.8% chance of switching.

Lesson 17 turns notes like these into architecture decision records, which is where a lock-in
accepted on purpose belongs.

## What the sheet simplifies

The sheet treats portability as if it removed the switching cost entirely. It does not: with the
payment interface in place, leaving the gateway still costs something, only much less. That
simplification flatters portability. At the gateway the margin is wide — R$ 24,000 against an
expected R$ 47,250 — so it survives; at a case near its break-even, estimate what the switch would
still cost with the portability in place, and compare that instead.
