---
title: The arithmetic of availability
version: 1
---

**An availability figure is an amount of downtime written as a percentage, and the percentage hides
how much time it is.** "Three nines" sounds close to perfect. Turned back into hours it is a whole
working day lost every year, and the habit worth building is to make that conversion before you
agree to any number.

Joana met it in her second month. Regina asked her what the Portal B2B should promise the 4,000
bakeries that order through it, and Joana gave the answer she had given at the fintech: 99.9%. Then
she did the arithmetic on the systems the portal depends on, and found that the portal could not
keep that promise. Its own code was fine. **The trouble was what it called.**

## The nines, as time

A year has 8,760 hours (365 × 24) and a 30-day month has 43,200 minutes. A service with
availability *A* may be down for the fraction (1 − *A*) of that time. That is all the table below
does:

| availability | down per year | down per 30-day month |
|---|---|---|
| 99% | 87.6 h, or 3.65 days | 432 min, or 7.2 h |
| 99.5% | 43.8 h | 216 min, or 3.6 h |
| 99.9% | 8.76 h | 43.2 min |
| 99.95% | 4.38 h | 21.6 min |
| 99.99% | 52.56 min | 4.32 min |

Each extra nine divides the downtime by ten. The price does not divide with it. The step from 99.9% to 99.99% means surviving the loss of a whole server or a whole site without a person waking up,
and that is a different architecture rather than a better version of the same one.

Two details catch people every time they read one of these numbers.

*Which month.* 43.2 minutes is a tenth of a per cent of a 30-day month. An average month, a
twelfth of a year, allows 43.8 minutes; a 31-day month allows 44.64; February allows 40.32. The
differences are small and they are exactly the kind of thing two parties argue about after an
outage, so a target names its period.

*Which window of measurement.* 99.9% measured over a year allows 8.76 hours, and nothing stops
all of them arriving in one night. 99.9% measured per month allows at most 43.2 minutes in any one
month. **The same percentage over a different window is a different promise**, and a bakery that
cannot order on the one bad night does not care that the year averaged out.

## A chain multiplies

When a request has to pass through several systems and each of them has to be up for it to
succeed, the availability of the whole is the product of the parts. The reasoning is the
probability of independent events: the request works only if the first system is up, and the
second, and the third.

Joana's case was the stock check. When a bakery opens its basket, the portal asks SAP's
available-to-promise service how much of each product can still be sold (lesson 1 tells how that
service came to exist), and the call crosses Rui's service bus on the way. Three systems in a row,
with their availability over the last twelve months taken from each team's own monitoring:

| system | measured availability |
|---|---|
| Portal B2B | 99.9% |
| the service bus (IBM Integration Bus) | 99.5% |
| SAP ECC, outside its planned window | 99.0% |

The chain is 0.999 × 0.995 × 0.99 = 0.98406, about **98.41%**. That leaves 1.594% of the year,
which is 139.6 hours, or 5.8 days. In a 30-day month it is about 688 minutes, eleven and a half
hours. Each system on its own looks respectable. Together they put the bakery's basket out of
reach for almost a week a year.

When every factor is close to 100% there is a shortcut worth knowing: **the unavailabilities
roughly add.** 0.1% + 0.5% + 1.0% = 1.6%, against the exact 1.594%. It is how you check a vendor's
claim in a meeting without a calculator, and it makes the next point obvious. A chain is always
less available than its weakest member. The portal team could make their own code perfect and the
stock check would still be at 0.995 × 0.99 = 98.505%.

