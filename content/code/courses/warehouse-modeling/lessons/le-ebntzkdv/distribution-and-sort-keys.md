---
title: Distribution keys and sort keys
version: 1
---

A Redshift table declares how its rows are spread across slices, with `DISTSTYLE`:

| style | what happens | suits |
|---|---|---|
| `KEY` | rows are placed by a hash of the `DISTKEY` column | large tables joined on that column |
| `ALL` | a full copy of the table on every node | small dimensions |
| `EVEN` | rows dealt out in turn | tables with no good key and no joins |
| `AUTO` | Redshift chooses, and may change its mind as the table grows | the default |

and in which order rows are stored on each slice, with a `SORTKEY`, which makes the zone maps of lesson 8
skip blocks for filters on those columns.

Ana's star in Redshift's dialect (**not run**):

```sql
CREATE TABLE dim_book (
  book_key    BIGINT,
  isbn        VARCHAR(13),
  title       VARCHAR(200),
  department  VARCHAR(50)
  -- and the other columns of dim_book
)
DISTSTYLE ALL;

CREATE TABLE fact_sales (
  date_key       INTEGER,
  shop_key       BIGINT,
  book_key       BIGINT,
  customer_key   BIGINT,
  promotion_key  BIGINT,
  order_id       BIGINT,
  line_no        BIGINT,
  quantity       BIGINT,
  gross_cents    BIGINT,
  discount_cents BIGINT,
  net_cents      BIGINT
)
DISTSTYLE KEY
DISTKEY (order_id)
SORTKEY (date_key);
```

Every choice in it is one lesson 7 or 8 measured in the lab:

- **`DISTKEY (order_id)`**: 572,439 distinct values that spread four nodes to within half a per cent of each
  other, and the key `fact_payments` would share, making that join co-located.
- **Not `shop_key`**: seven values put 72% of the rows on one node.
- **`DISTSTYLE ALL` on the dimensions**: copying 3,000 books to every node moved 9,000 rows; re-spreading the
  sales by book would have moved 666,023.
- **`SORTKEY (date_key)`**: queries filter by date first, and the data arrives in date order, so the blocks
  of one month sit together and the rest are skipped: two row groups of eight, in lesson 8.

Redshift's `AUTO` settings will often reach similar choices on their own. Knowing what they are, and why, is
what lets somebody see when `AUTO` has chosen badly, which the skew figure of lesson 7 shows.
