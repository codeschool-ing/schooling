---
title: One workload, priced three ways
version: 1
---

**The "my orders" screen of Quitanda's app is a workload with a clear shape**: a customer opens it,
the app asks for that customer's last ten orders, and the screen has to appear well within a second.
Three million openings a month, six hundred thousand new orders a month, fifty gigabytes of orders
kept. The access pattern is a few items by one key, which the tree of two sections back sends to
Cosmos DB, and the point of this section is to see what the other branches would have cost, with
arithmetic rather than with an opinion.

The arithmetic is a program, so that its assumptions are written down and can be changed. **It runs
on your computer with nothing but Python, and it asks Azure nothing**: every price in it is an
illustrative round number, labelled as such, and every estimate of the workload is marked as one.
Save it as `compare.py`:

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "LOOKUPS = 3_000_000          # \"my orders\" opened, per month\nWRITES = 600_000             # new orders, per month\nSTORED_GB = 50\n\n", "note": "**The workload, in numbers**: the screen opened three million times a month, six hundred thousand new orders, fifty gigabytes kept."}, {"code": "# Illustrative prices, round numbers for the arithmetic: not Azure's.\nCOSMOS_PER_MILLION_RU = 0.25\nCOSMOS_PER_GB = 0.25\nSQL_PER_VCORE_HOUR = 0.25\nSQL_PER_GB = 0.12\nSERVERLESS_PER_TB = 5.00\n\n", "note": "**Every price here is illustrative**, a round number for the arithmetic and not Azure's. The price sheet of lesson 1 gives the real ones, with their units and dates."}, {"code": "# Assumptions about the workload, to be replaced by measurements.\nRU_PER_LOOKUP = 3            # one in-partition query returning ten small orders\nRU_PER_WRITE = 6             # one 1 KB document, indexed by default\nSQL_VCORES = 2\nMIN_MB_PER_QUERY = 10\n\n", "note": "**And the assumptions about the workload, written down where they can be argued with.** Three request units for a lookup and six for a write are estimates for small documents; on Azure, the request charge that every Cosmos DB answer carries, lesson 13, replaces them with measurements. The 10 MB is the minimum Microsoft documents a serverless SQL pool charging for any query."}, {"code": "def cosmos():\n    ru = LOOKUPS * RU_PER_LOOKUP + WRITES * RU_PER_WRITE\n    return {\"request units\": ru / 1e6 * COSMOS_PER_MILLION_RU, \"storage\": STORED_GB * COSMOS_PER_GB}\n\n", "note": "**Cosmos DB, serverless**: request units by the million, and storage. The orders are partitioned by the customer, so each lookup is a query inside one partition."}, {"code": "def sql_database():\n    return {\"compute\": SQL_VCORES * 730 * SQL_PER_VCORE_HOUR, \"storage\": STORED_GB * SQL_PER_GB}\n\n", "note": "**Azure SQL Database**: two vCores for every hour of the month, used or not, and storage. The lookups are an indexed query each, and the machine is mostly idle."}, {"code": "def synapse_serverless():\n    tb = LOOKUPS * MIN_MB_PER_QUERY / 1e6\n    return {f\"{tb:.0f} TB processed\": tb * SERVERLESS_PER_TB}\n\n", "note": "**Synapse's serverless SQL pool**: charged by data processed, at least 10 MB a query, however little the query reads."}, {"code": "for name, bill in [(\"Cosmos DB, serverless\", cosmos()), (\"Azure SQL Database, 2 vCores\", sql_database()),\n                   (\"Synapse serverless SQL pool\", synapse_serverless())]:\n    lines = \"  \".join(f\"{k} {v:,.2f}\" for k, v in bill.items())\n    print(f\"{name:<30} {sum(bill.values()):>8,.2f} USD   {lines}\")\n", "note": "One line per store: the month's total and what it is made of."}]}
```

```
ana@laptop:~/azure$ python compare.py
Cosmos DB, serverless             15.65 USD   request units 3.15  storage 12.50
Azure SQL Database, 2 vCores     371.00 USD   compute 365.00  storage 6.00
Synapse serverless SQL pool      150.00 USD   30 TB processed 150.00
```

## What the three numbers say

**Cosmos DB is about fifteen dollars, and storage is most of it.** The requests cost 3.15 because each
lookup is one cheap query inside one partition, the pattern the store is built for; the 50 GB cost
12.50. If the estimate of three request units per lookup is wrong by a factor of three, the total
moves by about six dollars, which is why the assumption can be a guess today and a measurement next
month.

**Azure SQL Database is 371, and nearly all of it is the two vCores**, billed every hour whether the
screen is opened or not. The query itself would be fast with an index on the customer and the date;
the price is the machine. That number reads very differently if the orders already live in that
database for the checkout, as the last section put them: then the screen costs almost nothing extra,
because the machine is already paid for. **The cheapest store for a new workload is often the one
already running**, as long as the workload fits its branch.

**Synapse's serverless pool is 150, and it is the wrong shape at any price.** Every lookup pays for at
least 10 MB, so three million lookups pay for 30 TB of reading to return a few kilobytes each, and
each takes seconds to plan and run, which a screen cannot wait for. A lake engine asked to be a
database is slow and, at this volume, not even cheap.

**None of these numbers is Azure's.** Run the price sheet of lesson 1 for real prices, replace the
first block of constants, and run the program again; the ranking changes only if the real prices
differ from these by more than an order of magnitude, which is the useful thing to know about a
comparison before trusting it.
