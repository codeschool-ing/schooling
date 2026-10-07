---
title: Formats that travel
version: 1
---

The feed leaves Ipê as a file. The format is the part of interoperability that is mostly solved, and
the few ways it still goes wrong are worth knowing by heart:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "\copy (SELECT * FROM share.delivery_feed ORDER BY order_id LIMIT 3) TO STDOUT WITH (FORMAT csv, HEADER)"
SET
order_id,ordered_on,cep,city,state,items
100467,2026-06-30,01613-005,São Paulo,SP,3
100867,2026-06-30,20183-954,Rio de Janeiro,RJ,6
101189,2026-06-30,01279-281,São Paulo,SP,1
```

That CSV is a good one, and every property of it is a choice:

- **a header row**, so a column is found by name rather than by position;
- **dates in ISO 8601** — `2026-06-30` — and never `30/06/2026`, which a system set to the United
  States reads as an impossible date, or `06/07/2026`, which it reads as a different day without
  complaint;
- **UTF-8**, so `São Paulo` arrives as `São Paulo`. A file written in an older Windows encoding and
  read as UTF-8 turns it into mojibake, and an address no courier can find;
- **no decimal numbers** in this feed — but where there are, a decimal point and no thousands
  separator. In Brazil a spreadsheet writes `1.234,56`, and the comma is also CSV's separator;
- **CEPs as text.** `01613-005` read as a number loses its leading zero and its dash, and a spreadsheet
  will do exactly that if nobody tells it otherwise.

## Beyond CSV

CSV has no types: every value is text until somebody decides otherwise, which is where the list above
comes from. **JSON** carries types for numbers, booleans and nulls, and JSON Schema can describe it.
**Parquet** stores a typed schema inside the file and compresses well, and is the usual format for
large datasets between data platforms. The contract names the format, and for CSV it names the
encoding, the separator and the date format, because CSV itself will not.

## Portability is interoperability for a person

Lesson 7's right of **portability** (LGPD article 18, V) and the GDPR's article 20 — data in a
*structured, commonly used and machine-readable format* — are the same problem with a person as the
consumer. The JSON export of lesson 7 meets it for the same reasons this CSV does: named fields, typed
values, a standard encoding. A PDF of a customer's orders is readable by a person and by no other
system, and is not a portable format.
