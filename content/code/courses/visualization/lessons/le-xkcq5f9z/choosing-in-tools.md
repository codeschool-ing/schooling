---
title: Choosing palettes in your tools
version: 1
---

You will rarely design a palette from nothing, and you should not need to. Good ones exist in every
tool, under names worth knowing.

## matplotlib

| kind | names to reach for |
|---|---|
| sequential | `viridis`, `cividis`, `magma`, `Blues`, `Greys` |
| diverging | `RdBu`, `PuOr`, `BrBG` |
| categorical | `tab10`, the default line colours; or a list of Okabe and Ito's hex values |

A colour map is passed by name, `cmap="cividis"`, to any function that colours by value, such as
`imshow` or `scatter`. For a diverging map, also pass the middle, so that zero sits on the light
centre: in matplotlib, `matplotlib.colors.TwoSlopeNorm(vcenter=0)`.

## ColorBrewer

The palettes behind `RdBu`, `Blues` and many others come from **ColorBrewer**, designed by the
cartographer Cynthia Brewer for maps. Its website lets you choose the kind, sequential, diverging or
qualitative, the number of classes and whether you need it to survive colour blindness or a
photocopier, and gives the hex values. It is the best single place to pick a palette for a choropleth
(lesson 8).

## Spreadsheets and BI tools

Excel and LibreOffice let you set every series colour by hand: type the hex values instead of picking
by eye. Their conditional formatting scales take a minimum, midpoint and maximum colour, which is
enough to build an honest sequential scale (two colours) or diverging one (three, with the midpoint on
the meaningful value). Power BI and Tableau ship colour-blind-safe and diverging palettes in their
format panes; lesson 20 compares the tools.

## A last check, whatever the source

**Look at the chart in grey**, as lesson 11 suggested, and **in a colour-blindness simulator**, as
lesson 14 shows. A palette that passes both is ready for data.
