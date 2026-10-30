---
title: Exporting the costs, and answering who spent what
version: 1
---

**Cost analysis answers the questions somebody thought to ask in the portal; an export answers the
ones nobody has thought of yet.** It is the month's cost data, line by line, written as files into a
storage account on a schedule, where a spreadsheet, a database or a program can read it. A finance
team that allocates costs to cost centres every month does it from the export, not from a chart.

## What an export is

Everything in this part is from Microsoft's documentation, and **not run**: an export is configured
in Cost Management against a real billing scope and writes into a real storage account.

- **What it holds.** Several datasets can be exported. The one for allocation is the cost and usage
  details, offered as actual cost, as amortised cost, or in the **FOCUS** format lesson 14 read, which
  carries both as `BilledCost` and `EffectiveCost` on the same line.
- **Where from.** A subscription, a resource group, a management group, or the billing scopes above
  them: lesson 2's boxes again.
- **How often.** Once; daily, with the month to date; or monthly, with the previous month. A daily
  export **overwrites** the previous day's file by default, so the latest file of the month is the
  month so far, not one more day.
- **In what form.** CSV or Parquet, optionally compressed, and **partitioned**: a large month is split
  into several files, which cannot be switched off. A program that reads only the first file reads
  part of the month.

A month of a small shop is a few hundred lines a day; a company's is millions. The columns lesson 14
described are the ones that allocate: `x_ResourceGroupName` and `ResourceId` say where a cost is, and
**`Tags` carries the resource's tags as one JSON object**, which is how a tag reaches the bill.

## A month to practise on, invented

There is no export in this lab, so the lesson makes one. **The program below writes a month of cost
lines that never happened**: six of the shop's resources, a cost per day for each that is a round
number chosen for the example, and the reservation from lesson 14's arithmetic bought on the first of
the month. It uses nine FOCUS columns out of the many a real export has, so that what follows can be
read by eye. Save it in `~/azure/tags` as `gen_export.py`:

```python
#!/usr/bin/env python3
"""gen_export.py: write an invented month of cost lines in a few FOCUS columns. Not Azure's data."""
import csv
import json

# group, resource, service, cost per day, the resource's own tags
RESOURCES = [
    ('rg-shop-prod-app', 'vm-shop-web-1', 'Virtual Machines', 3.20, {'cost-centre': 'cc-410'}),
    ('rg-shop-prod-app', 'vm-shop-web-2', 'Virtual Machines', 3.20, {}),
    ('rg-shop-prod-app', 'pip-shop-web', 'Virtual Network', 0.12, {}),
    ('rg-shop-prod-data', 'sql-shop-prod', 'SQL Database', 6.00, {'cost-centre': 'cc-420'}),
    ('rg-shop-prod-data', 'stshopassets', 'Storage', 0.85, {}),
    ('rg-shop-hub', 'vpng-shop-hub', 'VPN Gateway', 4.50, {}),
]
# the tags the shop put on its resource groups; rg-shop-hub has none
GROUPS = {'rg-shop-prod-app': {'cost-centre': 'cc-410'}, 'rg-shop-prod-data': {'cost-centre': 'cc-420'}}
COLUMNS = ['ChargePeriodStart', 'ChargeCategory', 'PricingCategory', 'x_ResourceGroupName',
           'ResourceName', 'ServiceName', 'BilledCost', 'EffectiveCost', 'Tags']

with open('shop-2026-10.csv', 'w', newline='') as f:
    out = csv.writer(f)
    out.writerow(COLUMNS)
    # a one-year reservation for vm-shop-web-1, paid up front on the first of the month
    out.writerow(['2026-10-01', 'Purchase', 'Committed', '', 'shop-web-1y', 'Virtual Machines',
                  '1168.00', '0.00', ''])
    for day in range(1, 32):
        for group, name, service, cost, tags in RESOURCES:
            reserved = name == 'vm-shop-web-1'
            out.writerow([f'2026-10-{day:02d}', 'Usage', 'Committed' if reserved else 'Standard',
                          group, name, service, '0.00' if reserved else f'{cost:.2f}', f'{cost:.2f}',
                          json.dumps(tags) if tags else ''])

with open('groups.json', 'w') as f:
    json.dump(GROUPS, f, indent=2)
print(f'wrote {1 + 31 * len(RESOURCES)} lines to shop-2026-10.csv, and groups.json')
```

`RESOURCES` is the shop, one line per resource: its group, its name, its service, its invented cost
per day, and its own tags. Two of the six are tagged, as in most real estates, where the resources
made by the template carry the scheme and the ones made by hand, or by an older script, do not.
`GROUPS` is what this lesson's first section would put on the groups, written to `groups.json`. The
reservation's line has no resource group and no tags: a purchase belongs to the billing account, not
to anything in the tree. Run it and look at the first lines:

