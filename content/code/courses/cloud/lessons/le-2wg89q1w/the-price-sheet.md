---
title: The price sheet, whole
version: 1
---

The program that prints every price in this course is below, all of it. **Copy it with the button
on the block and save it as `~/cloud/prices.py`.** Any editor does; in the terminal, `nano
prices.py` opens one, the terminal's own paste puts the program in, and Ctrl+O, Enter and Ctrl+X
save it and leave. The notes beside the code are not copied.

```schooling-example
{"language": "python", "file": "prices.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The price sheet every number in the cloud course comes from.\n\nAWS publishes its whole price list as JSON, with no account and no key:\nhttps://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json names one\n\"offer\" per service, and each offer keeps every version it ever published. This\nscript reads ONE PINNED VERSION of each offer, for two regions, and prints the\nprices the course quotes. Pinned, so that running it next year prints the same\nsheet: the prices move, the files they were read from do not.\n\n    python3 prices.py            # the whole sheet\n    python3 prices.py lambda     # one block of it\n\nNothing here needs credentials, and nothing here is a bill. It is a reading of a\npublished list, taken on the date in each offer's `publicationDate`, and the\ncourse says so wherever it quotes a line. The EC2 files are large (about 290 MB\nfor sa-east-1 and 480 MB for us-east-1), so they are downloaded once into\n~/.cache/cloud-prices and read from there afterwards.\n\nStandard library only: urllib and json.\n\"\"\"\n", "note": "The docstring says what the program reads and how to run it. It is the program's own manual, so it travels with the file."}, {"code": "import json\nimport os\nimport sys\nimport urllib.request\n\n", "note": "Four modules from Python's standard library: nothing to install, which is why the sheet runs on any machine with Python 3."}, {"code": "BASE = 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws'\nCACHE = os.path.expanduser('~/.cache/cloud-prices')\nREGIONS = ['sa-east-1', 'us-east-1']\n# How each region spells a usage type. us-east-1 is the oldest region and most of\n# its usage types carry no prefix at all; a few newer services give it one.\nPREFIX = {'sa-east-1': ['SAE1-'], 'us-east-1': ['', 'USE1-']}\nVERSION = {\n    'AmazonEC2': '20260925174521',\n    'AWSLambda': '20260919002359',\n    'AmazonS3': '20260926015512',\n    'AWSDataTransfer': '20260916132208',\n    'AmazonEFS': '20260911124425',\n    'AmazonVPC': '20260917190528',\n}\n\n\n", "note": "Where the list lives, where the downloads are kept, and the two regions the sheet compares. `VERSION` pins one published version of each offer, and it is the reason the sheet prints the same numbers next year."}, {"code": "def offer(code, region):\n    os.makedirs(CACHE, exist_ok=True)\n    path = os.path.join(CACHE, f'{code}-{VERSION[code]}-{region}.json')\n    if not os.path.exists(path):\n        url = f'{BASE}/{code}/{VERSION[code]}/{region}/index.json'\n        urllib.request.urlretrieve(url, path + '.part')\n        os.rename(path + '.part', path)\n    with open(path) as f:\n        return json.load(f)\n\n\n", "note": "One offer for one region, as a Python dictionary. The first call downloads the file into the cache, under a name that carries the version; every later call reads the copy. The download goes to a `.part` file that is renamed only when it is complete, so a cut connection never leaves a half file that looks finished."}, {"code": "def dims(doc, sku, term='OnDemand'):\n    for t in doc['terms'].get(term, {}).get(sku, {}).values():\n        for d in t['priceDimensions'].values():\n            yield t.get('termAttributes', {}), d\n\n\n", "note": "Every price in an offer is a price dimension inside a term, and a term belongs to a SKU, the code for one product. This walks the terms of one SKU and hands back each dimension with the term's own attributes."}, {"code": "def by_usage(doc, region, usage, first=True):\n    \"\"\"The price of a usage type, in its first tier unless first is False.\"\"\"\n    want = {prefix + usage for prefix in PREFIX[region]}\n    found = []\n    for sku, p in doc['products'].items():\n        if p['attributes'].get('usagetype') in want:\n            for _, d in dims(doc, sku):\n                found.append((float(d['beginRange']), float(d['pricePerUnit']['USD'])))\n    if not found:\n        return None\n    found.sort()\n    return found[0][1] if first else found\n\n\n", "note": "The price of a usage type, such as a gigabyte stored. The region prefix is added here, because each region spells its usage types differently. A price with tiers comes back as its first tier, or as the whole list of tiers when `first` is false."}, {"code": "def instance(doc, name, reserved=False):\n    for sku, p in doc['products'].items():\n        a = p['attributes']\n        if (a.get('instanceType') == name and a.get('operatingSystem') == 'Linux'\n                and a.get('tenancy') == 'Shared' and a.get('preInstalledSw') == 'NA'\n                and a.get('capacitystatus') == 'Used'\n                and a.get('licenseModel') == 'No License required'):\n            if not reserved:\n                for _, d in dims(doc, sku):\n                    return a, float(d['pricePerUnit']['USD'])\n            for ta, d in dims(doc, sku, 'Reserved'):\n                if (ta.get('LeaseContractLength') == '1yr' and ta.get('PurchaseOption') == 'No Upfront'\n                        and ta.get('OfferingClass') == 'standard'):\n                    return a, float(d['pricePerUnit']['USD'])\n    return None, None\n\n\n", "note": "One instance type's hourly price, on demand or reserved for a year. The six attribute tests pick the plain Linux machine out of the many SKUs that share the type's name: other operating systems, dedicated hardware, preinstalled software."}, {"code": "def row(label, values, fmt='{:.4f}'):\n    cells = ''.join(f'{(fmt.format(v) if v is not None else \"-\"):>13}' for v in values)\n    print(f'  {label:<34}{cells}')\n\n\ndef head(title):\n    print()\n    print(title)\n\n\n", "note": "Printing. `row` lines up one label and a value per region; a missing price prints as a dash, never as zero."}, {"code": "INSTANCES = ['t3.micro', 't4g.small', 't3.medium', 'm7i.large', 'm7g.large', 'c7i.large', 'm7i.xlarge']\n\n\ndef ec2():\n    docs = {r: offer('AmazonEC2', r) for r in REGIONS}\n    head('EC2, Linux, on demand, USD per hour')\n    for name in INSTANCES:\n        a, _ = instance(docs[REGIONS[0]], name)\n        label = f'{name:<11}{a[\"vcpu\"]:>2} vCPU {a[\"memory\"]:>7}'\n        row(label, [instance(docs[r], name)[1] for r in REGIONS], '{:.5f}')\n    head('EC2, Linux, 1-year reserved, no upfront, USD per hour')\n    for name in INSTANCES:\n        row(name, [instance(docs[r], name, reserved=True)[1] for r in REGIONS], '{:.5f}')\n    head('EBS, USD per GB-month')\n    for usage, label in [('EBS:VolumeUsage.gp3', 'gp3 SSD volume'),\n                         ('EBS:VolumeUsage.st1', 'st1 HDD volume'),\n                         ('EBS:SnapshotUsage', 'snapshot')]:\n        row(label, [by_usage(docs[r], r, usage) for r in REGIONS])\n    head('Networking, USD')\n    for usage, label in [('NatGateway-Hours', 'NAT gateway, per hour'),\n                         ('NatGateway-Bytes', 'NAT gateway, per GB processed'),\n                         ('LoadBalancerUsage', 'load balancer (ALB), per hour')]:\n        row(label, [by_usage(docs[r], r, usage) for r in REGIONS])\n    vpc = {r: offer('AmazonVPC', r) for r in REGIONS}\n    row('public IPv4 address, per hour',\n        [by_usage(vpc[r], r, 'PublicIPv4:InUseAddress') for r in REGIONS])\n\n\n", "note": "The seven instance types the lessons quote, and the first block of the sheet: their prices, their reserved prices, the disks and the network charges that sit in the EC2 offer. This is the block that needs the two large files."}, {"code": "def storage():\n    s3 = {r: offer('AmazonS3', r) for r in REGIONS}\n    head('S3, USD per GB-month (first tier)')\n    for usage, label in [('TimedStorage-ByteHrs', 'Standard'),\n                         ('TimedStorage-SIA-ByteHrs', 'Standard-Infrequent Access'),\n                         ('TimedStorage-GIR-ByteHrs', 'Glacier Instant Retrieval'),\n                         ('TimedStorage-GlacierByteHrs', 'Glacier Flexible Retrieval')]:\n        row(label, [by_usage(s3[r], r, usage) for r in REGIONS], '{:.5f}')\n    head('S3 requests, USD per 1,000')\n    for usage, label in [('Requests-Tier1', 'PUT, COPY, POST, LIST'),\n                         ('Requests-Tier2', 'GET and the rest')]:\n        row(label, [by_usage(s3[r], r, usage) * 1000 for r in REGIONS], '{:.5f}')\n    efs = {r: offer('AmazonEFS', r) for r in REGIONS}\n    head('EFS, USD per GB-month')\n    row('Standard', [by_usage(efs[r], r, 'TimedStorage-ByteHrs') for r in REGIONS])\n\n\n", "note": "Storage: S3's classes and its requests, then EFS. The request prices are per request in the list and printed per thousand, which is how they are usually quoted."}, {"code": "def transfer():\n    dt = {r: offer('AWSDataTransfer', r) for r in REGIONS}\n    head('Data transfer, USD per GB')\n    # Egress is priced in tiers of monthly volume, and the tiers are the point:\n    # the first 10 TB of a month cost more per GB than the next 40.\n    tiers = {r: by_usage(dt[r], r, 'DataTransfer-Out-Bytes', first=False) for r in REGIONS}\n    names = ['first 10 TB', 'next 40 TB', 'next 100 TB', 'over 150 TB']\n    for i, name in enumerate(names):\n        row(f'out to the internet, {name}', [tiers[r][i][1] for r in REGIONS])\n    row('between zones, each direction',\n        [by_usage(dt[r], r, 'DataTransfer-Regional-Bytes') for r in REGIONS])\n    row('to the other region',\n        [by_usage(dt['sa-east-1'], 'sa-east-1', 'USE1-AWS-Out-Bytes'),\n         by_usage(dt['us-east-1'], 'us-east-1', 'USE1-SAE1-AWS-Out-Bytes')])\n    row('in from the internet',\n        [by_usage(dt[r], r, 'DataTransfer-In-Bytes') for r in REGIONS])\n\n\n", "note": "Data transfer. Egress has four tiers of monthly volume, and the sheet prints all four, because the tiers are what lesson 2 is about."}, {"code": "def lam():\n    fn = {r: offer('AWSLambda', r) for r in REGIONS}\n    head('Lambda, USD')\n    row('per 1 million requests',\n        [by_usage(fn[r], r, 'Request') * 1_000_000 for r in REGIONS], '{:.2f}')\n    row('per GB-second, x86',\n        [by_usage(fn[r], r, 'Lambda-GB-Second') for r in REGIONS], '{:.10f}')\n    row('per GB-second, Arm',\n        [by_usage(fn[r], r, 'Lambda-GB-Second-ARM') for r in REGIONS], '{:.10f}')\n    # The free allowance is in the list too, as a price of zero up to a limit.\n    free = {r: offer('AWSLambda', r) for r in REGIONS}\n    for usage, label in [('Request', 'free tier, requests'),\n                         ('Lambda-GB-Second', 'free tier, GB-seconds')]:\n        limits = []\n        for r in REGIONS:\n            limit = None\n            for sku, p in free[r]['products'].items():\n                if p['attributes'].get('usagetype') == 'Global-' + usage:\n                    for _, d in dims(free[r], sku):\n                        limit = float(d['endRange'])\n            limits.append(limit)\n        row(label, limits, '{:,.0f}')\n\n\n", "note": "Lambda's two prices and its free allowance. The allowance is in the list as a price of zero up to a limit, and the limit is the number printed."}, {"code": "BLOCKS = {'ec2': ec2, 'storage': storage, 'transfer': transfer, 'lambda': lam}\n\n\ndef main():\n    wanted = sys.argv[1:] or list(BLOCKS)\n    print('AWS public price list, USD, excluding tax')\n    for code, version in VERSION.items():\n        print(f'  offer {code:<16} version {version}')\n    print(f'  {\"\":<34}' + ''.join(f'{r:>13}' for r in REGIONS))\n    for name in wanted:\n        BLOCKS[name]()\n\n\nif __name__ == '__main__':\n    main()\n", "note": "The command line. With no argument, every block; with names, only those, in the order given. The header with the versions is printed every time, so every quote carries the versions it came from."}]}
```

