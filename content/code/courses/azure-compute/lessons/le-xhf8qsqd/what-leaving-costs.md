---
title: What leaving would cost, estimated before you arrive
version: 1
---

"How locked in are we?" has no answer. **"What would leaving cost, in person-days and in money?"
has one**, and it can be estimated on the first day, when it is cheapest to change. The estimate has four lines, and each comes from something you can count.
They are the components that would be rewritten, the data that would be carried out, the people who would have to learn another
platform, and the months of running both while the move happens.

**Every figure in this section's example is invented**: the person-days, the gigabytes, the rate
per gigabyte and the monthly bill. They are there to make the arithmetic concrete, and none of
them is Azure's price or anybody's measurement. The method is the part to keep.

## The rewrite, component by component

Start with the code and the files around it. The question is not how big the system is but how
much of it touches Azure, and the honest unit is one component at a time. For the shop after lesson 21's decision, the list starts with the image, the Container App and its
two jobs, and the Service Bus queue for the finance export. Then come the identity that connects them, the database and the file share,
the Bicep that declares it all, and what the team watches it with.

A short program holds that list, scores each line in person-days, and adds them up by kind of
lock-in. It uses nothing outside Python's standard library. Save it as `~/azure/exitcost.py`; the
copy button takes the whole file without the notes:

```schooling-example
{"language": "python", "file": "exitcost.py", "parts": [{"code": "# exitcost.py\n\"\"\"What leaving Azure would cost the shop. Every figure here is invented.\"\"\"\n\nDEPENDENCIES = [\n    # component, kind of lock-in, person-days to replace it elsewhere\n    ('shop:1.0, the image', 'API', 0),\n    ('Container Apps: the app and two jobs', 'API', 3),\n    ('Service Bus queue for the export', 'API', 2),\n    ('managed identity and role assignments', 'identity', 3),\n    ('orders database and report share', 'data', 2),\n    ('Bicep files', 'operations', 4),\n    ('Azure Monitor queries and alerts', 'operations', 3),\n    ('three developers on a new platform', 'operations', 12),\n    ('reservations and savings plans', 'contract', 0),\n]\n", "note": "The shop's dependencies after lesson 21's decision, one row each: what it is, which kind of lock-in from section 02 it carries, and the person-days to replace it on another platform. **Every number here is invented.** The image scores zero because section 03 ran it unchanged three ways, and the contract zero because the shop signed nothing."}, {"code": "GB = 300               # orders and report files to carry out\nUSD_PER_GB = 0.10      # illustrative, not Azure's price\nMONTHS_BOTH = 2        # both platforms running during the move\nUSD_PER_MONTH = 150    # illustrative: the shop's Azure bill today\n\n", "note": "The two lines that are money rather than effort: the gigabytes to carry out, and the months during which both platforms run. The rates are round on purpose, so that nobody mistakes them for Azure's."}, {"code": "width = max(len(name) for name, _, _ in DEPENDENCIES)\nprint(f\"{'component':<{width}}  {'kind':<10}  days\")\nfor name, kind, days in sorted(DEPENDENCIES, key=lambda d: d[2], reverse=True):\n    print(f'{name:<{width}}  {kind:<10}  {days:>4}')\n\n", "note": "The table, largest first. `sorted` with `reverse=True` keeps rows of equal days in the order they were written, so the output is the same on every run."}, {"code": "totals = {}\nfor _, kind, days in DEPENDENCIES:\n    totals[kind] = totals.get(kind, 0) + days\neverything = sum(totals.values())\nprint()\nfor kind, days in sorted(totals.items(), key=lambda t: t[1], reverse=True):\n    print(f'{kind:<10}  {days:>4} person-days  {100 * days / everything:3.0f}%')\nprint(f\"{'total':<10}  {everything:>4} person-days\")\n\n", "note": "The score by kind: each kind's person-days and its share of the total. The share is what the next section's decision record reads, because it says which kind of lock-in a seam would be worth buying for."}, {"code": "print()\nprint(f'data out   {GB} GB x {USD_PER_GB:.2f} USD = {GB * USD_PER_GB:.2f} USD')\nprint(f'both run   {MONTHS_BOTH} months x {USD_PER_MONTH} USD = {MONTHS_BOTH * USD_PER_MONTH:.2f} USD')\n", "note": "The money, printed apart from the days so that nobody adds money to person-days."}], "output": "component                              kind        days\nthree developers on a new platform     operations    12\nBicep files                            operations     4\nContainer Apps: the app and two jobs   API            3\nmanaged identity and role assignments  identity       3\nAzure Monitor queries and alerts       operations     3\nService Bus queue for the export       API            2\norders database and report share       data           2\nshop:1.0, the image                    API            0\nreservations and savings plans         contract       0\n\noperations    19 person-days   66%\nAPI            5 person-days   17%\nidentity       3 person-days   10%\ndata           2 person-days    7%\ncontract       0 person-days    0%\ntotal         29 person-days\n\ndata out   300 GB x 0.10 USD = 30.00 USD\nboth run   2 months x 150 USD = 300.00 USD\n"}
```

