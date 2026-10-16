---
title: Sizing a commitment to the floor
version: 1
---

The table makes every commitment look like money saved. It is, **for the hours it is used**. An hour of
commitment with nothing running under it is paid at the plan's rate for nothing, and that is where the
discount goes. So the question is not *how much do we run on average* but *how much do we run every hour*.

`commit.py` is the shop's month, hour by hour: six instances at night and at weekends' start, fourteen in
working hours, eighteen at lunch when orders peak, and the cost of committing to each level with a
one-year Compute Savings Plan at the rate the previous section found:

```python
# commit.py: a month of the shop's instances, and what each size of commitment would have cost
ON_DEMAND = 0.1301  # m7g.large per hour, from rates.py
PLAN = 0.0884  # the same hour under a 1-year Compute Savings Plan, no upfront

usage = []  # instances running, hour by hour, for a 30-day month starting on a Monday
for day in range(30):
    weekend = day % 7 >= 5
    for hour in range(24):
        if weekend:
            usage.append(6 if hour < 8 else 8)
        elif 9 <= hour < 18:
            usage.append(14 if hour not in (12, 13) else 18)
        else:
            usage.append(6)

print(f"hours {len(usage)}, instance-hours {sum(usage)}, fewest at once {min(usage)}, most {max(usage)}")
print("commit  plan USD  on demand USD  total USD  unused plan  saved")
all_on_demand = sum(usage) * ON_DEMAND
for commit in (0, 4, 6, 8, 10, 14, 18):
    plan = commit * PLAN * len(usage)  # paid every hour, used or not
    rest = sum(max(0, u - commit) for u in usage) * ON_DEMAND
    unused = sum(max(0, commit - u) for u in usage) / (commit * len(usage)) if commit else 0
    total = plan + rest
    print(f"{commit:>6} {plan:>9.2f} {rest:>14.2f} {total:>10.2f} {unused:>11.0%} {1 - total / all_on_demand:>6.0%}")
```

```
ana@laptop:~/aws/commit$ python3 commit.py
hours 720, instance-hours 6336, fewest at once 6, most 18
commit  plan USD  on demand USD  total USD  unused plan  saved
     0      0.00         824.31     824.31          0%     0%
     4    254.59         449.63     704.22          0%    15%
     6    381.89         262.28     644.17          0%    22%
     8    509.18         177.46     686.64         14%    17%
    10    636.48         125.94     762.42         25%     8%
    14    891.07          22.90     913.97         39%   -11%
    18   1145.66           0.00    1145.66         51%   -39%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A step chart of instances running over two days, a weekday and a Saturday: six at night, fourteen in working hours, eighteen at lunch on the weekday; six then eight on Saturday. A solid line at six, labelled commit 6: busy every hour. A dashed line at ten, labelled commit 10: idle at night and at weekends, paid anyway; the usage falls below it for most of the hours outside the working day.\"><defs><marker id=\"flr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 240 L690 240\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70 240 L70 60\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"62\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"62\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"62\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"62\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><text x=\"62\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><path d=\"M70.0 186 L82.9 186 L82.9 186 L95.8 186 L95.8 186 L108.8 186 L108.8 186 L121.7 186 L121.7 186 L134.6 186 L134.6 186 L147.5 186 L147.5 186 L160.4 186 L160.4 186 L173.3 186 L173.3 186 L186.2 186 L186.2 114 L199.2 114 L199.2 114 L212.1 114 L212.1 114 L225.0 114 L225.0 78 L237.9 78 L237.9 78 L250.8 78 L250.8 114 L263.8 114 L263.8 114 L276.7 114 L276.7 114 L289.6 114 L289.6 114 L302.5 114 L302.5 186 L315.4 186 L315.4 186 L328.3 186 L328.3 186 L341.2 186 L341.2 186 L354.2 186 L354.2 186 L367.1 186 L367.1 186 L380.0 186 L380.0 186 L392.9 186 L392.9 186 L405.8 186 L405.8 186 L418.8 186 L418.8 186 L431.7 186 L431.7 186 L444.6 186 L444.6 186 L457.5 186 L457.5 186 L470.4 186 L470.4 186 L483.3 186 L483.3 168 L496.2 168 L496.2 168 L509.2 168 L509.2 168 L522.1 168 L522.1 168 L535.0 168 L535.0 168 L547.9 168 L547.9 168 L560.8 168 L560.8 168 L573.8 168 L573.8 168 L586.7 168 L586.7 168 L599.6 168 L599.6 168 L612.5 168 L612.5 168 L625.4 168 L625.4 168 L638.3 168 L638.3 168 L651.2 168 L651.2 168 L664.2 168 L664.2 168 L677.1 168 L677.1 168 L690.0 168\" stroke=\"var(--paper)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M70 186 L690 186\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70 150 L690 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"76\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">commit 6: busy every hour</text><text x=\"390.0\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">commit 10: idle hours, paid anyway</text><text x=\"225.0\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a weekday</text><text x=\"535.0\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a Saturday</text><path d=\"M380.0 240 L380.0 248\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">instances running, hour by hour</text></svg>", "caption": "Everything under the solid line is used every hour. The space between the usage and the dashed line is commitment paid for nothing."}
```

Read the last column. **Committing to six, the fewest that ever run at once, saves the most: 22%.** Every
instance committed above the floor is used in some hours and idle in others, and the idle hours are paid
anyway. At eight, 14% of the plan is unused and the saving falls to 17%; at ten it is 8%. At fourteen,
the working-hours level, the commitment costs more than paying on demand for everything. The average
here is 8.8 instances, and committing to the average would have saved less than committing to the floor.

## The arithmetic behind it

An hour of plan costs 0.0884 USD and replaces 0.1301 USD of on-demand, so it pays for itself if it is used
more than 0.0884 / 0.1301 = **68% of the time**. That is the rule for sizing, and it holds level by level:
commit the first instance, the second, and so on, while each additional one would be busy at least 68% of
the hours. In the shop's month the seventh instance runs only in working hours and weekend days, well
under 68%, so the commitment stops at six.

With a deeper discount the threshold falls: a three-year plan at 0.0612 pays off above 47%. **A longer
term justifies a larger commitment**, which is why the two choices are made together.

## Layers, not one purchase

Usage grows, and a commitment sized to last year's floor is too small by the end of this one. The usual
practice is to **buy in layers**: a plan sized to the current floor now, another in a quarter when the
floor has risen, each with its own end date, so that commitments expire in steps rather than all at once
and each renewal is a new decision with new data. The next section is where that data comes from.
