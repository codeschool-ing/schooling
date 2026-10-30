---
title: The price sheet, whole
version: 1
---

Nothing in this lab charges, so nothing in it can tell you what anything costs. **Every price in
this course is a number from Google's public price pages instead**, collected in the program
below, with the day it was read and the region it applies to.

## Why it is a program and not a download

AWS publishes its price list as files anybody can fetch. Google does not, quite. It has a
machine-readable catalogue, the Cloud Billing Catalog API, but calling it needs an API key, and an
API key needs an account. The pages anybody can read are web pages that draw their tables in the
browser. So the numbers below were read off those pages on **30 October 2026** and typed into a
program, and each block of the program names the page it came from.

They are **Iowa's prices**, `us-central1`, because that is the region every page shows until you
choose another, and the one a reader can check without choosing anything. Prices differ from
region to region, and São Paulo, where the lab places everything, has its own. The lessons only
ever compare prices with each other, all from one region and one day, which is what a comparison
needs. For a real budget, open the page, pick your own region and read today's number.

## The program

**Copy it with the button on the block and save it as `~/gcp/prices.py`.** Any editor does; in the
terminal, `nano prices.py` opens one, the terminal's own paste puts the program in, and Ctrl+O,
Enter and Ctrl+X save it and leave. The notes beside the code are not copied.

