---
title: Three ways to pay for one machine
version: 1
---

**The same hour of the same machine has three prices on AWS, and which one you pay is decided by
what you promised, not by the machine.** On demand promises nothing and pays the full rate. A
**Reserved Instance** promises to pay for one instance type in one region, every hour, for one or
three years. A **Savings Plan** promises to spend a number of dollars an hour on computing, every
hour, for one or three years. The common picture of a reservation is a machine kept aside for you
somewhere. It is a discount on the bill. Buying one starts, sets aside or names no machine, and a
running instance that matches it is simply charged less.

## moto has a price list, and it is not AWS's

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. The EC2 API has an operation that lists reservations for sale, and moto answers it:

```
ana@laptop:~/aws$ aws ec2 describe-reserved-instances-offerings --instance-type m7i.large --query 'ReservedInstancesOfferings[:4].[InstanceType,OfferingType,FixedPrice,UsagePrice]' --output text
t2.micro	No Upfront	0.0	0.05
t2.micro	Partial Upfront	215.0	0.05
t2.micro	All Upfront	203.0	0.0
t2.micro	No Upfront	0.0	0.05
ana@laptop:~/aws$ aws savingsplans describe-savings-plans 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the DescribeSavingsPlans operation (reached max retries: 2): <!doctype html>
```

**The question named an `m7i.large` and moto answered about a `t2.micro`**, with upfront prices of
its own invention. moto keeps a few invented offerings so that code which buys reservations has
something to buy. Its Savings Plans API is not there at all. Nothing in this lesson's arithmetic
comes from moto. It comes from two offers of AWS's price list, read by a short program.

## A program that reads every term of one instance

`price.py`, from lesson 1, prints only on-demand prices. The prices of reservations sit in the same
EC2 offer under a second kind of term. The rates of Savings Plans sit in an offer of their own,
`AWSComputeSavingsPlan`, which AWS publishes beside the others. **Save this as `~/aws/terms.py`**:

