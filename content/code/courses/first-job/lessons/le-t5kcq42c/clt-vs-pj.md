---
title: CLT against PJ
version: 1
---

**In Brazil**, the same monthly number means different things under a *CLT* contract and as a *PJ*. A CLT
salary comes with three payments fixed by law on top of the twelve months: the **13th salary**, **one third
extra on the holiday month**, and **FGTS**, deposited by the employer at 8% of what it pays. A PJ invoice
comes with none of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"What a CLT year is made of, in monthly salaries: twelve monthly salaries; one 13th salary; one third of a salary on the holiday month; and FGTS at 8 percent, a little over one salary. Together about 14.4 monthly salaries a year, before tax and benefits.\"><defs><marker id=\"pa17-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"563.6666666666666\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"28\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">12 monthly salaries</text><rect x=\"586.6666666666666\" y=\"40\" width=\"44.22222222222222\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"633.8888888888888\" y=\"40\" width=\"12.74074074074074\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"649.6296296296296\" y=\"40\" width=\"47.37037037037037\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">13º salário · holiday third · FGTS, 8%</text><text x=\"20\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">≈ 14.4 monthly salaries a year, before tax and benefits</text></svg>", "caption": "The reason a CLT offer and a PJ offer with the same monthly number are not the same offer. The parts are fixed by law; the monthly figure is not in the drawing because it does not change the proportions."}
```

The arithmetic, with a monthly figure chosen only to make it easy to follow:

```schooling-example
{"language": "python", "file": "clt_pj.py", "parts": [{"code": "# What a CLT salary is worth in a year, and the PJ invoice that matches it.\n# The monthly figure is an example, not a market rate. Taxes are left out on\n# purpose: INSS and income tax change with each year's tables.\nmonthly = 3000.00\n", "note": "The input is one number, the monthly gross salary of a CLT offer. It is an example chosen to make the arithmetic easy to follow, not a figure for any market."}, {"code": "thirteenth = monthly             # 13º salário: one extra month a year\nholiday_third = monthly / 3      # férias: a month paid, plus one third\nfgts = 0.08 * (12 * monthly + thirteenth + holiday_third)\n", "note": "The three things a CLT contract pays on top of twelve salaries, each fixed by law: the 13th salary, the extra third on the holiday month, and FGTS, which the employer deposits at 8% of what it pays."}, {"code": "clt_year = 12 * monthly + thirteenth + holiday_third + fgts\nprint(f\"CLT, a year before tax: R$ {clt_year:10,.2f}\")\nprint(f\"  that is {clt_year / monthly:.2f} monthly salaries\")\n", "note": "Add them up. The line that matters is the second: how many monthly salaries the year is worth, which does not depend on the example figure."}, {"code": "for months_invoiced in (12, 11):\n    pj = clt_year / months_invoiced\n    print(f\"PJ invoice to match it, {months_invoiced} months billed: R$ {pj:9,.2f}\")\n", "note": "The PJ side. A contractor who takes a month off bills eleven months, not twelve, so the invoice that matches the CLT year is higher than a twelfth of it. Benefits, taxes and the accountant come on top of this, and they differ from case to case."}]}
```

```
$ python3 clt_pj.py
CLT, a year before tax: R$  43,200.00
  that is 14.40 monthly salaries
PJ invoice to match it, 12 months billed: R$  3,600.00
PJ invoice to match it, 11 months billed: R$  3,927.27
```

The line that matters is **14.40 monthly salaries**: whatever the CLT figure, a year is worth about that many
of it before tax. So a PJ invoice equal to the CLT salary is **a pay cut of roughly a sixth** before anything
else is counted, and more if you take a month off unpaid.

What the program leaves out, on purpose, is three things. **Taxes and contributions** differ between the
two and change with each year's tables. A PJ company pays an accountant. And **benefits** (health plan,
meal allowance) are often part of a CLT offer and often missing from a PJ one. Put those in with the current
figures before comparing two real offers; the program gives you the part that does not change.

**Elsewhere** the same question exists as employee against contractor, with different rules and the same
lesson: compare the year, not the month.
