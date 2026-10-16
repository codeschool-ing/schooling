---
title: Crossing zones, and what a load balancer costs
version: 1
---

**A load balancer is not one machine.** AWS runs a piece of it, a **node**, in every zone you gave
it a subnet in. The name `shop-web-1.sa-east-1.elb.amazonaws.com` answers with the addresses of all
the nodes. Each caller lands on one node. The question of this section is what that node does next:
send only to targets in its own zone, or to targets in every zone. That choice is **cross-zone load
balancing**, and it decides both how evenly the load spreads and whether lesson 1's price for
crossing a zone appears on the bill.

## When the zones are uneven

The wrong picture is that a load balancer divides requests evenly between targets. It divides them
evenly between **nodes**, because DNS hands out the nodes' addresses in turn. What each node does
with its share depends on the setting. Put two targets in `sa-east-1a` and eight in `sa-east-1b`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l22-cross-zone\" aria-label=\"Cross-zone load balancing, with two targets in sa-east-1a and eight in sa-east-1b. Each zone has a load balancer node, and each node receives half the traffic. On the left, cross-zone off: each node sends only to its own zone, so the two targets in sa-east-1a carry 25% each and the eight in sa-east-1b 6.25% each. On the right, cross-zone on: each node sends to every target, and all ten carry 10% each.\"><defs><marker id=\"l22-cross-zone-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22-cross-zone-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l22-cross-zone-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"185.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">cross-zone off</text><rect x=\"20.0\" y=\"44.0\" width=\"110.0\" height=\"236.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"41.0\" y=\"76.0\" width=\"68.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">node: 50%</text><rect x=\"31.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"51.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">25%</text><rect x=\"79.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"99.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">25%</text><rect x=\"150.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"216.0\" y=\"76.0\" width=\"68.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">node: 50%</text><rect x=\"158.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6.25%</text><rect x=\"206.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"226.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6.25%</text><rect x=\"254.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"274.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6.25%</text><rect x=\"302.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"322.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6.25%</text><rect x=\"158.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6.25%</text><rect x=\"206.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"226.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6.25%</text><rect x=\"254.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"274.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6.25%</text><rect x=\"302.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"322.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6.25%</text><path d=\"M75.0 106.0 L75.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#l22-cross-zone-af-ah-amber)\"></path><path d=\"M250.0 106.0 L250.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22-cross-zone-af-ah-paper-dim)\"></path><text x=\"535.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">cross-zone on</text><rect x=\"370.0\" y=\"44.0\" width=\"110.0\" height=\"236.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"391.0\" y=\"76.0\" width=\"68.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">node: 50%</text><rect x=\"381.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"401.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"429.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"449.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"500.0\" y=\"44.0\" width=\"200.0\" height=\"236.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"566.0\" y=\"76.0\" width=\"68.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">node: 50%</text><rect x=\"508.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"528.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"556.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"604.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"624.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"652.0\" y=\"170.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"672.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"508.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"528.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"556.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"604.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"624.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><rect x=\"652.0\" y=\"222.0\" width=\"40.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"672.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">10%</text><path d=\"M425.0 106.0 L425.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22-cross-zone-af-ah-phosphor)\"></path><path d=\"M600.0 106.0 L600.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22-cross-zone-af-ah-phosphor)\"></path><path d=\"M450.0 104.0 L490.0 134.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M490.0 134.0 L538.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l22-cross-zone-af-ah-phosphor)\"></path><path d=\"M566.0 104.0 L490.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M490.0 140.0 L442.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l22-cross-zone-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">each node gets half the traffic; the setting decides where it may send it</text></svg>", "caption": "Off, a zone carries half the load however few targets it holds. On, the load follows the targets."}
```

**With cross-zone off, each zone gets half the traffic whatever it holds**. The two machines in
`sa-east-1a` carry a quarter each, and the eight in `sa-east-1b` an eighth of a half, 6.25% each.
The two will be overloaded long before the eight are busy. With it on, every node spreads over every
target and each of the ten carries 10%. The other way to fix it is to keep the zones even. An auto
scaling group spread over the same zones does that, and `aws-compute` lesson 4 builds one.

## The setting, per kind

| | cross-zone by default | can it be turned off | crossing a zone, LB to target |
|---|---|---|---|
| application | on | per target group, not for the whole ALB | not charged |
| network | off | on and off, per LB or per target group | charged, as lesson 1 priced it |
| gateway | off | on and off | charged, as lesson 1 priced it |

The table is AWS's documented behaviour. Ask moto about the ALB and the NLB this lesson made:

```
ana@laptop:~/aws$ nlb=$(aws elbv2 describe-load-balancers --names shop-tcp --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws$ aws elbv2 describe-load-balancer-attributes --load-balancer-arn $lb --query "Attributes[?Key=='load_balancing.cross_zone.enabled'].Value" --output text
false
ana@laptop:~/aws$ aws elbv2 describe-load-balancer-attributes --load-balancer-arn $nlb --query "Attributes[?Key=='load_balancing.cross_zone.enabled'].Value" --output text
false
```

**moto reports `false` for both, and for the ALB that is wrong**. An ALB always balances across
zones at the load balancer level. What can be switched off is the same setting on one of its target
groups. For the NLB `false` is the true default, and turning it on is one call:

```
ana@laptop:~/aws$ aws elbv2 modify-load-balancer-attributes --load-balancer-arn $nlb --attributes Key=load_balancing.cross_zone.enabled,Value=true --query "Attributes[?Key=='load_balancing.cross_zone.enabled'].Value" --output text
true
```

**On an NLB, that call has a price.** With the targets spread evenly over two zones, about half of
what each node forwards crosses to the other zone. Lesson 1 read that crossing at 0.01 dollars a
gigabyte leaving one zone plus 0.01 arriving in the other. An NLB forwarding 2 TB a month with
cross-zone on sends about 1,024 GB across, so 1,024 × 0.02 = **20.48 dollars a month** for the
crossing alone. The ALB's crossing is not charged, which AWS's pricing page says and the transfer
lines of the price list do not show. So the NLB's default is a choice between an even load and a
smaller bill. The right answer is often to keep cross-zone off and the zones even.

## The price list

The load balancers have an offer of their own, `AWSELB`, 16 kilobytes for São Paulo. The EC2 offer
the `cloud` course read the same line from is about 290 megabytes, and both say 0.0340 for an ALB's
hour. Ask `price.py` for the two usage types that matter:

```
ana@laptop:~/aws$ python3 price.py AWSELB 20260911124544 sa-east-1 SAE1-LoadBalancerUsage SAE1-LCUUsage
AWSELB 20260911124544, published 2026-09-11, USD
SAE1-LoadBalancerUsage
          0 to       Inf Hrs  0.0189
          0 to       Inf Hrs  0.0340
          0 to       Inf Hrs  0.0340
          0 to       Inf Hrs  0.0340
SAE1-LCUUsage
          0 to       Inf LCU-Hrs 0.0055
          0 to       Inf LCU-Hrs 0.0083
          0 to       Inf LCU-Hrs 0.0110
```

**Four prices under one name, and three under the other, with nothing to say which is which**. The
four decimals have also turned one of them, 0.00825, into `0.0083`. A usage type is not always
unique inside an offer: the same `SAE1-LoadBalancerUsage` is the hour of a Classic, an application,
a network and a gateway load balancer. What tells them apart is another attribute of the product,
its **operation**. This short program prints it beside each price. Save it as `~/aws/ops.py`:

```python
#!/usr/bin/env python3
"""Prints each price of a usage type beside the operation it is charged for.

    python3 ops.py OFFER VERSION REGION USAGETYPE...

Reads the offer price.py has already downloaded into ~/.cache/aws-prices.
"""
import json
import os
import sys

code, version, region, *usages = sys.argv[1:]
path = os.path.expanduser(f'~/.cache/aws-prices/{code}-{version}-{region}.json')
with open(path) as f:
    doc = json.load(f)
for usage in usages:
    rows = []
    for sku, product in doc['products'].items():
        a = product['attributes']
        if a.get('usagetype') == usage:
            for term in doc['terms']['OnDemand'].get(sku, {}).values():
                for d in term['priceDimensions'].values():
                    rows.append((a.get('operation', ''), float(d['pricePerUnit']['USD']), d['unit']))
    print(usage)
    for operation, price, unit in sorted(rows):
        print(f'  {operation:<26} {price:.5f} per {unit}')
```

```
ana@laptop:~/aws$ python3 ops.py AWSELB 20260911124544 sa-east-1 SAE1-LoadBalancerUsage SAE1-LCUUsage
SAE1-LoadBalancerUsage
  LoadBalancing              0.03400 per Hrs
  LoadBalancing:Application  0.03400 per Hrs
  LoadBalancing:Gateway      0.01890 per Hrs
  LoadBalancing:Network      0.03400 per Hrs
SAE1-LCUUsage
  LoadBalancing:Application  0.01100 per LCU-Hrs
  LoadBalancing:Gateway      0.00550 per LCU-Hrs
  LoadBalancing:Network      0.00825 per LCU-Hrs
```

`LoadBalancing` alone is the Classic load balancer; the other three name their kind. In the list AWS
published on **11 September 2026**, in São Paulo:

| | per hour | per capacity unit-hour |
|---|---|---|
| application | 0.034 | 0.011 (LCU) |
| network | 0.034 | 0.00825 (NLCU) |
| gateway | 0.0189 | 0.0055 (GLCU) |

## Two meters running at once

**A load balancer is billed by the hour it exists and by the work it does**, and the second meter is
the one that surprises. A **capacity unit** is a bundle of work, and an hour is charged for the
largest of its dimensions. AWS's pricing page, not the list, defines them. For an ALB, one LCU is up to 25 new connections a
second, 3,000 active connections a minute, 1 GB processed in the hour for machine targets, or 1,000
rule evaluations a second. An NLB's unit is larger in connections, 800 new TCP connections a second
and 100,000 active, with the same 1 GB.

The shop's ALB for a month of 730 hours, processing about 2 GB an hour:

- the hours: 730 × 0.034 = **24.82 dollars**, whether anybody visits or not;
- the work: bytes are the largest dimension, so 2 LCU each hour, 2 × 730 × 0.011 = **16.06 dollars**;
- together **40.88 dollars a month**, before the bytes it sends to the internet, which are lesson 1's
  0.15 a gigabyte from São Paulo and the largest line once the shop is busy.

**The hour meter is why a load balancer left running is the usual forgotten charge**: 24.82
dollars a month for one that serves nothing, which is the warning lesson 1 gave for a real account.
moto charged nothing for the three this lesson made, and AWS would charge for all three from the
minute each was created. Delete them when the lesson is done, in a real account, the same day.
