---
title: What keeping every version costs
version: 1
---

**Versioning multiplies the bill by the number of generations kept, and nothing caps that number
unless a rule does.** A name written once a day for a year is 365 generations, each billed in full,
and the listing a person looks at shows one object. Soft delete adds a second multiplier that nobody
switched on: seven more days of every object replaced or deleted.

Quitanda's curated customer table is 50 GiB and rewritten every night. The program below prices a
year of it in Standard, at São Paulo's 0.035 USD a GiB-month, under four arrangements: versioning
with no rule; versioning with a rule that deletes each noncurrent version seven days after it is
replaced; no versioning, with the default soft delete; and no versioning with soft delete turned off.
Save it as `~/gcp/keep.py`:

```schooling-example
{"language": "python", "file": "keep.py", "parts": [{"code": "\"\"\"A table rewritten every night, for a year, under four arrangements.\"\"\"\n\nTABLE_GIB = 50     # the table, rewritten whole every night\nPRICE = 0.035      # Standard, southamerica-east1, USD per GiB-month\nKEEP = 7           # days a noncurrent version lives under the rule\nSOFT = 7           # days a deleted or replaced object stays soft-deleted\n\n\n", "note": "The numbers the answer depends on. The price is São Paulo's Standard from the pricing page, read 2026-10-30; `SOFT` is the soft-delete duration a new bucket gets unless somebody changes it."}, {"code": "def copies(day, arrangement):\n    most = {\n        'versions, no rule': day,\n        'versions, rule': 1 + KEEP + SOFT,\n        'no versions': 1 + SOFT,\n        'no soft delete': 1,\n    }[arrangement]\n    return min(day, most)\n\n\nARRANGEMENTS = ['versions, no rule', 'versions, rule', 'no versions', 'no soft delete']\n\n\n", "note": "**How many copies of the table the bucket is billed for on a given day.** With versioning and no rule, every night's version is still there. With a rule, a version lives seven days after it is replaced and then seven more soft-deleted. With no versioning, each replaced table is soft-deleted for seven days. Only with soft delete off is there one copy."}, {"code": "print(f'{\"month\":>5}' + ''.join(f'{a:>19}' for a in ARRANGEMENTS))\ntotal = dict.fromkeys(ARRANGEMENTS, 0.0)\nfor month in range(1, 13):\n    days = range((month - 1) * 30 + 1, month * 30 + 1)\n    row = f'{month:>5}'\n    for a in ARRANGEMENTS:\n        cost = sum(copies(d, a) for d in days) * TABLE_GIB * PRICE / 30\n        total[a] += cost\n        row += f'{cost:>19,.2f}'\n    print(row)\nprint(f'{\"year\":>5}' + ''.join(f'{total[a]:>19,.2f}' for a in ARRANGEMENTS))\nprint(f'{\"GiB\":>5}' + ''.join(f'{copies(360, a) * TABLE_GIB:>19,}' for a in ARRANGEMENTS))\n", "note": "A month is 30 days, and a day's storage is a thirtieth of a GiB-month. Each line is what the month cost under each arrangement; `year` adds the twelve months up, and `GiB` is what the bucket holds on the year's last day."}]}
```

```
ana@laptop:~/gcp$ python3 keep.py
month  versions, no rule     versions, rule        no versions     no soft delete
    1              27.13              20.13              12.37               1.75
    2              79.62              26.25              14.00               1.75
    3             132.13              26.25              14.00               1.75
    4             184.63              26.25              14.00               1.75
    5             237.13              26.25              14.00               1.75
    6             289.62              26.25              14.00               1.75
    7             342.13              26.25              14.00               1.75
    8             394.63              26.25              14.00               1.75
    9             447.13              26.25              14.00               1.75
   10             499.63              26.25              14.00               1.75
   11             552.12              26.25              14.00               1.75
   12             604.62              26.25              14.00               1.75
 year           3,790.50             308.88             166.37              21.00
  GiB             18,000                750                400                 50
```