The diagram also understates the chain. The call needs the network between the data centre and the
portal's hosting, name resolution, the certificate on each hop and the identity service that signs
the portal's token. **Every synchronous dependency is one more factor**, and the honest chain is
longer than the one on the whiteboard. The figure below keeps to the three that the measurements
cover.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l12-chain\" aria-label=\"Two rows. The top row is the stock check as it is: the Portal B2B at 99.9%, the service bus at 99.5% and SAP ECC at 99.0%, in series, so the chain is 0.999 times 0.995 times 0.99, which is 98.41%, about 139.6 hours down a year. The bottom row puts two bus nodes in parallel between the portal and SAP. On paper the pair is 1 minus 0.005 squared, 99.9975%, and the chain becomes 98.90%. With last year's outage record, 18 of the bus's 43.8 hours came from causes both nodes share, so the pair reaches about 99.79% and not 99.9975%.\"><defs><marker id=\"l12-chain-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">in series: every one must be up</text><rect x=\"25.0\" y=\"47.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Portal B2B</text><text x=\"95.0\" y=\"79.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99.9%</text><rect x=\"220.0\" y=\"47.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">service bus</text><text x=\"290.0\" y=\"79.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99.5%</text><rect x=\"415.0\" y=\"47.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP ECC</text><text x=\"485.0\" y=\"79.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99.0%</text><path d=\"M166.0 72.0 L218.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M361.0 72.0 L413.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M556.0 72.0 L586.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><text x=\"650.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">= 98.41%</text><text x=\"650.0\" y=\"79.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">139.6 h a year</text><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.999 × 0.995 × 0.99 = 0.98406</text><path d=\"M20.0 140.0 L700.0 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"20.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a second bus node in parallel</text><rect x=\"25.0\" y=\"215.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"232.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Portal B2B</text><text x=\"95.0\" y=\"247.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99.9%</text><rect x=\"220.0\" y=\"184.0\" width=\"140.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bus node A  99.5%</text><rect x=\"220.0\" y=\"254.0\" width=\"140.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bus node B  99.5%</text><rect x=\"415.0\" y=\"215.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"232.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP ECC</text><text x=\"485.0\" y=\"247.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99.0%</text><path d=\"M166.0 240.0 L190.0 240.0 L190.0 205.0 L218.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M190.0 240.0 L190.0 275.0 L218.0 275.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M361.0 205.0 L390.0 205.0 L390.0 240.0 L413.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M361 275 L390 275 L390 240\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"650.0\" y=\"232.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">= 98.90%</text><text x=\"650.0\" y=\"247.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">on paper</text><text x=\"360.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pair on paper: 1 − 0.005² = 99.9975%   ·   with the 18 h both nodes share: about 99.79%</text></svg>", "caption": "The stock check as a chain. In series the availabilities multiply; a second node adds a nine on paper, and the outages both nodes share take most of it back."}
```

## Redundancy buys a nine, on paper

Two copies of a component, either of which can do the work, fail together only when both are down.
If each is available with probability *a*, the pair is available with probability 1 − (1 − *a*)².

For the bus at 99.5%, a second node would give 1 − 0.005² = 0.999975, which is **99.9975%**. The
downtime falls from 43.8 hours a year to about 13 minutes (0.000025 × 525,600 minutes). Put that
pair in the chain and the stock check becomes 0.999 × 0.999975 × 0.99 = 98.90%. Now SAP is nearly
all of what is left.

That formula rests on one word: independent. It assumes that whatever takes down one copy leaves
the other alone, and that is the assumption real systems break. Rui keeps a record of every outage
of the bus, and Joana went through last year's 43.8 hours with him:

| cause | hours | would a second node have helped? |
|---|---|---|
| an expired certificate on the bus's endpoints | 11 | no: both nodes would use the same certificate |
| a flow deployed with a mapping error | 7 | no: a deployment goes to both nodes |
| node failures: a full disk, a host restart, a hung process | 25.8 | yes |

The 18 hours of shared causes remain whatever the number of nodes. The 25.8 hours of node failures
nearly vanish: each node is down for 25.8 of 8,760 hours, so both are down together for about
0.076 hours, under five minutes. The pair comes out at about 18.1 hours a year, which is 99.79%.

**Redundancy removes the failures that are independent and keeps every failure the copies share.**
The second node is still worth having: it takes away more than half of the downtime. It is not
worth 99.9975%, and a proposal that quotes the formula without the outage record has promised
something the system will not do. The formula also assumes the switch from one copy to the other
is instant. A failover that takes four minutes to notice and two to complete puts those minutes
back in on every failure.

## What the arithmetic says to do

Joana's conclusion was not to buy a second bus node first. The chain told her where the hours were:
SAP at 1.0% is the biggest factor, and SAP is the system Serra Alta can least change. Adding nines
to the bus or to the portal moves the total by tenths. **Taking SAP out of the path while the
bakery waits** moves it by whole percentage points, and the short cache from lesson 1 is the first
step of that: a basket opened while SAP is slow is served from a figure a few minutes old instead
of failing. The section on degraded modes, two on from here, makes that a design rather than an
accident.

There is a second thing the table above does not show. SAP's 99.0% is measured outside its planned
window, and every Sunday from 01:00 to 05:00 it is down on purpose. Whether that counts depends on
who is asking, which is what the next section settles: what exactly is being measured, from where,
and what happens when the number is missed.