```schooling-example
{"language": "python", "file": "terms.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Every way to pay for one EC2 instance type, from the AWS public price list.\n\n    python3 terms.py EC2VERSION SPVERSION REGION INSTANCETYPE\n\nEC2VERSION is a version of the AmazonEC2 offer, SPVERSION one of the\nAWSComputeSavingsPlan offer. Linux, shared tenancy, one-year terms. Both files\nare large and are downloaded once into ~/.cache/aws-prices.\n\"\"\"\n", "note": "What the program reads and how to call it. Two offers, each at a version you name, so the same command prints the same prices next year."}, {"code": "import json\nimport os\nimport resource\nimport sys\nimport urllib.request\n\n", "note": "Only Python's own library, like `price.py`. `resource` is there to report how much memory the run needed."}, {"code": "HOST = 'https://pricing.us-east-1.amazonaws.com'\nCACHE = os.path.expanduser('~/.cache/aws-prices')\nHOURS_A_YEAR = 8760\nHOURS_A_MONTH = 730\nORDER = ['No Upfront', 'Partial Upfront', 'All Upfront']\n\n\n", "note": "Where the price list lives and where the downloads are kept, the same cache `price.py` uses. A year of a reservation is 8,760 hours, and AWS bills a month as 730 of them, which is 8,760 divided by twelve."}, {"code": "def fetch(code, version, region, url):\n    os.makedirs(CACHE, exist_ok=True)\n    path = os.path.join(CACHE, f'{code}-{version}-{region}.json')\n    if not os.path.exists(path):\n        urllib.request.urlretrieve(url, path + '.part')\n        os.rename(path + '.part', path)\n    with open(path) as f:\n        doc = json.load(f)\n    print(f'{code} {doc[\"version\"]}, published {doc[\"publicationDate\"][:10]}, USD')\n    return doc\n\n\n", "note": "Downloads one file once, to a `.part` name renamed only when complete, then reads it whole with `json.load` and prints the line that says which version this is and when AWS published it."}, {"code": "def ec2(version, region, itype):\n    url = f'{HOST}/offers/v1.0/aws/AmazonEC2/{version}/{region}/index.json'\n    doc = fetch('AmazonEC2', version, region, url)\n    for sku, p in doc['products'].items():\n        a = p['attributes']\n        if (a.get('instanceType') == itype and a.get('operatingSystem') == 'Linux'\n                and a.get('tenancy') == 'Shared' and a.get('preInstalledSw') == 'NA'\n                and a.get('capacitystatus') == 'Used'\n                and a.get('licenseModel') == 'No License required'):\n            break\n    else:\n        sys.exit(f'{itype}: no Linux, shared tenancy product in this offer')\n", "note": "The EC2 offer holds a product for every combination of instance type, operating system, licence and tenancy. The six tests keep the one plain Linux machine on shared hardware, whose SKU is the code every other price of it hangs from."}, {"code": "    for t in doc['terms']['OnDemand'][sku].values():\n        for d in t['priceDimensions'].values():\n            on_demand = float(d['pricePerUnit']['USD'])\n    rows = []\n    for t in doc['terms']['Reserved'][sku].values():\n        ta = t['termAttributes']\n        if ta['LeaseContractLength'] != '1yr':\n            continue\n        upfront = hourly = 0.0\n        for d in t['priceDimensions'].values():\n            if d['unit'] == 'Quantity':\n                upfront = float(d['pricePerUnit']['USD'])\n            else:\n                hourly = float(d['pricePerUnit']['USD'])\n        rows.append((f'reserved, {ta[\"OfferingClass\"]}', ta['PurchaseOption'], upfront, hourly))\n    return sku, a, on_demand, rows\n\n\n", "note": "The SKU has two kinds of term. `OnDemand` is one price per hour. Each `Reserved` term is a length, a class and a purchase option, and up to two prices: an upfront fee, in the unit `Quantity`, and a price per hour. Only the one-year terms are kept."}, {"code": "def plans(version, region, sku):\n    url = f'{HOST}/savingsPlan/v1.0/aws/AWSComputeSavingsPlan/{version}/{region}/index.json'\n    doc = fetch('AWSComputeSavingsPlan', version, region, url)\n    kind = {p['sku']: p for p in doc['products']}\n    rows = []\n    for term in doc['terms']['savingsPlan']:\n        a = kind[term['sku']]['attributes']\n        if a['purchaseTerm'] != '1yr':\n            continue\n        for rate in term['rates']:\n            if rate['discountedSku'] == sku:\n                name = 'compute' if a['productFamily'] == 'ComputeSavingsPlans' \\\n                    else f'{a[\"instanceType\"]} family'\n                rows.append((f'savings plan, {name}', a['purchaseOption'],\n                             None, float(rate['discountedRate']['price'])))\n    return rows\n\n\n", "note": "The Savings Plans offer is a list of plans and, for each, the rate it charges for every SKU it covers. The rate for this instance is the one whose `discountedSku` is the SKU found above, so the two files join by that code and nothing else."}, {"code": "def main():\n    ec2_version, sp_version, region, itype = sys.argv[1:]\n    sku, a, on_demand, rows = ec2(ec2_version, region, itype)\n    rows += plans(sp_version, region, sku)\n    rows.sort(key=lambda r: (r[0], ORDER.index(r[1])))\n    print(f'{itype}, {a[\"vcpu\"]} vCPU, {a[\"memory\"]}, Linux, shared tenancy, {region}')\n    print(f'{\"\":<47}{\"upfront\":>8}{\"hourly\":>9}{\"effective\":>10}{\"a month\":>9}{\"break-even\":>11}')\n    print(f'{\"on demand\":<47}{\"-\":>8}{on_demand:>9.5f}{on_demand:>10.5f}'\n          f'{on_demand * HOURS_A_MONTH:>9.2f}{HOURS_A_MONTH:>9} h')\n    for kind, option, upfront, hourly in rows:\n        if upfront is None:\n            effective, upfront_s, hourly_s = hourly, '-', '-'\n        else:\n            effective = upfront / HOURS_A_YEAR + hourly\n            upfront_s, hourly_s = f'{upfront:,.0f}', f'{hourly:.5f}'\n        hours = effective / on_demand * HOURS_A_MONTH\n        print(f'{kind + \", 1yr, \" + option:<47}{upfront_s:>8}{hourly_s:>9}{effective:>10.5f}'\n              f'{effective * HOURS_A_MONTH:>9.2f}{hours:>9.0f} h')\n", "note": "The table. A reservation's effective rate is its upfront fee spread over the 8,760 hours of the year, plus its hourly price. A Savings Plan's rate is already effective. A month at that rate, and the break-even: how many hours a month the machine must run on demand before paying for the commitment is cheaper."}, {"code": "    peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024\n    print(f'peak memory {peak:,} MB')\n\n\nmain()\n", "note": "The last line, the most memory the run held at once, read from the operating system."}]}
```

