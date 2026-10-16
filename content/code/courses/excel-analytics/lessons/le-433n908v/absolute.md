---
title: Absolute references, for the cell every row needs
version: 1
---

**Some addresses have to stay where they are while the formula moves.** A share of the total is the
plainest case: every sale is divided by the same total, so the reference to the total must point at
one cell from every row. A dollar sign is how you say so. `$L$2` is an **absolute reference**, and
it reads "cell L2", wherever the formula is copied.

## The share of each sale

Put the total in a cell of its own, outside the data, with a label beside it so the next person
knows what it is. On `Sales`, type `Total` in **L1**, and in **L2**:

```localised
=SUM(H2:H109)
```

Then type `Share` in **J1**, and in **J2** the obvious formula:

```localised
=H2/L2
```

J2 shows a decimal a little under 0.03. Select column J, click **Percent Style** (the **%** button
on the **Home** tab) and then **Increase Decimal** once, and J2 reads **2.8%**: sale S1001 is 2.8%
of eighteen months of revenue. Now double-click the fill handle of J2.

Every cell from J3 down shows `#DIV/0!`. Click J3 and the formula bar explains it: `=H3/L3`. The
reference to the total moved down a row like every relative reference does, and L3 is empty, so
J3 divides by zero. J2 was right only because it is the one cell where L2 is the total.

The repair is two dollar signs. In J2:

```localised
=H2/$L$2
```

and fill down again. J3 now holds `=H3/$L$2` and shows **3.8%**, J109 shows **0.4%**, and the
check that a column of shares deserves comes out right:

```localised
=SUM(J2:J109)
```

answers **1**, which is 100%. The largest share in the column is 4.1%, the 20 bags of `CER1K` that
`C03` bought in sale S1083.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l02-anchor\" aria-label=\"Two copies of the share column. On the left, =H2/L2 filled down: J3 holds =H3/L3 and J4 holds =H4/L4, each arrow pointing at its own row of column L, where only L2 holds the total, so J3 and J4 show #DIV/0!. On the right, =H2/$L$2 filled down: every arrow points at L2, and the cells show 2.8%, 3.8% and 0.2%.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">=H2/L2, filled down</text><text x=\"98.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">J</text><text x=\"36.0\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"44.0\" y=\"60.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"74.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Share</text><text x=\"36.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"44.0\" y=\"88.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"102.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">=H2/L2</text><text x=\"36.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"44.0\" y=\"116.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">=H3/L3</text><text x=\"36.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"44.0\" y=\"144.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"158.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">=H4/L4</text><text x=\"245.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">L</text><rect x=\"212.0\" y=\"60.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272.0\" y=\"74.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Total</text><rect x=\"212.0\" y=\"88.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272.0\" y=\"102.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">51494</text><rect x=\"212.0\" y=\"116.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"212.0\" y=\"144.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M156.0 102.0 L208.0 102.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M208.0 102.0 L200.0 98.0 L200.0 106.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M156.0 130.0 L208.0 130.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M208.0 130.0 L200.0 126.0 L200.0 134.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M156.0 158.0 L208.0 158.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M208.0 158.0 L200.0 154.0 L200.0 162.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"44.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">J2  2.8%</text><text x=\"44.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">J3  #DIV/0!</text><text x=\"44.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">J4  #DIV/0!</text><text x=\"380.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">=H2/$L$2, filled down</text><text x=\"458.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">J</text><text x=\"396.0\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"404.0\" y=\"60.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"410.0\" y=\"74.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Share</text><text x=\"396.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"404.0\" y=\"88.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"410.0\" y=\"102.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">=H2/$L$2</text><text x=\"396.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"404.0\" y=\"116.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"410.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">=H3/$L$2</text><text x=\"396.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"404.0\" y=\"144.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"410.0\" y=\"158.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">=H4/$L$2</text><text x=\"605.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">L</text><rect x=\"572.0\" y=\"60.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"632.0\" y=\"74.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Total</text><rect x=\"572.0\" y=\"88.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"632.0\" y=\"102.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">51494</text><rect x=\"572.0\" y=\"116.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"572.0\" y=\"144.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M516.0 102.0 L568.0 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568.0 102.0 L560.0 98.0 L560.0 106.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><path d=\"M516.0 130.0 L568.0 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568.0 102.0 L559.1 102.3 L562.9 109.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><path d=\"M516.0 158.0 L568.0 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568.0 102.0 L559.6 105.1 L565.5 110.6 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"404.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">J2  2.8%</text><text x=\"404.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">J3  3.8%</text><text x=\"404.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">J4  0.2%</text></svg>", "caption": "A relative reference to the total moves with every row and finds an empty cell. With dollars, every row points at the one cell that holds it."}
```

## The same mistake, without an error

`#DIV/0!` is the kind failure. Here is the unkind one. Suppose J2 had been written with the total
inside it:

```localised
=H2/SUM(H2:H109)
```

J2 is correct, 2.8%. Fill it down and **both ends of the range move**: J3 holds
`=H3/SUM(H3:H110)`, which leaves out sale S1001, and J109 holds `=H109/SUM(H109:H216)`, which is one
sale divided by itself. No cell shows an error. J3 says 3.9% where the truth is 3.8%, J109 says
100%, and the column adds up to 579%. The only thing that gives it away is a check like the one
above, which is the reason to write one every time a formula is filled.

## Four ways to write one address

The dollar sign fixes whatever follows it, the column letter or the row number, so one address has
four forms:

| written | when the formula is copied down | when it is copied across |
|---|---|---|
| `L2` | the row moves | the column moves |
| `$L$2` | stays L2 | stays L2 |
| `L$2` | stays on row 2 | the column moves |
| `$L2` | the row moves | stays in column L |

You do not have to type the dollars. Click inside an address in the formula bar and press **F4**
(on a Mac, **Cmd+T**): each press moves to the next form in the order `$L$2`, `L$2`, `$L2`, `L2`.
The two forms in the middle, with one dollar each, are the subject of the next section.