```schooling-example
{"language": "python", "file": "prices.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The price sheet every number in the gcp-compute course comes from.\n\nGoogle publishes its prices as web pages rather than as a file a program can\ndownload without an account. These are the numbers those pages showed on\n30 October 2026: Iowa (us-central1), the region every page shows before you\nchoose one, on demand, in US dollars before tax.\n\n    python3 prices.py                 # the whole sheet\n    python3 prices.py vm disks        # some blocks of it\n    python3 prices.py custom n4 4 10  # a custom machine: series, vCPUs, GiB\n\"\"\"\n", "note": "The docstring says where the numbers came from, on which day and for which region, and how to run the program. It travels with the file, so the sheet carries its own provenance."}, {"code": "import sys\n\nMONTH = 730  # hours: the month Google's own monthly figures use\n\n", "note": "One module from Python's standard library, and the month: Google's monthly figures are 730 hours, the average month of a 365-day year."}, {"code": "# cloud.google.com/products/compute/pricing/general-purpose and /spot-vms/pricing\n# name: (vCPUs, GiB of memory, on demand per hour, Spot per hour or None)\nVM = {\n    'e2-micro':       (2, 1, 0.008376428, None),\n    'e2-small':       (2, 2, 0.016752855, None),\n    'e2-medium':      (2, 4, 0.03350571, None),\n    'e2-standard-2':  (2, 8, 0.06701142, 0.040212),\n    'e2-standard-4':  (4, 16, 0.13402284, None),\n    'e2-highcpu-2':   (2, 2, 0.04947024, None),\n    'e2-highmem-2':   (2, 16, 0.09039966, None),\n    'n4-standard-2':  (2, 8, 0.0907, 0.053652),\n    'n4-standard-4':  (4, 16, 0.1814, None),\n    'n4-highcpu-2':   (2, 4, 0.07654, None),\n    'n4-highmem-2':   (2, 16, 0.11902, None),\n    'n2-standard-2':  (2, 8, 0.097118, 0.058256),\n    'n2d-standard-2': (2, 8, 0.084492, None),\n    'c4-standard-2':  (2, 7, 0.096866, 0.057979),\n    'c4a-standard-2': (2, 8, 0.0898, 0.044388),\n    'g2-standard-4':  (4, 16, 0.706832276, None),\n}\n\n", "note": "The machine types the course compares, each with its vCPUs, its memory, its on-demand price per hour and, where the Spot page lists it, its Spot price. Lesson 6 is about that last column."}, {"code": "# per vCPU-hour and per GiB-hour, the same page's custom tables\nCUSTOM = {\n    'e2': (0.02290217, 0.003069707),\n    'n4': (0.03275, 0.003717),\n    'n2': (0.03319155, 0.00444885),\n}\n\n", "note": "Custom machine types are priced per vCPU and per GiB rather than per name. These three rates are the ones lesson 1's `custom` command multiplies."}, {"code": "# cloud.google.com/compute/disks-image-pricing, per GiB-hour unless marked\nDISKS = [\n    ('pd-standard, after the free 30 GiB', 0.000054795),\n    ('pd-balanced', 0.000136986),\n    ('pd-ssd', 0.000232877),\n    ('pd-balanced, regional', 0.000273973),\n    ('hyperdisk-balanced', 0.000109589),\n    ('local SSD', 0.000109589),\n    ('standard snapshot', 0.000068493),\n    ('archive snapshot', 0.000026027),\n    ('custom image', 0.000068493),\n]\n\n", "note": "Disks and images, which Google prices per GiB per hour. Lesson 3 is about the disks and lesson 2 about the images; the program multiplies by 730 to give the month."}, {"code": "def shown(value):\n    return f'{value:.10f}'.rstrip('0').rstrip('.')\n\ndef line(label, value, unit):\n    print(f'  {label:<44}{shown(value):>14}  {unit}')\n\ndef head(title):\n    print()\n    print(title)\n\n", "note": "Printing. `shown` writes a number without the trailing zeros, so a price is printed as the page printed it."}, {"code": "def vm():\n    head('Compute Engine, on demand')\n    print(f'  {\"\":<28}{\"per hour\":>14}{\"per month\":>12}{\"Spot/hour\":>12}')\n    for name, (cpu, mem, hour, spot) in VM.items():\n        off = f'{spot:>12}' if spot else f'{\"-\":>12}'\n        print(f'  {name:<15}{cpu:>2} vCPU{mem:>4} GiB{shown(hour):>14}{hour * MONTH:>12.2f}{off}')\n\n", "note": "The first block: every machine type in one table, with the month worked out beside the hour."}, {"code": "def custom(series='n4', cpus='4', gib='10'):\n    cpu_rate, mem_rate = CUSTOM[series]\n    cpus, gib = int(cpus), float(gib)\n    head(f'{series}-custom-{cpus}-{int(gib * 1024)}: {cpus} vCPU and {gib:g} GiB')\n    line(f'{cpus} x {cpu_rate} per vCPU', cpus * cpu_rate, 'per hour')\n    line(f'{gib:g} x {mem_rate} per GiB', gib * mem_rate, 'per hour')\n    total = cpus * cpu_rate + gib * mem_rate\n    line('together', total, 'per hour')\n    line('together, for 730 hours', round(total * MONTH, 2), 'per month')\n\n", "note": "A custom machine type priced from its parts. It takes the series, the vCPUs and the memory in GiB, and adds the two products."}, {"code": "def disks():\n    head('Disks and images, per GiB per month')\n    for name, hour in DISKS:\n        line(name, round(hour * MONTH, 4), 'per GiB-month')\n\n", "note": "Disks and images, per GiB per month."}, {"code": "def serverless():\n    head('Cloud Run, request-based billing (cloud.google.com/run/pricing)')\n    line('vCPU, while a request is being served', 0.000024, 'per vCPU-second')\n    line('memory, while a request is being served', 0.0000025, 'per GiB-second')\n    line('vCPU, an idle minimum instance', 0.0000025, 'per vCPU-second')\n    line('requests', 0.40, 'per million')\n    line('free each month: vCPU', 180000, 'vCPU-seconds')\n    line('free each month: memory', 360000, 'GiB-seconds')\n    line('free each month: requests', 2000000, 'requests')\n    head('Cloud Run, instance-based billing, and jobs')\n    line('vCPU, for the whole life of the instance', 0.000018, 'per vCPU-second')\n    line('memory, for the whole life of the instance', 0.000002, 'per GiB-second')\n    head('GKE (cloud.google.com/kubernetes-engine/pricing)')\n    line('cluster management fee', 0.10, 'per cluster-hour')\n    line('free credit each month, per billing account', 74.40, 'dollars')\n    line('Autopilot pod vCPU', 0.0445, 'per vCPU-hour')\n    line('Autopilot pod memory', 0.0049225, 'per GiB-hour')\n\n", "note": "The serverless and container prices, with the monthly free allowances: Cloud Run's two billing modes for lessons 8 to 11, and GKE's fee and Autopilot's rates for lessons 13 and 14."}, {"code": "def other():\n    head('Around the compute')\n    line('Artifact Registry, after the free 0.5 GiB', round(0.000136986 * MONTH, 4), 'per GiB-month')\n    line('Cloud Tasks, after the free million', 0.40, 'per million operations')\n    line('Cloud Scheduler, after 3 free jobs', 0.10, 'per job per 31 days')\n    line('App Engine standard F1, after 28 free hours', 0.05, 'per instance-hour')\n    line('App Engine standard B1, after 9 free hours', 0.05, 'per instance-hour')\n    line('App Engine flexible vCPU', 0.0526, 'per vCPU-hour')\n    line('App Engine flexible memory', 0.0071, 'per GiB-hour')\n    line('internet egress to North America, Premium', 0.12, 'per GiB')\n\n", "note": "Everything around the compute that later lessons price: Artifact Registry, Cloud Tasks, Cloud Scheduler, App Engine and the egress that lesson 23 needs."}, {"code": "BLOCKS = {'vm': vm, 'disks': disks, 'serverless': serverless, 'other': other}\n\ndef main():\n    args = sys.argv[1:]\n    print('Google Cloud public prices, us-central1, USD, 30 October 2026')\n    if args[:1] == ['custom']:\n        custom(*args[1:])\n        return\n    for name in args or list(BLOCKS):\n        BLOCKS[name]()\n\nif __name__ == '__main__':\n    main()\n", "note": "The command line. With no argument, every block; with names, those blocks in that order; with `custom`, one custom machine type."}]}
```

