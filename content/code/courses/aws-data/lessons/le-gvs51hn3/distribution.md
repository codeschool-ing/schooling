---
title: Distribution styles, and the slice that does all the work
version: 1
---

**A table's distribution style decides which slice each row lives on**, and with it two things a
query's speed depends on: whether every slice has the same amount of work, and whether a join can
find matching rows on the same slice or has to move them across the network first. There are four
styles, and the wrong one does not fail. It makes one slice do most of the work while the others
wait, and it shows up only as a query that is slower than it should be.

| style | where a row goes | suits |
|---|---|---|
| `AUTO` | Redshift chooses, and changes its choice as the table grows | the default, and a reasonable start |
| `EVEN` | dealt out to the slices in turn | a table that is never joined on one column |
| `KEY` | the slice a hash of one column points to | two large tables joined on that column |
| `ALL` | a full copy on every node | a small table joined to everything |

**`AUTO` starts a small table as `ALL` and moves it to `EVEN` as it grows**, and AWS documents that
it may switch to `KEY` when it sees which column the table is joined on. It is a sound default, and
the other three exist for when you know the joins better than the statistics do.

## The tables, written down

Quitanda's warehouse has three tables to begin with: the stores, a few dozen rows; the customers;
and the orders, the large one. The DDL says how each is laid out, `orders.sql`:

```sql
CREATE TABLE stores (
    store_id     SMALLINT     NOT NULL,
    name         VARCHAR(64)  NOT NULL,
    district     VARCHAR(32)  NOT NULL
)
DISTSTYLE ALL;

CREATE TABLE customers (
    customer_id  VARCHAR(8)   NOT NULL,
    district     VARCHAR(32)  NOT NULL,
    signed_up    DATE         NOT NULL
)
DISTSTYLE KEY
DISTKEY (customer_id);

CREATE TABLE orders (
    order_id     VARCHAR(16)  NOT NULL,
    customer_id  VARCHAR(8)   NOT NULL,
    store_id     SMALLINT     NOT NULL,
    total_cents  INTEGER      NOT NULL,
    dt           DATE         NOT NULL
)
DISTSTYLE KEY
DISTKEY (customer_id)
COMPOUND SORTKEY (dt, customer_id);
```

**`stores` is `ALL`**: it is tiny and every report joins it, so each node keeps a copy and no join
with it ever moves a row. The price is that every load of `stores` is written once per node, which
is nothing at forty rows and would be a great deal at forty million. **`customers` and `orders` are
both `KEY` on `customer_id`**, so an order and the customer who placed it hash to the same slice, and
joining them moves nothing. The sort key is the next section's subject.

Sent to moto, the file is accepted the way the statement in the previous section was, and none of
it runs:

```
ana@laptop:~/aws$ aws redshift-data execute-statement --cluster-identifier quitanda-dw --database quitanda --sql file://orders.sql --query Id --output text
8622c371-a211-4ad9-9815-0c2369cfbedd
ana@laptop:~/aws$ aws redshift-data describe-statement --id 8622c371-a211-4ad9-9815-0c2369cfbedd --query '[Status,HasResultSet]' --output text
STARTED	False
```

What a key does to the rows can still be measured, with a model: a program that puts ten thousand orders on four slices the way a
hash would. **It is a model of the arithmetic, not Redshift**, and it is small enough to read
whole. Save it as `~/aws/slices.py`:

```schooling-example
{"language": "python", "file": "slices.py", "parts": [{"code": "import hashlib\nimport random\n\nSLICES = 4\nrng = random.Random(14)\norders = []\nfor n in range(10_000):\n    if rng.random() < 0.4:\n        customer = 'c-01'\n    else:\n        customer = f'c-{rng.randint(2, 500):02d}'\n    orders.append((f'o-{n:05d}', customer))\n\n\n", "note": "Ten thousand orders, made the same way on every run because the random generator is seeded. **Two in five belong to `c-01`**, a restaurant chain that buys for all its kitchens; the rest are spread over 499 households. Four slices, as in two `ra3.xlplus` nodes."}, {"code": "def slice_of(value):\n    return int(hashlib.md5(value.encode()).hexdigest(), 16) % SLICES\n\n\n", "note": "Where a key value lands: a hash of it, modulo the number of slices. Redshift uses a hash function of its own; MD5 stands in for it here, and any hash shows the same thing."}, {"code": "def show(label, placed):\n    counts = [placed.count(s) for s in range(SLICES)]\n    mean = len(placed) / SLICES\n    cells = '  '.join(f'{c:>5}' for c in counts)\n    print(f'{label:<22}{cells}   max/mean {max(counts) / mean:.2f}')\n\n\n", "note": "Counts the rows on each slice and prints them with the ratio of the fullest slice to the average. 1.00 is perfectly even."}, {"code": "print(f'{\"\":<22}' + '  '.join(f'sl {s:>2}' for s in range(SLICES)))\nshow('DISTSTYLE EVEN', [n % SLICES for n in range(len(orders))])\nshow('DISTKEY (order_id)', [slice_of(o) for o, _ in orders])\nshow('DISTKEY (customer_id)', [slice_of(c) for _, c in orders])\n\n", "note": "Three ways to place the same orders. `EVEN` deals them out in turn. A key on `order_id` hashes a value that is different on every row. A key on `customer_id` hashes a value that `c-01` repeats four thousand times."}, {"code": "moved = sum(slice_of(o) != slice_of(c) for o, c in orders)\nprint(f'join on customer_id, orders keyed on order_id: {moved:,} of {len(orders):,} rows move')\n", "note": "A join of these orders to a `customers` table distributed on `customer_id`. An order sits next to its customer only if both hashed to the same slice; every other row has to be sent across the network before the join can run."}]}
```

