---
title: What leaving would cost, estimated before you arrive
version: 1
---

"How locked in are we?" has no answer. **"What would leaving cost, in money and in weeks?" has
one**, and it can be estimated on the first day, when it is cheapest to change. The estimate has
four lines, and each comes from something you can count: the code that would be rewritten, the
data that would be moved, the people who would have to learn something new, and the weeks of
running both while the move happens.

**Every effort figure in this section's example is invented.** The line counts, the prices per
gigabyte and lesson 23's monthly bill are captures, and the arithmetic on them is exact.

## The rewrite surface

Start with the code. The question is not how big the application is but how much of it touches the
provider. For the shop of the previous section that can be counted directly:

```
ana@laptop:~/aws/shop$ wc -l orders.py lambda_app.py server.py
  14 orders.py
  11 lambda_app.py
  20 server.py
  45 total
ana@laptop:~/aws/shop$ grep -n "quote" lambda_app.py server.py
lambda_app.py:4:from orders import quote
lambda_app.py:8:    status, body = quote(json.loads(event.get("body") or "{}"))
server.py:5:from orders import quote
server.py:11:        status, body = quote(json.loads(self.rfile.read(size) or b"{}"))
```

Fourteen lines of `orders.py` hold the shop's rule, its name and its docstring, and the other two
files exist to reach it: eleven lines for Lambda, twenty for a web server. The `grep` shows that
each of them touches the rule in exactly two places, the import and the call. Leaving Lambda for a
container means using the twenty-line file, which already exists; leaving a container for Lambda
means the eleven-line one. **What has to be rewritten is the adapters, never the rule**, because the rule never learnt where
it runs.

On a real codebase the same count is a search: every file that imports `boto3`, reads an `event`
dictionary, parses a Step Functions input, or names an ARN. A codebase where that search returns
four files has a small rewrite surface; one where it returns two hundred has a large one, whatever
the architecture diagram says.

## Data, and the price of moving it

Data is the lock-in that grows by itself. Every month the shop stores more photos and more reports,
and every gigabyte is one more to carry out. Carrying it out of AWS to the internet is priced by the
gigabyte, in tiers, and the tiers are in the EC2 offer that `prices.py` already downloaded. A short
program reads them, at the same pinned version as the rest of the sheet:

```python
# egress.py
"""Data transfer from São Paulo to the internet, from AWS's price list.

Reads the EC2 offer that prices.py downloaded, at the same pinned version.
"""
import json
import os

PATH = '~/.cache/aws-prices/AmazonEC2-20261015191316-sa-east-1.json'

doc = json.load(open(os.path.expanduser(PATH)))
tiers = []
for sku, product in doc['products'].items():
    if product['attributes'].get('usagetype') == 'SAE1-DataTransfer-Out-Bytes':
        for term in doc['terms']['OnDemand'][sku].values():
            tiers += term['priceDimensions'].values()
for d in sorted(tiers, key=lambda d: float(d['beginRange'])):
    usd = float(d['pricePerUnit']['USD'])
    print(f"{d['beginRange']:>7} to {d['endRange']:>6} GB a month  {usd:.2f} USD per GB")
```

```
ana@laptop:~/aws$ python3 egress.py
      0 to      1 GB a month  0.00 USD per GB
      1 to  10240 GB a month  0.25 USD per GB
  10240 to  51200 GB a month  0.23 USD per GB
  51200 to 153600 GB a month  0.21 USD per GB
 153600 to    Inf GB a month  0.19 USD per GB
```

So from São Paulo, after the first gigabyte of the month, data to the internet costs **0.25 USD
per GB up to 10 TB**, falling in steps to 0.19 above 150 TB. Two terabytes of photos and reports,
2,048 GB, would cost (2,048 − 1) × 0.25 = **511.75 USD** to send out in one month at the list
price.

That list price is not the whole story, and the rest of it was not run here. On 5 March 2024 AWS
announced that it waives data transfer out to the internet for customers moving off AWS: the
customer asks AWS Support first, receives a credit for the transfer, and has a limited time to
complete the move. Treat it as a policy that can change, read its current terms on the day you
need it, and keep the list price in the estimate as the figure that holds without anybody's
approval.

## People and overlap

The last two lines are where most of the cost hides:

- skills: the team that runs the shop on Fargate would need to learn the new provider's
  container service, its identity model and its networking. Count people times days;
- overlap: during the move both platforms run, and the old one costs what it cost before. For
  the shop that is 49.60 USD a month of Fargate tasks, from lesson 23, for every month the move
  takes, before the load balancer and the storage.

## The estimate, written down

Put together, with the example's invented effort figures beside the captured ones:

| line | how it is counted | the shop, as an example |
| --- | --- | --- |
| rewrite | files and lines touching the provider | the adapters, 31 lines; storage calls, 2 days |
| data | GB to move × price per GB | 2,048 GB × 0.25 = 511.75 USD, or a waiver |
| skills | people × days to learn | 3 people × 3 days |
| overlap | months × the old monthly bill | 1 month × 49.60 USD, plus storage |

**The total is not the point; the biggest line is.** For the shop it is the people, not the
money, which is common for a small team. It says where a seam would pay for itself and
where it would not: no adapter makes three people know a new platform, but keeping the rule out of
the handlers made the rewrite line almost nothing.
