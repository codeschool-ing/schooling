---
title: Orphans, and why they are orphans
version: 1
---

An **orphan** is a row whose key points at nothing: an order whose customer is not in the
customer file. The checked join counts them for free:

```
ana@lab:~/clean$ python -c "from when import orders; from raw_customers import customers; from joins import join; j = join(orders, customers[['customer_id', 'name']], 'customer_id')"
join on customer_id: 28526 rows in, 28526 out, 246 with no match
```

246 orders, out of 28,526, have no customer. That is under 1%, small enough to ignore, and
ignoring it would be a mistake, because **orphans are rarely random**. A key with no partner is
almost always the trace of something that happened to one of the two files, and the work is
finding out what.

Two questions usually find it: who are they, and when? This company's CRM file was exported on 10
December 2025, a date the person who sent the file can tell you and the file cannot. The orders
run to 31 December. So the first test is whether each orphan customer's first order came before
or after the export:

```schooling-example
{
  "language": "python",
  "file": "orphans.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "from raw_customers import customers\nfrom when import orders\n\n",
      "note": "The customers without repeated rows, and the orders with `placed`, their time in São Paulo, from lesson 7."
    },
    {
      "code": "EXPORTED = pd.Timestamp(\"2025-12-10\")  # the CRM file's date, from the person who sent it\n",
      "note": "**The export date is a fact about the file**, and it comes from the person who sent it."
    },
    {
      "code": "alone = orders[~orders[\"customer_id\"].isin(customers[\"customer_id\"])]\n",
      "note": "The orders whose customer is not in the CRM."
    },
    {
      "code": "first = alone.groupby(\"customer_id\")[\"placed\"].agg([\"min\", \"max\", \"size\"])\n",
      "note": "Per orphan customer: first order, last order, how many."
    },
    {
      "code": "first[\"kind\"] = (first[\"min\"] >= EXPORTED).map({True: \"new since export\", False: \"left the CRM\"})\n\n",
      "note": "**The test**: did the first order come after the export?"
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(first.groupby(\"kind\").agg(customers=(\"size\", \"size\"), orders=(\"size\", \"sum\"),\n                                    first=(\"min\", \"min\"), last=(\"max\", \"max\")).to_string())\n",
      "note": "Customers, orders and dates per group."
    }
  ]
}
```

```
ana@lab:~/clean$ python orphans.py
                  customers  orders               first                last
kind                                                                       
left the CRM             12     216 2025-01-01 17:24:22 2025-12-28 11:10:16
new since export         20      30 2025-12-14 10:25:10 2025-12-31 18:41:51
```

The 32 customers fall into two groups that have nothing in common.

- **20 are new since the export.** Their first order is on 14 December or later, 30 orders between
  them. The CRM is not wrong; it is old. The fix is a fresher export, and until then, a sentence
  in the report saying that the last three weeks' new customers have no details.
- **12 left the CRM.** They ordered throughout the year, the earliest on 1 January, 216 orders in all, and
  they are not in a file exported in December. Customers do not vanish from a CRM by accident:
  these are people who asked for their data to be erased, which the LGPD lets anyone do.

The second group needs care in both directions. **The orders stay**: they are sales, they are in
the accounts, and revenue without them is wrong. **The people stay gone**: nothing in the analysis
may try to work out who they were, by matching the orders' addresses or anything else. They are
counted as orders from customers whose details were removed, and that is all.

The lab's answer key confirms the reading:

```
ana@lab:~/clean$ python -c "import pandas as pd; from orphans import first; e = pd.read_csv('~/clean-data/truth/erased.csv'); gone = first[first['kind'] == 'left the CRM']; print(len(gone), gone.index.isin(e['customer_id']).sum(), len(e))"
12 12 12
```

All 12 are in the list of erased customers, and the list has 12. In real work there is no such
file; the confirmation comes from whoever handles erasure requests, and asking is part of the job.
