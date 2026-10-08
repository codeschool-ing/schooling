---
title: Three kinds of data, three kinds of palette
version: 1
---

Lesson 1 said hue separates and lightness orders. Lesson 11 measured both. This lesson turns them into
the decision every chart with colour has to make: **which kind of palette does this data need?** There
are three, and the data decides, not taste.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 220\" role=\"img\" data-fig=\"l12-three-kinds\" aria-label=\"Three rows of swatches. Categorical: eight clearly different hues of similar weight, orange, sky blue, green, yellow, blue, vermilion, pink and black. Sequential: seven steps of viridis, from dark purple through blue and green to bright yellow, always getting lighter. Diverging: seven steps of a red-to-blue scale, dark red, light red, nearly white in the middle, light blue, dark blue.\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">categorical: kinds of thing</text><rect x=\"20.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#E69F00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#56B4E9\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"100.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#009E73\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"140.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#F0E442\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"180.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#0072B2\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"220.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#D55E00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"260.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#CC79A7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"300.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#000000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"20.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sequential: low to high</text><rect x=\"20.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#440154\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#443983\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"100.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#31688e\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"140.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#21918c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"180.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#35b779\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"220.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#90d743\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"260.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#fde725\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">diverging: below and above a middle</text><rect x=\"20.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#67001f\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#c94741\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"100.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#f7b799\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"140.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#f6f7f7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"180.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#a7d0e4\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"220.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#3783bb\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"260.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#053061\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect></svg>", "caption": "Three kinds of palette for three kinds of data. Hue separates kinds; lightness orders amounts; two hues meeting at a light middle show which side of a reference a value is on."}
```

| the data | the palette | built from |
|---|---|---|
| categories with no order: regions, products | **categorical** | different hues at similar lightness |
| quantities from low to high: orders, revenue | **sequential** | one direction of lightness, light to dark |
| quantities around a meaningful middle: change, difference from a target, correlation | **diverging** | two hues meeting at a light centre |

The question that settles it is **"does the middle mean something?"** If the values only go up, it is
sequential. If zero, or a target, or an average splits them into two meaningful sides, it is
diverging. If the values are names, it is categorical.

## The mistakes are all mismatches

- **A categorical palette on quantities.** Each value gets an unrelated hue, and the reader has to
  consult a legend to learn that green means more than purple.
- **A sequential palette on categories.** Five products in five shades of blue, and the reader looks
  for an order the products do not have, as lesson 1 warned.
- **A diverging palette on quantities with no middle.** Order counts coloured red to blue make the
  lower half look like a problem, when it is only smaller.
- **A sequential palette on data with a middle.** A map of profit and loss in one hue hides which
  regions lose money, because the line between the two is just another shade.

The next two sections take each kind in turn.
