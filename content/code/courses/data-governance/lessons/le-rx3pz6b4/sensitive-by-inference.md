---
title: Sensitive by what it reveals
version: 1
---

`sales.order_items` has five columns: an order, a line number, a product, a quantity and a price.
Nothing in it was designed as health data. Here is what it says about Ipê's customers:

```sql
-- What a pharmacy's order lines say about the people who placed them.
SET ROLE ipe_owner;
SELECT p.category,
       count(DISTINCT o.customer_id) AS customers
FROM sales.order_items i
JOIN sales.orders o   USING (order_id)
JOIN sales.products p USING (product_id)
WHERE p.category IN ('psychiatric', 'diabetes', 'contraceptive',
                     'diagnostic', 'cardiovascular', 'thyroid')
GROUP BY p.category ORDER BY customers DESC;
```

```
ana@lab:~/gov$ psql -f inferred.sql
SET
    category    | customers 
----------------+-----------
 psychiatric    |      3531
 cardiovascular |      2581
 diabetes       |      2560
 contraceptive  |      1664
 thyroid        |      1645
 diagnostic     |      1606
(6 rows)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT name, category FROM sales.products WHERE category = 'diagnostic'"
SET
       name        |  category  
-------------------+------------
 Teste de gravidez | diagnostic
(1 row)
```

3,531 customers bought a psychiatric medicine; 2,560 something for diabetes; 1,664 a contraceptive.
And the one product in `diagnostic`:

**A pregnancy test.** 1,606 customers bought one. A purchase history is therefore data about health
and sex life for a large part of Ipê's customers — sensitive data in the sense of article 5, II, not
because anybody labelled it so but because of what it reveals. The lab's purchases are generated and
spread evenly across products, so the numbers are higher than a real pharmacy's would be; the
conclusion does not depend on them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l6-inference\" aria-label=\"An order line holds a product id. The product belongs to a category. The category says something about the buyer's health: psychiatric, diabetes, contraceptive, a pregnancy test. The order line is therefore health data, though no column says so.\"><defs><marker id=\"dg-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"60.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">order_items</text><text x=\"95.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">product_id = 25</text><rect x=\"215.0\" y=\"60.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">products</text><text x=\"290.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Clonazepam 2 mg</text><rect x=\"410.0\" y=\"60.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">category</text><text x=\"480.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">psychiatric</text><rect x=\"595.0\" y=\"50.0\" width=\"105.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reveals</text><text x=\"647.5\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a health</text><text x=\"647.5\" y=\"105.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">condition</text><path d=\"M170.0 90.0 L213.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M365.0 90.0 L408.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M550.0 90.0 L593.0 90.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no column of order_items is called health, and the row is health data</text></svg>", "caption": "What a row reveals, not where it is filed, decides whether it is sensitive."}
```

## What follows

**`product_id` in a pharmacy's order lines is a sensitive column**, and section 7 classifies it that
way. The consequence is concrete:

- the analysts' grant on `order_items` from lesson 2 is a grant on health data, and needs the legal
  basis and the care that implies;
- an export of order lines to a marketing partner is a transfer of health data;
- a model trained on purchase histories to "recommend products" is processing health data, and may
  be making inferences about people's conditions that they never shared.

**Inference also works without a product name.** A pattern of orders every 30 days for the same
prescription-only item, the timing of purchases, a change in basket size — derived columns and
models can reveal what the raw table did not show at a glance. A classification exercise that only
reads column names misses all of it; one that asks *"what could somebody conclude from this?"* finds
it.
