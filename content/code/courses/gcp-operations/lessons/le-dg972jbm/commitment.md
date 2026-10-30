---
title: How much to commit, worked out
version: 1
---

**The right commitment is the usage that never goes away, and nothing above it.** Usage above the base is paid on
demand; a commitment above the base is paid for hours nothing used. The program below makes that concrete for the
shop's batch fleet: four machines always on, eight during working hours. Prices are relative (an on-demand
machine-hour costs 1.00), so the result is a share of the bill rather than a number of dollars, and holds in any
region. Write it into `~/gcp/cud.py`:

```python
# cud.py
"""cud.py: what a commitment saves, for a fleet whose size changes in the day.

Prices are relative: one machine-hour on demand costs 1.00. The discounts are
the ones on Compute Engine's pricing page, read on 30 October 2026.
"""
HOURS = 730
BASE, PEAK, PEAK_HOURS = 4, 8, 22 * 10          # 4 always, 8 in working hours
DISCOUNT = {"1-year": 0.37, "3-year": 0.55}     # resource-based, general purpose


def covered(committed):
    """Machine-hours of real use that a commitment of this many machines covers."""
    if committed <= BASE:
        return committed * HOURS
    return BASE * HOURS + (min(committed, PEAK) - BASE) * PEAK_HOURS


used = BASE * HOURS + (PEAK - BASE) * PEAK_HOURS
print(f'machine-hours used        {used:>6,}')
print(f'all on demand             {used:>6,.0f}')
for term, d in DISCOUNT.items():
    for committed in (BASE, 6, PEAK):
        cost = committed * HOURS * (1 - d) + (used - covered(committed))
        print(f'{term} on {committed} machines   {cost:>6,.0f}  saves {1 - cost / used:.0%}')
```

```
ana@laptop:~/gcp$ python3 cud.py
machine-hours used         3,800
all on demand              3,800
1-year on 4 machines    2,720  saves 28%
1-year on 6 machines    3,199  saves 16%
1-year on 8 machines    3,679  saves 3%
3-year on 4 machines    2,194  saves 42%
3-year on 6 machines    2,411  saves 37%
3-year on 8 machines    2,628  saves 31%
```

The fleet uses 3,800 machine-hours a month: 4 × 730 always, and 4 more for 220 working hours.

- **Committing to the base, four machines**, saves 28% over a year and 42% over three. Every committed hour is
  used, and the peak is paid on demand.
- **Committing to six** saves less, 16% and 37%: two machines are committed for 730 hours and used for 220.
- **Committing to the peak, eight**, saves 3% for one year. Half the commitment sits idle outside working hours, and
  the discount barely pays for it.

Read the three-year rows again: committing to the peak still saves 31%, because a 55% discount covers a lot of idle
hours. **That is the argument people use for over-committing, and it rests on the fleet staying exactly as it is
for three years.** If the batch work moves to Cloud Run jobs in the second year, the four committed machines keep
being billed until the term ends, with nothing to run on them. A commitment is a bet on the future shape of the
system, and the base is the part of the bet with the least to lose.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A day of the batch fleet: four machines all day, eight during working hours. Three horizontal lines mark commitments of four, six and eight machines. The line at four sits under usage all day; the lines at six and eight sit above usage outside working hours, where the commitment is paid for machines nobody runs.\"><defs><marker id=\"ah9\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"60\" y1=\"200\" x2=\"680\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"60.0\" y=\"120\" width=\"206.66666666666663\" height=\"80\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"266.66666666666663\" y=\"40\" width=\"258.33333333333337\" height=\"160\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"525.0\" y=\"120\" width=\"155.0\" height=\"80\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><line x1=\"60\" y1=\"120\" x2=\"680\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"54\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><line x1=\"60\" y1=\"80\" x2=\"680\" y2=\"80\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"54\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">6</text><line x1=\"60\" y1=\"40\" x2=\"680\" y2=\"40\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"54\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">8</text><text x=\"60.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00:00</text><text x=\"266.66666666666663\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">08:00</text><text x=\"525.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18:00</text><text x=\"680.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24:00</text><text x=\"395.8333333333333\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">working hours: 8 machines</text></svg>", "caption": "Committing to four saves 28% a year; committing to eight, 3%."}
```

## Sustained use, for comparison

A machine running the whole month on a type that receives sustained use discounts gets up to 30% off with no
commitment at all. For the four always-on machines, the honest comparison is therefore not 28% against nothing, but
a one-year commitment's 37% list discount against the up to 30% they might already be getting, since the two do not
stack. On those machine types, the one-year commitment is worth a few points; the three-year one is worth it only if
the machines will certainly still be needed.