## Running it

The `vm` block is the one this lesson reads:

```
ana@laptop:~/gcp$ python3 prices.py vm
Google Cloud public prices, us-central1, USD, 30 October 2026

Compute Engine, on demand
                                    per hour   per month   Spot/hour
  e2-micro        2 vCPU   1 GiB   0.008376428        6.11           -
  e2-small        2 vCPU   2 GiB   0.016752855       12.23           -
  e2-medium       2 vCPU   4 GiB    0.03350571       24.46           -
  e2-standard-2   2 vCPU   8 GiB    0.06701142       48.92    0.040212
  e2-standard-4   4 vCPU  16 GiB    0.13402284       97.84           -
  e2-highcpu-2    2 vCPU   2 GiB    0.04947024       36.11           -
  e2-highmem-2    2 vCPU  16 GiB    0.09039966       65.99           -
  n4-standard-2   2 vCPU   8 GiB        0.0907       66.21    0.053652
  n4-standard-4   4 vCPU  16 GiB        0.1814      132.42           -
  n4-highcpu-2    2 vCPU   4 GiB       0.07654       55.87           -
  n4-highmem-2    2 vCPU  16 GiB       0.11902       86.88           -
  n2-standard-2   2 vCPU   8 GiB      0.097118       70.90    0.058256
  n2d-standard-2  2 vCPU   8 GiB      0.084492       61.68           -
  c4-standard-2   2 vCPU   7 GiB      0.096866       70.71    0.057979
  c4a-standard-2  2 vCPU   8 GiB        0.0898       65.55    0.044388
  g2-standard-4   4 vCPU  16 GiB   0.706832276      515.99           -
```

The month is the hour times 730, rounded to the cent, and it is the number to keep in your head:
**an `e2-standard-2` running all month is about 49 dollars**, and the cheapest machine that
carries a GPU in this table is ten times that. The Spot column is lesson 6's subject; it is filled
in only for the types the Spot page lists.

A custom machine type is priced from its parts, which section 06 explains. The program takes the
series, the vCPUs and the memory in GiB:

```
ana@laptop:~/gcp$ python3 prices.py custom n4 4 10
Google Cloud public prices, us-central1, USD, 30 October 2026

n4-custom-4-10240: 4 vCPU and 10 GiB
  4 x 0.03275 per vCPU                                 0.131  per hour
  10 x 0.003717 per GiB                              0.03717  per hour
  together                                           0.16817  per hour
  together, for 730 hours                             122.76  per month
```

The sheet is not a bill. It knows nothing about the discounts lesson 22 weighs, the free tier, the
taxes in your country, or what anybody actually paid. It is the list price, which is the number
every other calculation starts from.
