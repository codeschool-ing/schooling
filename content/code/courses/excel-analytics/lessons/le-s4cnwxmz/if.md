---
title: IF, and choosing among more than two
version: 1
---

**`IF` turns a comparison into a choice: one value when it is `TRUE`, another when it is `FALSE`.**
It takes three arguments, always in this order: the test, the value if true, the value if false.
Everything else about it is what you put in those three places.

## One test, two answers

Café Serra calls its wholesale customers *trade* and everybody else *retail*. In J2 of `Sales`:

```localised
=IF(G2="Wholesale","Trade","Retail")
```

J2 shows `Trade`. Fill it down and 38 rows say `Trade`, the 38 wholesale sales.

The two values do not have to be text. This gives the revenue of a wholesale sale and 0 for any
other, so a sum of the column is the wholesale revenue:

```localised
=IF(G2="Wholesale",H2,0)
```

Filled down and added up with `=SUM(J2:J109)`, it gives **38731**: R$ 38,731 of the R$ 51,494 came
from wholesale. Lesson 5 gets the same number with one `SUMIFS` and no helper column, and the two
had better agree.

Leave out the third argument and `IF` does not give an empty cell. `=IF(E2>=10,"Large")` shows
`FALSE` on every row of fewer than ten bags, which is rarely what anybody wanted to see. Write the
empty text, `""`, as the third argument when you mean nothing.

## More than two answers: nested IF

Sort the sales into three sizes: **Large** from 10 bags, **Medium** from 4, **Small** below that.
`IF` chooses between two things, so the second choice goes inside the first:

```localised
=IF(E2>=10,"Large",IF(E2>=4,"Medium","Small"))
```

Read it as Excel does, from the left. Ten bags or more: `Large`, and the rest of the formula is
never looked at. Otherwise, the inner `IF` runs: four or more, `Medium`; otherwise `Small`. Filled
down, the column holds 22 `Large`, 41 `Medium` and 45 `Small`, which add up to the 108 sales. That
last check, the parts adding up to the whole, is worth doing every time a column sorts rows into
groups.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l03-bands\" aria-label=\"A line of bag counts from 1 to 20, cut at 4 and at 10 into three bands: Small from 1 to 3 bags, 45 sales; Medium from 4 to 9, 41 sales; Large from 10 to 20, 22 sales. Below it, the nested IF as a path: the test E2&gt;=10 first, which leads to Large if true; otherwise the test E2&gt;=4, which leads to Medium if true and to Small if false.\"><rect x=\"60.0\" y=\"56.0\" width=\"88.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"68.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Small</text><text x=\"105.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">45 sales</text><rect x=\"150.0\" y=\"56.0\" width=\"178.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"158.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Medium</text><text x=\"240.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">41 sales</text><rect x=\"330.0\" y=\"56.0\" width=\"328.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"338.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Large</text><text x=\"495.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">22 sales</text><path d=\"M60.0 84.0 L60.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><path d=\"M90.0 84.0 L90.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M120.0 84.0 L120.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 84.0 L150.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><path d=\"M180.0 84.0 L180.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M210.0 84.0 L210.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M240.0 84.0 L240.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M270.0 84.0 L270.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M300.0 84.0 L300.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M330.0 84.0 L330.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10</text><path d=\"M360.0 84.0 L360.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M390.0 84.0 L390.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420.0 84.0 L420.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M450.0 84.0 L450.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M480.0 84.0 L480.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M510.0 84.0 L510.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M540.0 84.0 L540.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M570.0 84.0 L570.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M600.0 84.0 L600.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M630.0 84.0 L630.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"630.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20</text><text x=\"664.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bags</text><rect x=\"60.0\" y=\"150.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">E2&gt;=10</text><path d=\"M180.0 165.0 L268.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M268.0 165.0 L260.0 161.0 L260.0 169.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"224.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">true</text><rect x=\"270.0\" y=\"150.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"320.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">\"Large\"</text><path d=\"M120.0 180.0 L120.0 218.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M120.0 218.0 L124.0 210.0 L116.0 210.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><text x=\"128.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">false</text><rect x=\"60.0\" y=\"220.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">E2&gt;=4</text><path d=\"M180.0 235.0 L268.0 235.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M268.0 235.0 L260.0 231.0 L260.0 239.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"224.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">true</text><rect x=\"270.0\" y=\"220.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"320.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">\"Medium\"</text><path d=\"M120.0 250.0 L120.0 288.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M120.0 288.0 L124.0 280.0 L116.0 280.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><text x=\"128.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">false</text><rect x=\"60.0\" y=\"290.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120.0\" y=\"305.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">\"Small\"</text><text x=\"420.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the first test that passes decides,</text><text x=\"420.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">and the tests after it are never read</text><text x=\"420.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tested in the other order, E2&gt;=4 first,</text><text x=\"420.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">catches 14 bags as Medium: 0 Large</text></svg>", "caption": "Three sizes from two tests. The nested IF asks the highest threshold first; 45, 41 and 22 sales add up to the 108."}
```

**The order of the tests is the logic.** Put them the other way round:

```localised
=IF(E2>=4,"Medium",IF(E2>=10,"Large","Small"))
```

A sale of 14 bags passes the first test, `E2>=4`, and is called `Medium` before the test for
`Large` is reached. The column now holds 0 `Large` and 63 `Medium`, and every cell looks like a
perfectly good answer. With thresholds that go up, test the highest first.

## IFS, the same thing without the nesting

Excel 2019 and later, and Microsoft 365, have `IFS`, which takes pairs of test and value and
returns the value of the first test that is `TRUE`:

```localised
=IFS(E2>=10,"Large",E2>=4,"Medium",TRUE,"Small")
```

The result is the same 22, 41 and 45. The last pair needs a word: `TRUE` is a test that always
passes, so it catches every row that failed the others. Leave it out and a sale of 3 bags passes no
test, and `IFS` answers `#N/A`. Older copies of Excel do not have `IFS` and answer `#NAME?`, so a
workbook that will be opened by other people is safer with nested `IF`.

Two or three levels of `IF` read well. Past that, a formula is hard to check and easy to break, and
a small table of thresholds is better: lesson 4 section 06 does these same three sizes with a
lookup, and the thresholds then live in cells where anybody can see and change them.
