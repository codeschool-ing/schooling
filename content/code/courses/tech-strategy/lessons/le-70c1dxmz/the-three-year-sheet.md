---
title: The three-year sheet
version: 1
---

The comparison that misleads is one year wide. **Run it three years out**, because that is long
enough for the running costs to outweigh the setup, and short enough that the estimates still mean
something. Three years is a convention rather than a law, and this section ends by showing what
changes when you move it.

## Type it in

Open your spreadsheet, as set up in lesson 1, add a sheet, and type each option's yearly cost from
the previous section's table. Year 1 is the one-off work plus a year of running; years 2 and 3 are
running alone, with buy's licence rising 10% each year.

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Option | Year 1 | Year 2 | Year 3 | Three years |
| 2 | Build | 246000 | 102000 | 102000 | |
| 3 | Buy | 157200 | 132000 | 143880 | |
| 4 | Adopt | 241200 | 169200 | 169200 | |

Check one row by hand before trusting the column, as lesson 1 asked. Build's year 1 is 960 hours at
R$ 150 (R$ 144,000), plus a quarter of an engineer-year (R$ 66,000), plus twelve months of database
capacity (R$ 36,000): R$ 246,000. Buy's year 3 is the licence after two rises, R$ 130,680, plus a
twentieth of an engineer-year, R$ 13,200: R$ 143,880.

In E2 to E4, the three-year totals:

```localised
E2   =SUM(B2:D2)      450000
E3   =SUM(B3:D3)      433080
E4   =SUM(B4:D4)      579600
```

Then three formulas in empty cells. The cheapest option over three years, the cheapest in year 1
alone, and how much cheaper buying is than building:

```localised
=INDEX(A2:A4,MATCH(MIN(E2:E4),E2:E4,0))      Buy
=INDEX(A2:A4,MATCH(MIN(B2:B4),B2:B4,0))      Buy
=E2-E3                                        16920
```

`MATCH` finds the position of the smallest value in the column, and `INDEX` returns the name in
that position, so the answer stays right if somebody edits a number.

## Reading it

**Buying is cheapest over three years, by R$ 16,920 against building and R$ 146,520 against
adopting.** It is also cheapest in year 1, by much more: R$ 157,200 against building's R$ 246,000,
a difference of R$ 88,800. Plot the running totals and the shape is the argument.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 345\" role=\"img\" aria-label=\"A line chart of cumulative spend on search over three years for three options. Build reaches R$ 246,000 after year 1, R$ 348,000 after year 2 and R$ 450,000 after year 3. Buy reaches R$ 157,200, R$ 289,200 and R$ 433,080. Adopt reaches R$ 241,200, R$ 410,400 and R$ 579,600. Under the axis, buy’s lead over build: R$ 88,800, R$ 58,800 and R$ 16,920.\"><path d=\"M150 290 L600 290\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"140\" y=\"294\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M150 210 L600 210\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"140\" y=\"214\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200,000</text><path d=\"M150 130 L600 130\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"140\" y=\"134\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400,000</text><path d=\"M150 50 L600 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"140\" y=\"54\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">600,000</text><text x=\"150\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cumulative spend, R$</text><text x=\"150\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">start</text><text x=\"300\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">year 1</text><text x=\"450\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">year 2</text><text x=\"600\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">year 3</text><text x=\"140\" y=\"334\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">buy ahead by, R$</text><text x=\"300\" y=\"334\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">88,800</text><text x=\"450\" y=\"334\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">58,800</text><text x=\"600\" y=\"334\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">16,920</text><path d=\"M150 290 L300 191.6 L450 150.8 L600 110\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><circle cx=\"150\" cy=\"290\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"300\" cy=\"191.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"450\" cy=\"150.8\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"600\" cy=\"110\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><path d=\"M150 290 L300 227.12 L450 174.32 L600 116.768\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><circle cx=\"150\" cy=\"290\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"300\" cy=\"227.12\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"450\" cy=\"174.32\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"600\" cy=\"116.768\" r=\"3.5\" fill=\"var(--amber)\"></circle><path d=\"M150 290 L300 193.52 L450 125.84 L600 58.16\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></path><circle cx=\"150\" cy=\"290\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"300\" cy=\"193.52\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"450\" cy=\"125.84\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"600\" cy=\"58.16\" r=\"3.5\" fill=\"var(--paper)\"></circle><text x=\"612\" y=\"106\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Build</text><text x=\"692\" y=\"106\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">450,000</text><text x=\"612\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Buy</text><text x=\"692\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">433,080</text><text x=\"612\" y=\"62\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Adopt</text><text x=\"692\" y=\"62\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">579,600</text></svg>", "caption": "Cumulative spend on search, option by option. Buying is cheapest at every point, but its lead over building falls from R$ 88,800 after year 1 to R$ 16,920 after year 3, because the licence rises every year and building’s running cost does not."}
```

The lead shrinks every year. From year 2 on, building costs R$ 102,000 a year and buying costs
R$ 132,000, then R$ 143,880, because the licence rises and the build's running cost does not. Buy
was R$ 88,800 ahead after year 1, R$ 58,800 after year 2, and R$ 16,920 after year 3.

**Carry the sheet one more year and the answer flips.** Year 4's licence would be R$ 130,680 ×
1.10 = R$ 143,748; add the R$ 13,200 of people and buying's fourth year is R$ 156,948, against
building's R$ 102,000. Over four years, building totals R$ 552,000 and buying R$ 590,028. The
horizon is therefore a choice that decides the result, which is why it has to be stated beside
the result, and why "three years" in a proposal should come with a sentence saying why three.

## How big is R$ 16,920?

Small. At R$ 150 an hour it is about 113 engineer-hours, and the build estimate alone is 960 hours.
**An estimate that ran 12% over would erase the whole difference**, and lesson 6 priced a rewrite
running 50% over. When two options finish this close, the sheet's verdict is "the money
does not decide this" — and the decision moves to what the sheet does not hold.

## What the sheet leaves out

The sheet holds what was easy to put in a cell. Five things were not, and each one leans a
direction:

| left out | which way it leans | where it is taken up |
|---|---|---|
| search queries on the same database as the seat holds | against building | below |
| what leaving the vendor would cost | against buying | lesson 9 |
| the risk of being stuck with the vendor's terms | against buying | lesson 10 |
| what the 960 hours would have done on the reservation path | against building | lesson 13 |
| how soon buyers get better search | towards buying | below |

The first one deserves a sentence of its own. Building puts search on the Postgres database that
also holds the seat locks lesson 1 diagnosed, and a popular on-sale is exactly when buyers search
hardest. **An option that adds load to the one path the strategy protects costs more than its row says.**
The last one is the plainest: buy's integration is 240 hours against build's 960, so buyers get
better search in weeks rather than months.

Davi's note to Helena, after the Catalogue team had checked the numbers:

> **Search: recommendation.** Buy the hosted service. Over three years it is the cheapest option by
> R$ 16,920 — too little to decide on — and the cheapest in year 1 by R$ 88,800. It keeps search
> load off the database the reservation path depends on, and it leaves the Catalogue team's hours
> for work only Coreto can do. Before signing: price what leaving would cost, starting with the
> contract's data-export terms, and ask for the 10% yearly rise to be capped, because by year 4 it
> would make building the cheaper option.

The recommendation does not claim more than the sheet shows. It names the money, admits the
margin is thin, and says which unpriced items tipped it.
