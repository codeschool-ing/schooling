---
title: Approximate matches, for bands and dates
version: 1
---

**An approximate match does not look for the key itself. It looks for the last threshold the key
has reached.** That is wrong for a product code and exactly right for a band, a tier, a tax bracket
or a price that changed on a date: any table that says "from this value onwards, this answer".

## The three sizes, as a table

Lesson 3 sorted the sales into three sizes with a nested `IF`, and the thresholds, 4 and 10, were
buried in the formula. Put them in cells instead. On `Sales`, leave column N empty and type this
small table at **O1**:

| | O | P |
|---|---|---|
| 1 | `From` | `Band` |
| 2 | 1 | `Small` |
| 3 | 4 | `Medium` |
| 4 | 10 | `Large` |

Each row says where a band **starts**. Type `Band` in **M1**, and in **M2**:

```localised
=XLOOKUP(E2,$O$2:$O$4,$P$2:$P$4,,-1)
```

The two commas leave out the fourth argument, the message for a missing key, and the fifth, `-1`,
asks for an **exact match or the next smaller key**. S1001 has 14 bags: there is no 14 in O2:O4,
the next smaller key is 10, and M2 shows `Large`. A sale of 6 bags lands on 4, `Medium`; a sale of
1 lands on 1, `Small`. Fill it down and count: 22 `Large`, 41 `Medium` and 45 `Small`, exactly
what lesson 3's `IF` gave.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-approx\" aria-label=\"The band table with the keys 1, 4 and 10 and the bands Small, Medium and Large, and a line of bag counts from 1 to 20 with the three keys marked on it. Three sales are placed on the line: 14 bags moves left to the key 10 and is Large, 6 bags moves left to 4 and is Medium, 1 bag sits on the key 1 and is Small.\"><text x=\"68.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">O</text><text x=\"133.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">P</text><text x=\"32.0\" y=\"61.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"40.0\" y=\"50.0\" width=\"56.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"61.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">From</text><rect x=\"96.0\" y=\"50.0\" width=\"74.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"102.0\" y=\"61.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Band</text><text x=\"32.0\" y=\"83.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"40.0\" y=\"72.0\" width=\"56.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"83.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><rect x=\"96.0\" y=\"72.0\" width=\"74.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"102.0\" y=\"83.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Small</text><text x=\"32.0\" y=\"105.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"40.0\" y=\"94.0\" width=\"56.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"105.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><rect x=\"96.0\" y=\"94.0\" width=\"74.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"102.0\" y=\"105.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Medium</text><text x=\"32.0\" y=\"127.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"40.0\" y=\"116.0\" width=\"56.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"127.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10</text><rect x=\"96.0\" y=\"116.0\" width=\"74.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"102.0\" y=\"127.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Large</text><path d=\"M240.0 60.0 L680.0 60.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M240.0 56.0 L240.0 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M263.2 56.0 L263.2 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M286.3 56.0 L286.3 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M309.5 56.0 L309.5 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M332.6 56.0 L332.6 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M355.8 56.0 L355.8 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M378.9 56.0 L378.9 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402.1 56.0 L402.1 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M425.3 56.0 L425.3 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M448.4 56.0 L448.4 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M471.6 56.0 L471.6 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M494.7 56.0 L494.7 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M517.9 56.0 L517.9 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M541.1 56.0 L541.1 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M564.2 56.0 L564.2 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M587.4 56.0 L587.4 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M610.5 56.0 L610.5 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M633.7 56.0 L633.7 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M656.8 56.0 L656.8 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M680.0 56.0 L680.0 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M240.0 48.0 L240.0 72.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"240.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M309.5 48.0 L309.5 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"309.5\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><path d=\"M448.4 48.0 L448.4 72.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"448.4\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">10</text><text x=\"680.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">20</text><circle cx=\"541.1\" cy=\"108.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"551.1\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">E = 14</text><path d=\"M533.1 108.0 L450.4 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450.4 108.0 L458.4 112.0 L458.4 104.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"440.4\" y=\"108.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">Large</text><circle cx=\"355.8\" cy=\"144.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"365.8\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">E = 6</text><path d=\"M347.8 144.0 L311.5 144.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M311.5 144.0 L319.5 148.0 L319.5 140.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"301.5\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Medium</text><circle cx=\"240.0\" cy=\"180.0\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"250.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">E = 1</text><text x=\"232.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Small</text><text x=\"240.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the largest key that is not greater than the value</text></svg>", "caption": "An approximate match walks back from the value to the last threshold it has reached. 14 bags has passed 10, so it is Large; 6 has passed 4 but not 10."}
```

The thresholds now live where anybody can see them. If Café Serra decides that `Large` starts at 12
bags, one cell changes and every row follows, which no nested `IF` ever offered.

## The same thing in the older functions

`VLOOKUP` with `TRUE` and `MATCH` with 1 do the same job:

```localised
=VLOOKUP(E2,$O$2:$P$4,2,TRUE)
```

gives the same 22, 41 and 45. Both of them **require the first column to be sorted in ascending
order**, because they search by halving the range rather than reading every row, and on an unsorted
table they give wrong answers without an error. `XLOOKUP` with `-1` reads the keys in order and
does not need the sort, though keeping a band table sorted is still the way to make it readable.

Two details keep a band table honest. The first row must start at the smallest possible value, here
1, or a sale below it finds nothing and shows `#N/A`. And the keys are where bands **begin**, so 10
belongs to `Large`; a table of where bands end would put every boundary one band off.

## A price that changed on a date

Dates are numbers, so the same lookup finds "the price in force on that day". The list price of
`CER1K` was R$ 115 until the end of 2025 and R$ 118 from 1 January 2026. As a table, at **O6**:

| | O | P |
|---|---|---|
| 6 | `From` | `CER1K` |
| 7 | 2025-01-01 | 115 |
| 8 | 2026-01-01 | 118 |

Then, for sale S1003 on row 4, an online sale of `CER1K` on 13 January 2025:

```localised
=XLOOKUP(B4,$O$7:$O$8,$P$7:$P$8,,-1)
```

answers **115**, the list price on the day, which is what S1003 paid. On row 85, S1084, sold online
on 25 February 2026, the same formula answers **118**, and that is what S1084 paid too. Online sales
pay the list price of their day, and this is how you check it. A table for all six products would
put one column per product beside the dates, and the lookup would then need a row and a column:
the two-`MATCH` pattern of section 05, with the row found by `MATCH(B4,$O$7:$O$8,1)`, the
approximate kind.
