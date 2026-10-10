---
title: Drop-down lists that grow with a table
version: 1
---

**A list rule turns a cell into a drop-down, and a value picked from a list cannot be misspelt.**
It is the strongest rule there is for a column whose values come from a short, known set:
`Customer`, `Product` and `Channel` in `New sales`. Where the list comes from decides whether it
stays right when the business changes.

## A list typed into the rule

`Channel` has three values, and they are not going to change often. Select the `Channel` cell of
`NewSales` (G2), choose **Data › Data Validation**, **Allow: List**, and type in **Source**:
`Wholesale,Online,Shop`. Leave **In-cell dropdown** ticked. The cell now shows an arrow when it is
selected, and typing anything that is not one of the three is refused.

The commas separate the items in an Excel set to English. Where Excel separates the arguments of a
formula with semicolons, as in Portuguese, it separates the items here with semicolons too.

## A list read from a table

Products and customers do change. A list typed into the rule would have to be retyped every time
Café Serra adds a coffee, and the day somebody forgets, the new product cannot be sold through the
sheet. So the list should be read from the `Products` and `Customers` tables of lesson 7, which
already hold every code.

**The Source box of most versions of Excel refuses a structured reference such as
`=Products[Code]`, and it accepts a name.** A name can point at a table column, so the column gets
a name first:

1. **Formulas › Name Manager › New**.
2. **Name**: `ProductCodes`. **Refers to**: `=Products[Code]`. **OK**.
3. Again, with **Name** `CustomerCodes` and **Refers to** `=Customers[Customer]`.

Lesson 2 made names for ranges and constants; these two are the same thing, pointing at a column
that can grow. To check them, type in any empty cell:

```localised
=ROWS(ProductCodes)
=ROWS(CustomerCodes)
```

They answer **6** and **11**: six products and eleven customers, `C00` to `C10`. Now select the
`Product` cell of `NewSales` (D2), choose **List**, and type `=ProductCodes` in **Source**. Do the
same on the `Customer` cell (C2) with `=CustomerCodes`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" data-fig=\"l08-list\" aria-label=\"A chain of three steps. On the left, the Code column of the Products table, with six codes and a dashed seventh row for a product added later. In the middle, a name, ProductCodes, which refers to Products[Code]. On the right, the Product cell of the NewSales table with its drop-down open, listing the same six codes and, dashed, the seventh.\"><text x=\"40.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">table Products, column Code</text><text x=\"32.0\" y=\"51.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"40.0\" y=\"40.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"51.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Code</text><text x=\"32.0\" y=\"73.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"40.0\" y=\"62.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"73.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SUL250</text><text x=\"32.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"40.0\" y=\"84.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SUL1K</text><text x=\"32.0\" y=\"117.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"40.0\" y=\"106.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"117.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER250</text><text x=\"32.0\" y=\"139.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"40.0\" y=\"128.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"139.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER1K</text><text x=\"32.0\" y=\"161.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><rect x=\"40.0\" y=\"150.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"161.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">MOG250</text><text x=\"32.0\" y=\"183.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><rect x=\"40.0\" y=\"172.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"183.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DEC250</text><rect x=\"40.0\" y=\"194.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"40.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a new product: the table</text><text x=\"40.0\" y=\"247.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">grows by one row</text><text x=\"270.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a name</text><rect x=\"270.0\" y=\"100.0\" width=\"170.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"355.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">ProductCodes</text><text x=\"355.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">=Products[Code]</text><text x=\"270.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">points at the column,</text><text x=\"270.0\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">however long it is</text><path d=\"M146.0 129.0 L264.0 129.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M264.0 129.0 L256.0 125.0 L256.0 133.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"540.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the rule on NewSales[Product]</text><text x=\"540.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Source: =ProductCodes</text><rect x=\"540.0\" y=\"64.0\" width=\"150.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"75.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER1K</text><rect x=\"690.0\" y=\"64.0\" width=\"22.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M695 72 L707 72 L701 79 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--paper)\"></path><rect x=\"540.0\" y=\"90.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"100.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SUL250</text><rect x=\"540.0\" y=\"110.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"120.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SUL1K</text><rect x=\"540.0\" y=\"130.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"140.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER250</text><rect x=\"540.0\" y=\"150.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"160.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER1K</text><rect x=\"540.0\" y=\"170.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"180.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">MOG250</text><rect x=\"540.0\" y=\"190.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"200.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DEC250</text><rect x=\"540.0\" y=\"210.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">and the list follows</text><path d=\"M446.0 129.0 L534.0 129.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M534.0 129.0 L526.0 125.0 L526.0 133.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path></svg>", "caption": "The list rule reads a name, and the name reads the table's column. A product added to the Products table appears in every drop-down built on the name, and nobody edits a rule."}
```

## Why not `=Products!$A$2:$A$7`

That address works today and gives the same six codes. It stops working on the day the `Products`
table gets a seventh row, because `$A$2:$A$7` is six cells and stays six cells. The name points at
`Products[Code]`, which is the column of the table, however long the table is. The drop-down then
offers the seventh product without anybody touching the rule.

The same reasoning is why the rule sits on a column of `NewSales`: the table carries the rule to
each new row, and the name carries each new product to the rule.

## What a list does not do

A drop-down shows the codes, not what they mean: `C07` is in the list and `Escritório Faro` is
not. A column beside the code that looks the name up, with the `XLOOKUP` of lesson 4, shows the
person typing whom they picked. The list also offers values in the order the table holds them,
so a long list is easier to use when its table is sorted.