```
ana@laptop:~/azure/tags$ python3 gen_export.py
wrote 187 lines to shop-2026-10.csv, and groups.json
ana@laptop:~/azure/tags$ head -4 shop-2026-10.csv
ChargePeriodStart,ChargeCategory,PricingCategory,x_ResourceGroupName,ResourceName,ServiceName,BilledCost,EffectiveCost,Tags
2026-10-01,Purchase,Committed,,shop-web-1y,Virtual Machines,1168.00,0.00,
2026-10-01,Usage,Committed,rg-shop-prod-app,vm-shop-web-1,Virtual Machines,0.00,3.20,"{""cost-centre"": ""cc-410""}"
2026-10-01,Usage,Standard,rg-shop-prod-app,vm-shop-web-2,Virtual Machines,3.20,3.20,
```

The tags are a JSON object inside a CSV field, which is why its quotes are doubled: that is how CSV
writes a quote inside a value. Any CSV reader undoes it.

## Who spent what

Allocating a month is grouping its lines by a tag and adding up one cost column. Save this as
`who_spent.py`:

```schooling-example
{"language": "python", "file": "who_spent.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"who_spent.py FILE [--effective] [--inherit GROUPS]: a month's cost by cost centre.\"\"\"\nimport csv\nimport json\nimport sys\nfrom collections import defaultdict\n\nTAG = 'cost-centre'\ncolumn = 'EffectiveCost' if '--effective' in sys.argv else 'BilledCost'\n", "note": "Which column to add up is the first decision, and lesson 14 explained the two: `BilledCost`, what was charged on the day, or `EffectiveCost`, the same amortised. The program says which one it used under its total, so a number never travels without its definition."}, {"code": "groups = {}\nif '--inherit' in sys.argv:\n    with open(sys.argv[sys.argv.index('--inherit') + 1]) as f:\n        groups = json.load(f)\n", "note": "With `--inherit`, the resource groups' tags are read too, and lent to lines whose resource has none of its own: what Cost Management's tag inheritance does to usage records, done here by hand."}, {"code": "totals = defaultdict(float)\nwith open(sys.argv[1], newline='') as f:\n    for row in csv.DictReader(f):\n        tags = json.loads(row['Tags'] or '{}')\n        group_tags = groups.get(row['x_ResourceGroupName'], {})\n        owner = tags.get(TAG) or group_tags.get(TAG) or '(untagged)'\n        totals[owner] += float(row[column])\n", "note": "The resource's own tag wins, the group's fills in, and a line with neither is counted as **`(untagged)`**, never dropped. A report that leaves out what it cannot attribute adds up to less than the bill, and nobody notices which part is missing."}, {"code": "for owner, cost in sorted(totals.items(), key=lambda kv: -kv[1]):\n    print(f'{owner:<12}{cost:>10.2f}')\nprint(f'{\"total\":<12}{sum(totals.values()):>10.2f}  ({column})')\n", "note": "Largest first, and the total last, which must equal the bill whatever the grouping: allocation moves money between rows and never creates or loses any."}]}
```

Ask it three times: the actual cost, the amortised cost, and the amortised cost with the groups'
tags lent to the resources:

```
ana@laptop:~/azure/tags$ python3 who_spent.py shop-2026-10.csv
(untagged)     1436.77
cc-420          186.00
cc-410            0.00
total          1622.77  (BilledCost)
ana@laptop:~/azure/tags$ python3 who_spent.py shop-2026-10.csv --effective
(untagged)      268.77
cc-420          186.00
cc-410           99.20
total           553.97  (EffectiveCost)
ana@laptop:~/azure/tags$ python3 who_spent.py shop-2026-10.csv --effective --inherit groups.json
cc-420          212.35
cc-410          202.12
(untagged)      139.50
total           553.97  (EffectiveCost)
```

**The first answer is useless, and every number in it is right.** Actual cost puts the whole year's
reservation in October, on a line with no tags, so nearly everything is `(untagged)` and the checkout
team's machine costs nothing, because its usage was covered by a purchase billed to nobody. That is
lesson 14's lesson, met in a report.

**The second is honest about the reservation and still mostly untagged.** Amortised, the machine
under the reservation carries its daily share, so `cc-410` has the month's 99.20, and the total falls
to October's real consumption. The year of the reservation not yet used is not October's cost. But
four of the six resources carry no tag, and their money sits under `(untagged)`.

**The third is the one a finance team can use.** With the groups' tags lent to the resources that
lack their own, the web server, the public IP address and the storage account find their cost
centres, and `(untagged)` shrinks to one resource: the VPN gateway, whose group was never tagged at
all. **What is left untagged after inheritance is a list of groups nobody owns**, and it is the
shortest, most useful list this report can produce. The total stays 553.97 in both amortised
answers: allocation moves money between rows, and never adds or loses any.