Run it with `python3 exitcost.py`. The output is the estimate's first half, the effort, followed by
the money.

Each row is a guess somebody can argue with, which is the point of writing it down: a number in a
file can be corrected, and a feeling in a meeting cannot.

Read the top of the table first. **The largest line is people, not code**: twelve person-days for
three developers to learn another platform's containers, identity and monitoring, against three
for the Container App and two for the queue. That is common for a small team, and it is the
operations kind of section 02 showing up as a number. Bicep is next, because every resource the
shop has is declared in a language that only Azure reads, and the four days are the rewrite into
whatever the next platform reads.

Then read the bottom. **The image costs nothing to move**, because section 03 showed it running
unchanged under Docker, Dapr and Kubernetes: no rewrite is the whole value of a seam that was
already paid for. And the contract line is zero because the shop signed nothing. A three-year
savings plan would add no person-days and could add a great deal of money, which is why it is a
row of its own.

On a real system the rewrite list comes from a search, not from memory: every file that imports
an `azure` library, every function decorated with a trigger or a binding, every workflow
definition, every Bicep module, every role assignment. A system where that search returns four
files has a small rewrite line; one where it returns two hundred has a large one, whatever the
architecture diagram says.

## Data, and the price of carrying it out

Data is the lock-in that grows by itself. Every month the shop stores more orders and more report
files, and every gigabyte is one more to carry out. Azure bills data that leaves it for the
internet by the gigabyte. The program uses one round rate, 0.10 USD per GB, which is
**illustrative and not Azure's**. The real one is in the pricing calculator, under bandwidth, or in
the Retail Prices API that lessons 1 and 21 showed, filtered on the bandwidth meters of
`brazilsouth`; this course quotes no number from either. At the example's rate, 300 GB is 30.00
USD, the line the program printed.

For the shop the money is small and the time is not: a database cannot be copied once and
switched over on a Friday afternoon. It is copied, kept in step while both run, and cut over,
which is the next line. If Microsoft offers any relief on transfer for a customer leaving Azure,
it is something to ask about when the day comes; keep the full rate in the estimate, because it
is the figure that holds without anybody's approval.

## People and overlap

The last two lines are where most of the cost hides:

- **retraining** is people times days, and it is already in the table as its largest row. It
  belongs in the estimate even when nobody is paid extra, because the weeks spent learning are
  weeks not spent on the shop;
- **parallel running** is months times the old bill. During the move both platforms run, and
  Azure costs what it cost before. The example puts the shop's bill at an illustrative 150 USD a
  month for two months, 300.00 USD, as the program printed. Lesson 21 is where the real monthly
  figure comes from, once its rates are real.

## The estimate, written down

Put together, with every figure the example's:

| line | how it is counted | the shop, as an example |
| --- | --- | --- |
| rewrite | person-days per component touching Azure | 17 person-days, 3 of them identity |
| data | GB to carry out × price per GB | 300 GB × 0.10 = 30.00 USD |
| retraining | people × days to learn | 3 people × 4 days = 12 person-days |
| overlap | months × the old monthly bill | 2 months × 150 USD = 300.00 USD |

**The total is not the point; the biggest line is.** For the shop it is the people, then the
Bicep, and the money is small beside both. That says where a seam would pay for itself and where
it would not: no adapter makes three people know a new platform, but keeping the image free of
Azure made its line zero. The next section writes all of it into a file the shop keeps.
