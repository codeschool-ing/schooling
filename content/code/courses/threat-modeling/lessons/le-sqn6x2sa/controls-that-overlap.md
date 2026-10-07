---
title: Controls that overlap
version: 1
---

The ranking judged each control **on its own**, as if it were the only one bought. That is fine
for comparing them, and wrong for adding them up. **Three controls cut T03**, and they cannot each
take credit for the same reais.

C1 removes 80% of T03's frequency. C2, the console on the clinic network, removes 50% of what is
left. C11, receptionists without clinical notes, removes 30% of what is left after that. Applied in
order, each one works on a smaller risk than the one before:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l11-overlap\" aria-label=\"T03’s expected loss as controls are added one after the other. With none: 75,000 reais a year. After C1, the second factor, which removes 80%: 15,000. After C2, the console on the clinic network, which removes half of what is left: 7,500. After C11, receptionists without notes, which removes 30% of what is left: 5,250. On its own, C11 claimed to save 22,500; added last, it saves 2,250, less than its cost of 3,500.\"><rect x=\"40.0\" y=\"30.0\" width=\"110.0\" height=\"180.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R$ 75,000</text><text x=\"95.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no controls</text><rect x=\"210.0\" y=\"30.0\" width=\"110.0\" height=\"144.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"210.0\" y=\"174.0\" width=\"110.0\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R$ 15,000</text><text x=\"265.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">+ C1, second factor</text><rect x=\"380.0\" y=\"174.0\" width=\"110.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"380.0\" y=\"192.0\" width=\"110.0\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R$ 7,500</text><text x=\"435.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">+ C2, clinic network</text><rect x=\"550.0\" y=\"192.0\" width=\"110.0\" height=\"5.4\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"550.0\" y=\"197.4\" width=\"110.0\" height=\"12.6\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"187.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R$ 5,250</text><text x=\"605.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">+ C11, roles</text><path d=\"M30.0 210.0 L700.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"605.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">C11 alone: R$ 22,500</text><text x=\"605.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">C11 last: R$ 2,250</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">T03’s expected loss per year, as controls are added in order</text></svg>", "caption": "A control is worth what it removes from what is left. Judged alone, C11 was worth ten times more than it is after C1 and C2."}
```

`prioritise.py` with a list of controls writes `risks.csv` as it would be with those controls in
place. Writing it to a scratch folder, `after/`, and running lesson 9's `risk.py` there shows T03
after C1 and C2:

```
(.venv) ana@vm:~/tm/portal-model$ mkdir after
(.venv) ana@vm:~/tm/portal-model$ python3 prioritise.py C1 C2 > after/risks.csv
(.venv) ana@vm:~/tm/portal-model$ cd after && python3 ../risk.py | grep T03
T03      0.03       250,000        7,500  10.4%
```

**R$ 7,500 a year are left.** C11 would remove 30% of that, R$ 2,250, and it costs R$ 3,500. Judged
alone, C11 looked like R$ 22,500 of value for R$ 3,500, a ratio of 6.4. Added after the two
stronger controls, its ratio is about 0.6, and on these numbers it is not worth buying for T03.

### The rule

**A control is worth what it removes from what is left after the controls already chosen.** So the
order of choosing matters, and the honest way to build a plan is greedy: pick the best ratio,
recompute every other control's value against what remains, pick again. For a list of eleven, that
can be done by hand with `prioritise.py` and `risk.py`, as above; for a list of a hundred, it is a
small program.

The independent ranking is still useful, for one thing: **it says which controls to consider
first.** It is the total of the independent values that is wrong, and a plan that adds them up
promises more than it delivers.