It needs nothing but Python and the network, and no account: every file it reads is public. Run it
for one block first, the small one:

```
ana@laptop:~/cloud$ python3 prices.py lambda | tail -6
Lambda, USD
  per 1 million requests                     0.20         0.20
  per GB-second, x86                 0.0000166667 0.0000166667
  per GB-second, Arm                 0.0000133334 0.0000133334
  free tier, requests                   1,000,000    1,000,000
  free tier, GB-seconds                   400,000      400,000
ana@laptop:~/cloud$ ls ~/.cache/cloud-prices
AWSLambda-20260919002359-sa-east-1.json
AWSLambda-20260919002359-us-east-1.json
```

**The first run took a few seconds because it downloaded two files**, one per region, and the
listing shows them in the cache with the version in the name. Run the same command again and it
reads them from there, with no network at all.

## The EC2 block is the heavy one

`storage`, `transfer` and `lambda` together read about 5 MB of price list. **`ec2` reads two files
of 292 MB and 482 MB**, because the EC2 offer prices every machine type in every combination of
operating system, licence and tenancy, and the program has to read the whole file to find the
seven lines it wants. The first `python3 prices.py ec2`, or a `python3 prices.py` with no argument,
downloads both:

```
ana@laptop:~/cloud$ time python3 prices.py ec2 | head -12
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

EC2, Linux, on demand, USD per hour
  t3.micro    2 vCPU   1 GiB              0.01680      0.01040
  t4g.small   2 vCPU   2 GiB              0.02680      0.01680

real	0m37.845s
user	0m9.000s
sys	0m13.981s
ana@laptop:~/cloud$ du -sh ~/.cache/cloud-prices
740M	/home/ana/.cache/cloud-prices
ana@laptop:~/cloud$ time python3 prices.py ec2 > /dev/null

real	0m14.957s
user	0m7.084s
sys	0m7.663s
```

The first run took 38 seconds, most of it the download; the second, with both files already in the
cache, took 15, all of it reading them. **The download happens once. The reading happens every
time**, so a lesson's `prices.py ec2` takes a quarter of a minute where the other blocks answer at
once, and none of them needs the network again.

That run also needed 2.2 GB of memory at its peak, because Python holds the larger file in memory
as one dictionary while it searches it. **Give the sheet a machine with 4 GB of memory and 1 GB of
free disk for the cache.** With less memory, the section on failures says what happens and what to
do.
