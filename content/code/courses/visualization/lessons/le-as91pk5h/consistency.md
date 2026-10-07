---
title: The same colour means the same thing
version: 1
---

Once a reader learns that orange is the Northeast, they stop reading the legend. That is the point of
a legend, and it means **a colour must keep its meaning in every chart a reader sees together**: a
report, a dashboard, a slide deck.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 300\" role=\"img\" data-fig=\"l13-consistency\" aria-label=\"Two pairs of small bar charts for three regions, 2024 on the left of each pair and 2025 on the right. In the top pair the colours change between the two charts: Southeast is blue in the first and orange in the second. In the bottom pair each region keeps one colour in both charts.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">colours reassigned</text><path d=\"M40.0 130.0 L240.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M54.0 53.9 h40.0 v76.1 h-40.0 Z\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1.2\"></path><path d=\"M120.7 99.0 h40.0 v31.0 h-40.0 Z\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1.2\"></path><path d=\"M187.3 98.2 h40.0 v31.8 h-40.0 Z\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1.2\"></path><text x=\"140.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><path d=\"M270.0 130.0 L470.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M284.0 42.7 h40.0 v87.3 h-40.0 Z\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1.2\"></path><path d=\"M350.7 85.1 h40.0 v44.9 h-40.0 Z\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1.2\"></path><path d=\"M417.3 90.7 h40.0 v39.3 h-40.0 Z\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1.2\"></path><text x=\"370.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><text x=\"20.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">colours kept</text><path d=\"M40.0 270.0 L240.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M54.0 193.9 h40.0 v76.1 h-40.0 Z\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1.2\"></path><path d=\"M120.7 239.0 h40.0 v31.0 h-40.0 Z\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1.2\"></path><path d=\"M187.3 238.2 h40.0 v31.8 h-40.0 Z\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1.2\"></path><text x=\"140.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><path d=\"M270.0 270.0 L470.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M284.0 182.7 h40.0 v87.3 h-40.0 Z\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1.2\"></path><path d=\"M350.7 225.1 h40.0 v44.9 h-40.0 Z\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1.2\"></path><path d=\"M417.3 230.7 h40.0 v39.3 h-40.0 Z\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1.2\"></path><text x=\"370.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><rect x=\"500.0\" y=\"120.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1\"></rect><text x=\"518.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Southeast</text><rect x=\"500.0\" y=\"142.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1\"></rect><text x=\"518.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Northeast</text><rect x=\"500.0\" y=\"164.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1\"></rect><text x=\"518.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">South</text></svg>", "caption": "A reader learns a colour on the first chart and reads the second with it. Reassign the colours and the second chart is read wrongly, with confidence."}
```

In the top pair the software assigned colours in each chart by the order of the series, so when the
order changed between 2024 and 2025, the colours moved. A reader who learnt "blue is Southeast" in the
first chart reads the second one's blue bar as Southeast, and it is South. **Nothing on the page warns
them.** In the bottom pair each region keeps its colour, and the second chart reads at a glance.

## How to keep colours fixed

- **Map colours to names, not to positions.** In code, keep a dictionary from category to colour and
  look each one up, rather than relying on the order the library assigns colours in.
- **Write the mapping down** for a team: "Southeast `#0072B2`, Northeast `#E69F00`…", in the
  project's style notes, so the next chart someone makes uses it.
- **In spreadsheets and BI tools**, set series colours by hand, and check them again when a filter
  removes a category, because some tools reassign colours to fill the gap.

## Consistency of meaning, too

The same applies to what a colour signals. If red marks a decline on page one, it must not mark the
largest value on page three. **A colour used for emphasis is used for emphasis everywhere**, and the
grey that means "context" means context in every chart.
