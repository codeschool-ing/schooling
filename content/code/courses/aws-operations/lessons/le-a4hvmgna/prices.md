---
title: The price list, read by a program
version: 1
---

moto knows no prices. Every cost this course quotes comes instead from **the price list AWS publishes
for anybody**, as JSON files at `pricing.us-east-1.amazonaws.com`, with no account and no key: one
file per service and region, and a new version every time a price changes. The program below reads
the São Paulo file of a service and prints its lines. **It is the only program the course asks you
to keep**, because lessons 8 to 25 use it to put a price beside what they build.

Write it into `~/aws/price.py`:

```schooling-example
{"language": "python", "file": "price.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"price.py: lines of AWS's public price list for sa-east-1, at pinned versions.\n\n    python3 price.py AWSCodePipeline            every line for one service\n    python3 price.py CodeBuild general1.small   only lines with all those words\n\nEach service's offer is downloaded once into ~/.cache/aws-prices and read\nfrom there. No account and no key: the list is published for anybody.\n\"\"\"\n", "note": "The docstring says how to call it. The first argument is a service's code in the price list, and any further words narrow the lines down."}, {"code": "import json\nimport os\nimport sys\nimport urllib.request\n\n", "note": "Standard library only, so nothing new has to be installed: `urllib` downloads, `json` reads."}, {"code": "BASE = 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws'\nCACHE = os.path.expanduser('~/.cache/aws-prices')\nVERSION = {\n    'AWSCodePipeline': '20260911124534',\n    'CodeBuild': '20260911124625',\n    'AmazonECR': '20260911124425',\n    'AmazonCloudWatch': '20261007115540',\n    'AWSXRay': '20260911124622',\n    'awswaf': '20260914163921',\n    'AWSShield': '20260916132208',\n    'AWSSecretsManager': '20260911124610',\n    'AWSSystemsManager': '20261008071021',\n    'awskms': '20260911124601',\n    'AmazonGuardDuty': '20261008231203',\n    'AWSSecurityHub': '20260930174933',\n    'AmazonInspectorV2': '20261015180712',\n    'AWSCloudTrail': '20260911124531',\n    'AWSConfig': '20260911124534',\n    'AmazonS3': '20261015173540',\n    'AmazonDynamoDB': '20260911124422',\n}\n\n\n", "note": "**Every offer is pinned to one version.** AWS keeps every version it ever published, so the same command prints the same prices next year, and the date in the first line of the output is the date of the price, not of the run. A newer version is a line edited here."}, {"code": "def offer(code):\n    path = os.path.join(CACHE, f'{code}-{VERSION[code]}.json')\n    if not os.path.exists(path):\n        os.makedirs(CACHE, exist_ok=True)\n        url = f'{BASE}/{code}/{VERSION[code]}/sa-east-1/index.json'\n        urllib.request.urlretrieve(url, path + '.part')\n        os.rename(path + '.part', path)\n    with open(path) as f:\n        return json.load(f)\n\n\n", "note": "One file per service, downloaded the first time it is asked for and read from the cache afterwards. The `.part` name means an interrupted download never looks like a finished one."}, {"code": "def lines(doc):\n    for sku, product in doc['products'].items():\n        usage = product['attributes'].get('usagetype', '')\n        for term in doc['terms'].get('OnDemand', {}).get(sku, {}).values():\n            for d in term['priceDimensions'].values():\n                yield usage, float(d['pricePerUnit']['USD']), d['unit'], d['description']\n\n\n", "note": "A product is a `usagetype`, the name the bill uses for a line, and its on-demand terms hold one or more price dimensions: a price, a unit and a sentence describing it."}, {"code": "def main():\n    code, words = sys.argv[1], [w.lower() for w in sys.argv[2:]]\n    doc = offer(code)\n    print(f'{code}, sa-east-1, published {doc[\"publicationDate\"][:10]}')\n    for usage, usd, unit, text in sorted(lines(doc)):\n        if all(w in (usage + ' ' + text).lower() for w in words):\n            print(f'  {usage:<36} {usd:>12.6f} USD per {unit:<10} {text}')\n\n\nmain()\n", "note": "Print the publication date first, then every line whose usage type or description contains all the words asked for, sorted, so two runs print the same order."}]}
```

The two services this lesson is about cost this, per line of the bill:

```
ana@laptop:~/aws$ python3 price.py AWSCodePipeline
AWSCodePipeline, sa-east-1, published 2026-09-11
  Global-actionExecutionMinute             0.000000 USD per minutes    $0.00 for 100 action execution minutes
  Global-activePipeline                    0.000000 USD per pipelines  $0.00 for first active pipeline
  SAE1-actionExecutionMinute               0.002000 USD per minutes    $0.002 per action execution minute
  SAE1-activePipeline                      1.000000 USD per pipelines  $1.00 per additional active pipeline
  SAE1-trialPipeline                       0.000000 USD per pipelines  $0.00 per trial pipeline - no charge for pipelines created within 30 days
ana@laptop:~/aws$ python3 price.py CodeBuild Build-Min:Linux:g1
CodeBuild, sa-east-1, published 2026-09-11
  Global-Build-Min:Linux:g1.small          0.000000 USD per minutes    AWS CodeBuild Free Tier - 100 build minutes on build.general1.small
  SAE1-Build-Min:Linux:g1.2xlarge          0.300000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.2xlarge in South America (Sao Paulo)
  SAE1-Build-Min:Linux:g1.large            0.020000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.large - South America (Sao Paulo)
  SAE1-Build-Min:Linux:g1.medium           0.010000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.medium - South America (Sao Paulo)
  SAE1-Build-Min:Linux:g1.small            0.005000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.small - South America (Sao Paulo)
  SAE1-Build-Min:Linux:g1.xlarge           0.125000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.xlarge in South America (Sao Paulo)
```

Read a line from the right. The sentence is AWS's own. The number is US dollars per unit, and the
unit is a minute of a build, a minute of an action, or one pipeline for a month. The left column is
the **usage type**, the name the same line will carry on a bill, and lesson 24 reads bills by it.
`SAE1-` is São Paulo; `Global-` lines are the free allowance, which applies to the account as a
whole.

So **a build on the smallest Linux machine costs half a cent a minute**, and a pipeline of the newer
type costs nothing to keep and 0.2 cents for every minute one of its actions runs. A pipeline whose
build takes six minutes and whose deployment takes four, run twenty times a working day for 22 days,
costs 440 runs × 6 minutes × 0.005 = 13.20 USD in builds, and 440 × 10 minutes × 0.002 = 8.80 USD in
action minutes, less the 100 free minutes of each. The older type of pipeline charged 1 USD a
month instead, whatever it did; that is the `activePipeline` line, and which one a pipeline is
billed by is its `pipelineType`, `V1` or `V2`.

**These are list prices, at the date in the first line of each block.** A discount, a credit or a
tax is not in them, and lesson 22 is about the discounts. A newer version of an offer is a newer
`VERSION` in the program, and the date it prints changes with it.
