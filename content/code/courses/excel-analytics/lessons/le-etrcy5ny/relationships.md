---
title: Relationships, and which way a filter flows
version: 1
---

**A relationship tells the model that a column of one table holds the key of another.** It is the
pointer of lesson 1 section 06, written down where Excel can follow it: `Sales[Product]` holds codes,
and each code names one row of `Products`. Once the model knows that, a pivot table can put
`Products[Origin]` in its rows and add up `Sales[Revenue]` beneath it, and no formula fetches
anything.

Two of the three relationships can be drawn now. The third joins `Sales[Date]` to the calendar of
the next section.

| from, the many side | to, the one side |
|---|---|
| `Sales[Product]` | `Products[Code]` |
| `Sales[Customer]` | `Customers[Customer]` |
| `Sales[Date]` | `Calendar[Date]`, in section 06 |

## Drawing one

In the Power Pivot window, **Home › Diagram View** shows each table as a box with its columns
listed. Drag `Product` from the `Sales` box and drop it on `Code` in the `Products` box. A line
appears between the two boxes, with a `1` at the `Products` end and an asterisk at the `Sales`
end. Do the same from `Sales[Customer]` to `Customers[Customer]`.

There are two other ways to the same result, and they make the same line: **Design › Create
Relationship** in the Power Pivot window, which asks for the two tables and the two columns in a
dialog, and **Data › Relationships › New** in Excel itself. Use whichever you find; the diagram is
the one that shows you the whole model at once, and it is worth opening after any change.

## The rules a relationship has to obey

**The one side has to be unique.** `Products[Code]` holds six codes and no code twice, so each sale
finds exactly one product. If `CER1K` appeared on two rows of `Products`, a sale of `CER1K` would
not know which one it meant, and Excel refuses to create the relationship rather than guess. This is
the reason lesson 1 section 06 insisted that a key identifies one row: here the model checks it.

**Both columns have to be of the same type.** Text joins text and a date joins a date. A code that
is text on one side and a number on the other matches nothing, which is why the previous section
checked the types.

**A value on the many side that finds no row is not an error, and it is not dropped either.** A sale
of a product code missing from `Products` would still be counted, under a row labelled `(blank)`.
On your data there is none: every one of the 108 sales names a product and a customer that exist.
A `(blank)` row in a pivot table built on a model is worth reading as a question: which key has no
row on the other side?

## A filter flows from the one side to the many side

The arrows in the figure of section 03 point from each dimension to the facts, and they are the
most important thing in this section. **A filter on a dimension reaches the fact table; a filter on the
fact table does not reach the dimension.** Choose `Cerrado` in `Products[Origin]` and the model keeps
the two Cerrado products, then the sales that point at them. That is a star schema working.

The other direction is where a model surprises people. Put `Sales[Channel]` in a pivot table's rows
and **Count of Code**, a count of `Products[Code]`, in its values. The pivot table answers:

| `Channel` | Count of Code | sales in that channel |
|---|---|---|
| `Online` | 6 | 47 |
| `Shop` | 6 | 23 |
| `Wholesale` | 6 | 38 |

Six on every row. The filter on `Channel` lives in `Sales`, at the many end, and it does not climb
the line back to `Products`, so each row counts all six products, whatever was sold. Nothing is
broken: the question is asked the wrong way round. **To count something per channel, count it in
`Sales`**, where the channel is, and lesson 16 does exactly that with a measure.

## Forgetting a relationship

The other surprise looks similar and has a different cause. Put `Products[Origin]` in the rows and
`Sales[Revenue]` in the values of a model pivot table **before** the relationship exists, and every
row shows the same number:

| `Origin` | Sum of Revenue |
|---|---|
| `Cerrado` | 51,494 |
| `Mogiana` | 51,494 |
| `Sul de Minas` | 51,494 |

R$ 51,494 is all the revenue there is. With no line between the tables, choosing `Cerrado` filters
`Products` and reaches nothing else, so each row adds up all of `Sales`. Excel notices: the pivot
table's field list shows a notice that relationships may be needed, with a button to create one.
**The same number repeated down a column is the symptom, whatever the notice says.** Section 07 shows
the same pivot table with the relationship in place.
