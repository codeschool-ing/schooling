---
title: The discount, and what sets it
version: 1
---

The common picture of spot is an auction: you bid, the highest bids win, and a better bid keeps
your instance. That was roughly true until 2017 and is not how it works now. **A spot instance is
on-demand capacity that nobody is using at the moment, sold at a lower price, with one condition:
AWS takes it back when it needs it.** There is no bidding. The price for each instance type in each
Availability Zone is set by AWS from the long-term supply and demand for that pool, and it moves
gradually, over days rather than minutes.

## How much cheaper

AWS describes the discount as **up to 90%** off the on-demand price. That number is a ceiling, not
a quote: the real discount depends on the type, the zone and the week, and a type everybody wants
in a busy zone is discounted much less than an older one nobody asks for. Spot prices are not in
the price sheet of lesson 1, which reads AWS's published on-demand list as of 16 October 2026, and
this course does not invent them. Where an arithmetic needs one, the lesson says it is an
assumption.

moto has a spot price history, and it shows why a number from moto is never a price:

```
ana@laptop:~/aws$ aws ec2 describe-spot-price-history --instance-types m7i.large --product-descriptions Linux/UNIX --query "SpotPriceHistory[].[AvailabilityZone,SpotPrice,Timestamp]" --output table
--------------------------------------------------------
|               DescribeSpotPriceHistory               |
+-------------+----------+-----------------------------+
|  sa-east-1a |  0.00001 |  2006-01-02T15:04:05+00:00  |
|  sa-east-1b |  0.00001 |  2006-01-02T15:04:05+00:00  |
|  sa-east-1c |  0.00001 |  2006-01-02T15:04:05+00:00  |
+-------------+----------+-----------------------------+
```

**Every one of those rows is a placeholder.** One ten-thousandth of a cent an hour, the same in every
zone, stamped with a date in 2006, the year EC2 opened and three years before spot existed. On AWS
the same command returns a row per zone per change of price, over the last 90 days, and it is the
honest way to see what a pool has cost recently. Even then it shows the past, which is the only
thing a spot price can promise.

## Asking for one

A spot instance is an ordinary launch with one more option. `--instance-market-options` names the
market and two choices: whether the request is `one-time` or `persistent`, and what happens at an
interruption.

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type m7i.large --instance-market-options '{"MarketType": "spot", "SpotOptions": {"SpotInstanceType": "one-time", "InstanceInterruptionBehavior": "terminate"}}' --query 'Instances[].[InstanceId,InstanceType,InstanceLifecycle]' --output text
i-25f3f8de6964698c7	m7i.large	spot
ana@laptop:~/aws$ aws ec2 describe-spot-instance-requests --query "length(SpotInstanceRequests)"
0
```

The instance is an `m7i.large` like any other, and `InstanceLifecycle` is the one field that says
it is spot; an on-demand instance has none. **The zero is moto's again.** On AWS, launching spot
through `run-instances` also creates a spot instance request behind the instance, and
`describe-spot-instance-requests` lists it with its state; moto records the instance and no request.

The interruption behaviour is a decision about what the instance is:

- **`terminate`**, the default, ends it. Its root volume goes with it if the template said so, as
  lesson 4's did.
- **`stop`** keeps its EBS volumes and stops it, and the request starts it again when capacity is
  back. It needs a `persistent` request.
- **`hibernate`** writes its memory to the root volume first, so it resumes where it was. It also
  needs a persistent request, an encrypted root volume large enough for the memory, and an image
  prepared for it.

There is also a **maximum price**, `MaxPrice`, which defaults to the on-demand price. Setting it
lower does not make spot cheaper, since you pay the spot price whatever your maximum is; it only
adds a second reason to be interrupted, when the spot price rises above it.

## What the discount buys, in the sheet's numbers

The price sheet has the on-demand side: an `m7i.large` in São Paulo is 0.16065 USD an hour. Ten of
them for a month of 730 hours cost 10 × 0.16065 × 730 = 1,172.745 USD on demand. The group of the
mixed-groups section keeps four of the ten on demand and six on spot. **Suppose, for the sake of
the arithmetic, a spot discount of 60%**, which is an assumption and not a price anybody quoted. The
four on-demand instances cost 4 × 0.16065 × 730 = 469.10, the six spot ones
6 × 0.16065 × 0.4 × 730 = 281.46, and the month comes to 750.56 instead of 1,172.75: about 36% less
for the group, from a 60% discount on 60% of it.

That last sentence is the shape to keep. **The saving is the discount times the share of the group
on spot**, and the share on spot is limited by how much of the group can lose an instance with two
minutes' notice. The rest of this lesson is about making that share large without making it
dangerous.
