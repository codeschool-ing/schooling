---
title: Consistency and uniqueness: one thing, one way, once
version: 1
---

**Consistency asks whether the same fact is recorded the same way everywhere it appears.**
Within a column, that means one spelling per value and one format per type. Across files, it
means that two records of the same thing agree. **Uniqueness** is its close relative: each thing
in the world appears once in the data that claims to list it.

## Within a column

Quitanda Verde serves five cities. Its customer file disagrees:

```
ana@lab:~/clean$ psql -c "SELECT count(DISTINCT city) AS spellings FROM raw.customers"
 spellings 
-----------
        28
(1 row)

ana@lab:~/clean$ psql -c "SELECT normalize(city, NFC) AS city_as_shown, octet_length(city) AS bytes, count(*) FROM raw.customers WHERE city ILIKE '%paulo%' GROUP BY city ORDER BY count(*) DESC"
 city_as_shown | bytes | count 
---------------+-------+-------
 São Paulo     |    10 |   458
 São Paulo     |    11 |   213
 Sao Paulo     |     9 |    96
 SAO PAULO     |     9 |    59
 são paulo     |    10 |    37
 S. Paulo      |     8 |    33
 São Paulo     |    11 |    25
 SÃ£o Paulo    |    12 |     9
 são paulo     |    11 |     9
 São Paulo     |    12 |     9
 sÃ£o paulo    |    12 |     1
(11 rows)
```

Twenty-eight spellings for five cities, eleven of them for São Paulo alone. Some differences are
visible — `SAO PAULO`, `S. Paulo`, `Sao Paulo` — and some are not. **The first two rows look
identical and are different strings**, ten bytes against eleven. The app stores the accent of `ã`
as a separate character after the `a`, so the bytes differ while the screen shows the same word;
lesson 6 takes it apart. (The query passes the column through `normalize()` only to print it,
because the separate accent would otherwise knock this very table out of line.) A trailing space
is the same trick at the end of a word: the row of 25 is `São Paulo ` with eleven bytes. `SÃ£o
Paulo` is what a migration in 2023 left behind after reading UTF-8 as if it were Latin-1.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 346\" role=\"img\" data-fig=\"l01-sao-paulo\" aria-label=\"A bar chart of the 11 ways the city column of customers.csv spells São Paulo, 949 customers in all. The correct spelling has 458 rows; the rest are split between a decomposed accent, no accent, capitals, an abbreviation, a trailing space and text mangled by a migration.\"><text x=\"200.0\" y=\"49.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;São Paulo&quot;</text><rect x=\"210.0\" y=\"40.0\" width=\"260.0\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"476.0\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">458</text><text x=\"500.0\" y=\"49.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the spelling everybody means</text><text x=\"200.0\" y=\"75.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;São Paulo&quot;</text><rect x=\"210.0\" y=\"66.0\" width=\"120.9\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"336.9\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">213</text><text x=\"500.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">accent stored apart</text><text x=\"200.0\" y=\"101.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Sao Paulo&quot;</text><rect x=\"210.0\" y=\"92.0\" width=\"54.5\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270.5\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">96</text><text x=\"500.0\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no accent</text><text x=\"200.0\" y=\"127.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;SAO PAULO&quot;</text><rect x=\"210.0\" y=\"118.0\" width=\"33.5\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"249.5\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">59</text><text x=\"500.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no accent, capitals differ</text><text x=\"200.0\" y=\"153.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;são paulo&quot;</text><rect x=\"210.0\" y=\"144.0\" width=\"21.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"237.0\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">37</text><text x=\"500.0\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">capitals differ</text><text x=\"200.0\" y=\"179.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;S. Paulo&quot;</text><rect x=\"210.0\" y=\"170.0\" width=\"18.7\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"234.7\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">33</text><text x=\"500.0\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abbreviated</text><text x=\"200.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;São Paulo &quot;</text><rect x=\"210.0\" y=\"196.0\" width=\"14.2\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"230.2\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">25</text><text x=\"500.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a space after it</text><text x=\"200.0\" y=\"231.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;SÃ£o Paulo&quot;</text><rect x=\"210.0\" y=\"222.0\" width=\"5.1\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"221.1\" y=\"231.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><text x=\"500.0\" y=\"231.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">accent mangled in 2023</text><text x=\"200.0\" y=\"257.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;São Paulo &quot;</text><rect x=\"210.0\" y=\"248.0\" width=\"5.1\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"221.1\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><text x=\"500.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">accent stored apart, a space after it</text><text x=\"200.0\" y=\"283.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;são paulo&quot;</text><rect x=\"210.0\" y=\"274.0\" width=\"5.1\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"221.1\" y=\"283.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><text x=\"500.0\" y=\"283.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">accent stored apart, capitals differ</text><text x=\"200.0\" y=\"309.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;sÃ£o paulo&quot;</text><rect x=\"210.0\" y=\"300.0\" width=\"0.6\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"216.6\" y=\"309.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><text x=\"500.0\" y=\"309.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">accent mangled in 2023, capitals differ</text><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">city, in customers.csv</text><text x=\"500.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what is different</text></svg>", "caption": "One city, 11 values. Only the first bar is what a GROUP BY would call São Paulo."}
```

Any `GROUP BY city` over this column reports eleven cities where there is one, and the largest of
them, the correct spelling, holds 458 of the 949 rows. A chart of customers by city would show
São Paulo at less than half its size, and nothing in the query would look wrong.

Dates are the same problem with worse consequences, because a date in the wrong format still
sorts:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, min(signed_up), max(signed_up) FROM raw.customers GROUP BY signup_channel"
 signup_channel |    min     |    max     
----------------+------------+------------
 site           | 2023-01-19 | 2025-12-10
 app            | 01/02/2024 | 12/31/2024
 import-2023    | 01/06/2023 | 25/08/2023
 store          | 01/01/2024 | 31/12/2024
(4 rows)
```

The website writes `2025-12-10`, the app writes `12/31/2024` with the month first, and the shops
write `31/12/2024` with the day first. As text, `max()` compares characters, so the app's latest
date is `12/31/2024` even though the app signed people up all through 2025: a date such as
`12/05/2025` sorts below `12/31/2024`, because `0` comes before `3`. **A column holding three date formats does not
fail; it answers a different question from the one you asked.** Lesson 7 converts them.

## Uniqueness

An order number should identify one order:

```
ana@lab:~/clean$ psql -c "SELECT count(*) AS rows, count(DISTINCT order_id) AS order_ids FROM raw.orders"
 rows  | order_ids 
-------+-----------
 28551 |     28526
(1 row)
```

28,551 rows and 28,526 order numbers: 25 orders appear twice. The app resends an order when it
does not hear back in time, and both copies reached the export. Every one of them was counted
twice in the revenue figure of the previous section. Lesson 5 is about finding duplicates, and
these are the easy kind — same key, same row. The hard kind is the same person under two keys,
which a count of distinct ids cannot see at all.

## Across files

The order's total should equal its lines, less the discount, plus the delivery fee. The orders
should belong to customers the customer file knows. Both are consistency between two files, and
both fail here: lesson 9 finds the totals that disagree with their own lines, and the next section
counts the orders that belong to nobody.
