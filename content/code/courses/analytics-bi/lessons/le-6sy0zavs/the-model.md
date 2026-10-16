---
title: The model: lesson 3's star, drawn in Power BI
version: 1
---

Once the five files are loaded, Power BI's **model view** shows them as five boxes, and the model
is what you draw between them. Each line is a **relationship**: a column in one table that matches
a column in another, so that a filter on one reaches the other.

The relationships are exactly the joins of lesson 3's star:

| from (many side) | to (one side) | on |
|---|---|---|
| `orders` | `customers` | `customer_id` |
| `orders` | `calendar` | `order_date` = `day` |
| `order_lines` | `orders` | `order_id` |
| `order_lines` | `products` | `product_id` |

Power BI often proposes relationships itself, by matching column names. Check every one it proposes
against this table, and delete the ones it invented: a relationship guessed from a name is a join
nobody decided on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"pbi-model\" aria-label=\"The model as Power BI draws it: five tables joined by four relationships. Customers and calendar each join orders; orders joins order lines; products joins order lines. Every relationship is many to one, with the one side at the dimension or at orders. An arrow on each line shows the single filter direction, from the one side to the many side: from customers and calendar into orders, from orders into order lines, from products into order lines. No arrow goes from order lines back to orders.\"><defs><marker id=\"pbi-model-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">customers</text><rect x=\"20\" y=\"200\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">calendar</text><rect x=\"290\" y=\"120\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">orders</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">order_lines</text><rect x=\"560\" y=\"210\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">products</text><line x1=\"160\" y1=\"70\" x2=\"288\" y2=\"132\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#pbi-model-ah)\"></line><text x=\"168\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"276\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">*</text><line x1=\"160\" y1=\"214\" x2=\"288\" y2=\"154\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#pbi-model-ah)\"></line><text x=\"168\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"276\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">*</text><line x1=\"430\" y1=\"132\" x2=\"558\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#pbi-model-ah)\"></line><text x=\"438\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"546\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">*</text><line x1=\"630\" y1=\"210\" x2=\"630\" y2=\"86\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#pbi-model-ah)\"></line><text x=\"642\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"642\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">*</text><text x=\"360\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">a filter travels the way the arrows point, and no further</text></svg>", "caption": "Many to one, single direction: a slicer on products reaches order lines and stops there."}
```

Each relationship has two properties that matter:

- **Cardinality.** Every relationship here is **many to one**: many orders per customer, one customer
  per order. It is the star's rule — a dimension has one row per key — written as a setting. Power
  BI shows the "one" side with a `1` and the many side with an asterisk.
- **Cross-filter direction.** Which way a filter travels along the line. The default here is
  **single**: from the one side to the many side, from `customers` to `orders`. A slicer on region
  filters orders; a filter on orders does not filter customers. A later section of this lesson shows
  what that default protects, and what it costs.

## The calendar is a date table

Power BI's time functions, used later in this lesson, need a table with one row per day and no gaps,
**marked** as the model's date table (*Mark as date table*, choosing `day`). The layer's `calendar`
was built for exactly this: `generate_series` gives every day from January 2025 to June 2026, with no
gap even on 14 August 2025, the day with no orders. That matters more than it seems: a calendar built
from the dates that appear in `orders` would be missing that day, and a running total would step
over it silently.