**The last month with versioning and no rule costs 604.62, and with the rule 26.25.** At the end of
the year the bucket with no rule holds 360 copies of a 50 GiB table, 18,000 GiB, for a dataset whose
size never moved. The year's total is 3,790.50 against 308.88, more than twelve times as much, spent
on versions that nobody had asked for after their first week.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Stored GiB over a year for a 50 GiB table rewritten nightly. With versioning and no rule the line climbs by 50 GiB a day to 18,000 GiB on day 360. With a seven-day rule it stops at 750 GiB after fifteen days. With no versioning and soft delete on it stops at 400 GiB after eight days.\" data-fig=\"l03-versions\"><path d=\"M90.0 260.0 L690.0 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 30.0 L90.0 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 260.0 L90.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M235.0 260.0 L235.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"235.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90</text><path d=\"M380.0 260.0 L380.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"380.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">180</text><path d=\"M525.0 260.0 L525.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"525.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">270</text><path d=\"M670.0 260.0 L670.0 265.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"670.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">360</text><path d=\"M85.0 260.0 L90.0 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M85.0 186.7 L90.0 186.7\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"186.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6,000</text><path d=\"M85.0 113.3 L90.0 113.3\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"113.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12,000</text><path d=\"M85.0 40.0 L90.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18,000</text><text x=\"20.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">GiB stored</text><text x=\"690.0\" y=\"296.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">day of the year</text><path d=\"M90.0 260.0 L670.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90.0 260.0 L114.2 250.8 L670.0 250.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90.0 260.0 L102.9 255.1 L670.0 255.1\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"666.0\" y=\"42.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">versions, no rule: 18,000 GiB</text><text x=\"670.0\" y=\"232.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">versions and a 7-day rule: 750 GiB</text><text x=\"122.2\" y=\"243.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no versions, soft delete on: 400 GiB</text></svg>", "caption": "The same table and the same nightly write. A rule turns a line with no end into a ceiling; soft delete alone makes a lower one."}
```

**The rule changes the shape, and the size of the table does not matter to the argument.** Without a
rule the stored size grows by one copy of the table every night, for as long as the bucket exists.
With a rule it climbs for fifteen days and then stays flat: the live table, seven noncurrent versions,
and seven more that the rule deleted and soft delete still keeps. A table ten times bigger gives a
bill ten times bigger in every column, and the same ratios between them.

**The third and fourth columns are the cost of soft delete on its own.** With versioning off, each
night's replaced table is still kept for seven days, so the bucket holds eight copies, 400 GiB, and
pays 166.37 a year where one copy would pay 21.00. Nobody chose that: it is the default. For a table
that is rebuilt from its sources every night, the seven days protect something that can be produced
again, and Quitanda turns soft delete off on that bucket with `--clear-soft-delete`. For the raw
bucket, where an export deleted by mistake cannot be produced again, it keeps it on.

The arithmetic counts storage and nothing else, because storage is what grows. Each night's write is
one Class A operation whatever the arrangement, and a deletion by a life-cycle rule is not billed as
an operation at all; the pricing page lists Object Lifecycle Management's `Delete` among the free
ones.

## How many days to keep

**Seven days is a choice about how long a mistake can go unnoticed**, not a number with a right
answer. A noncurrent version is a way back from a bad nightly job, and it is useful only for as long
as somebody would still notice the job was bad. Quitanda's analysts look at the customer table every
morning, so a broken rewrite is seen within a day and seven is generous. A table read once a month
needs a month and a few days. A rule can also keep a fixed number of noncurrent versions instead of a
number of days, with the condition `numNewerVersions`, which suits a name written irregularly: with
`numNewerVersions: 3` a version is deleted once three newer ones exist, however long that took.

**Two protections with the same job are paid twice.** In a versioned bucket with a seven-day rule,
soft delete adds seven more days to each version the rule deletes. That is worth having where a
mistake might be noticed late, and it is waste where the rule's seven days are already the margin.
Choose the total days of protection first, then decide which mechanism gives them.