The versions are the EC2 offer the `cloud` course pinned, published on 25 September 2026, and the
Savings Plans offer AWS published the same day. The machine is an `m7i.large`, two processors and
8 GiB, Linux on shared hardware, in São Paulo:

```
ana@laptop:~/aws$ python3 terms.py 20260925174521 20260925170412 sa-east-1 m7i.large
AmazonEC2 20260925174521, published 2026-09-25, USD
AWSComputeSavingsPlan 20260925170412, published 2026-09-25, USD
m7i.large, 2 vCPU, 8 GiB, Linux, shared tenancy, sa-east-1
                                                upfront   hourly effective  a month break-even
on demand                                             -  0.16065   0.16065   117.27      730 h
reserved, convertible, 1yr, No Upfront                0  0.10915   0.10915    79.68      496 h
reserved, convertible, 1yr, Partial Upfront         455  0.05198   0.10392    75.86      472 h
reserved, convertible, 1yr, All Upfront             892  0.00000   0.10183    74.33      463 h
reserved, standard, 1yr, No Upfront                   0  0.09956   0.09956    72.68      452 h
reserved, standard, 1yr, Partial Upfront            415  0.04741   0.09478    69.19      431 h
reserved, standard, 1yr, All Upfront                814  0.00000   0.09292    67.83      422 h
savings plan, compute, 1yr, No Upfront                -        -   0.10915    79.68      496 h
savings plan, compute, 1yr, Partial Upfront           -        -   0.10395    75.88      472 h
savings plan, compute, 1yr, All Upfront               -        -   0.10187    74.37      463 h
savings plan, m7i family, 1yr, No Upfront             -        -   0.09956    72.68      452 h
savings plan, m7i family, 1yr, Partial Upfront        -        -   0.09482    69.22      431 h
savings plan, m7i family, 1yr, All Upfront            -        -   0.09292    67.83      422 h
peak memory 936 MB
ana@laptop:~/aws$ ls -sh ~/.cache/aws-prices | grep -e AmazonEC2 -e SavingsPlan
230M AWSComputeSavingsPlan-20260925170412-sa-east-1.json
279M AmazonEC2-20260925174521-sa-east-1.json
```

**The first run downloads two large files, and every run reads both whole.** The listing shows them
in the cache: 279 MB of EC2 offer and 230 MB of Savings Plans rates. The EC2 one is large because it
prices every instance type in every combination of system, licence and tenancy. Reading one with
`json.load` holds it in memory as a Python dictionary. The program reads them one after the other,
so the peak it reports, 936 MB in the run above, is the larger of the two rather than their sum. A
computer with 2 GB of memory free runs it comfortably.

## Reading the table

Every price is in dollars, before tax, from the lists of **25 September 2026**. The rows that
matter for a decision:

| how it is paid | effective per hour | a month of 730 hours | against on demand |
|---|---|---|---|
| on demand | 0.16065 | 117.27 | |
| Reserved Instance, standard, 1 year, no upfront | 0.09956 | 72.68 | 38% less |
| Reserved Instance, standard, 1 year, all upfront (814) | 0.09292 | 67.83 | 42% less |
| Compute Savings Plan, 1 year, no upfront | 0.10915 | 79.68 | 32% less |
| EC2 Instance Savings Plan, m7i, 1 year, no upfront | 0.09956 | 72.68 | 38% less |

**The effective rate is what makes the rows comparable.** A partial-upfront reservation charges 415
dollars on the day of purchase and 0.04741 an hour after that. Spread over the 8,760 hours of the
year, the 415 is 0.04737 an hour, and the two together are 0.09478. Paying more upfront lowers the
effective rate a little, here from 0.09956 to 0.09292. The price is money paid a year early that you
cannot recover.

**Two pairs of numbers are the same**, and the coincidence is AWS's design rather than a bug in the
program. The EC2 Instance Savings Plan for the `m7i` family charges exactly the standard
reservation's rate, 0.09956. The Compute Savings Plan charges exactly the convertible reservation's,
0.10915. A plan that is as narrow as a reservation is priced like one, and a plan that is as
flexible as the most flexible reservation is priced like that. What each one is flexible about is
the next section.

A **month is 730 hours** on every line, a twelfth of 8,760, which is the month AWS's own pricing
calculator uses. A real month of 31 days is 744 hours of running, and the bill counts the hours that
happened. The `a month` column is the effective rate times 730. Those monthly figures assume the
machine runs all month. The commitment is paid whether it does or not, which is what the last column
of the program is about.