```
ana@laptop:~/aws$ python3 slices.py
                      sl  0  sl  1  sl  2  sl  3
DISTSTYLE EVEN         2500   2500   2500   2500   max/mean 1.00
DISTKEY (order_id)     2543   2469   2439   2549   max/mean 1.02
DISTKEY (customer_id)  5420   1506   1731   1343   max/mean 2.17
join on customer_id, orders keyed on order_id: 7,449 of 10,000 rows move
```

**`EVEN` and the key on `order_id` came out level, and the key on `customer_id` did not**: slice 0
holds 5,420 rows and slice 3 holds 1,343, so the fullest slice has 2.17 times the average. Every
query that scans `orders` waits for slice 0, so the cluster runs at roughly the speed of a cluster
with half its slices. A key spreads rows evenly only when the column has many values, each about
equally common. `customer_id` passes that test for Quitanda's households and fails it the day one
customer is a restaurant chain.

**The key on `order_id` is level and moves the rows instead.** Joining those orders to `customers`
on `customer_id` meant sending 7,449 of the 10,000 rows to another slice first, about three in four,
which is what a hash that ignores the join column gives with four slices. In Redshift's own plan
that movement is a step called `DS_DIST_INNER` or `DS_DIST_BOTH`, where one or both sides are
redistributed for the query, or `DS_BCAST_INNER`, where a whole table is copied to every node; a
join with nothing to move is `DS_DIST_NONE`. Those names come from AWS's documentation of `EXPLAIN`,
not from a run.

**So the choice is a trade between the two failures**, and it is made per table: key the large
tables on the column they are joined on, as long as no single value of it dominates; make the small
ones `ALL`; and use `EVEN` for a large table with no dominant join. On a real cluster, the system
view `SVV_TABLE_INFO` reports a `skew_rows` column, the ratio of the fullest slice to the emptiest,
and checking it after the first load is how a key like `customer_id` gets caught before a report
does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The ten thousand orders of the slices.py model on four slices, in three layouts. DISTSTYLE EVEN puts 2,500 rows on every slice. DISTKEY on order_id puts between 2,439 and 2,549. DISTKEY on customer_id puts 5,420 rows on slice 0 and between 1,343 and 1,731 on the others, 2.17 times the mean, because customer c-01 has two orders in five.\" data-fig=\"l14-skew\"><text x=\"16\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DISTSTYLE EVEN</text><text x=\"16\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max/mean 1.00</text><rect x=\"200\" y=\"22\" width=\"169.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"29\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 0</text><text x=\"375.6\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2,500</text><rect x=\"200\" y=\"41\" width=\"169.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 1</text><text x=\"375.6\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2,500</text><rect x=\"200\" y=\"60\" width=\"169.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"67\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 2</text><text x=\"375.6\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2,500</text><rect x=\"200\" y=\"79\" width=\"169.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 3</text><text x=\"375.6\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2,500</text><text x=\"16\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DISTKEY (order_id)</text><text x=\"16\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max/mean 1.02</text><rect x=\"200\" y=\"114\" width=\"172.6\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"121\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 0</text><text x=\"378.6\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2,543</text><rect x=\"200\" y=\"133\" width=\"167.5\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 1</text><text x=\"373.5\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2,469</text><rect x=\"200\" y=\"152\" width=\"165.5\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"159\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 2</text><text x=\"371.5\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2,439</text><rect x=\"200\" y=\"171\" width=\"173.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 3</text><text x=\"379.0\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2,549</text><text x=\"16\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DISTKEY (customer_id)</text><text x=\"16\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">max/mean 2.17</text><rect x=\"200\" y=\"206\" width=\"367.8\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"213\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 0</text><text x=\"573.8\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">5,420</text><rect x=\"200\" y=\"225\" width=\"102.2\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 1</text><text x=\"308.2\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1,506</text><rect x=\"200\" y=\"244\" width=\"117.5\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"251\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 2</text><text x=\"323.5\" y=\"251\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1,731</text><rect x=\"200\" y=\"263\" width=\"91.1\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"192\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sl 3</text><text x=\"297.1\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1,343</text><polyline points=\"369.6428571428571,16 369.6428571428571,284\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"373.6428571428571\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mean, 2,500 rows</text></svg>", "caption": "A key with one dominant value puts most of the work on one slice. Counts from the model, not from Redshift."}
```
