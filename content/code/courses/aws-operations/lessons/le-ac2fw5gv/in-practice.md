---
title: Coverage, utilisation, and what the lab cannot show
version: 1
---

Two numbers describe a commitment once it exists, and Cost Explorer reports both:

- **utilisation**: how much of the commitment was used. Below 100% is money paid for nothing, the unused
  column of the previous section;
- **coverage**: how much of the eligible usage the commitments covered. The rest was paid on demand.

They pull in opposite directions. 100% utilisation with 40% coverage means the commitment is safe and
small; 90% coverage with 80% utilisation means it is large and partly wasted. The shop's choice of six
gives 100% utilisation and 68% coverage, and that is a good place to be: the uncovered third is
the part of the fleet that comes and goes.

Cost Explorer also **recommends** a commitment from the last 7, 30 or 60 days of usage. The
recommendation is the same arithmetic as `commit.py`, on the real history, and it is worth reading the
lookback it used: sixty days that include a sale will recommend a commitment the year cannot use.

## What moto shows instead

```
ana@laptop:~/aws/commit$ aws ec2 describe-reserved-instances-offerings --instance-type m7g.large --query 'ReservedInstancesOfferings[:3].[Duration,OfferingType,FixedPrice,UsagePrice]' --output text
31536000	No Upfront	0.0	0.05
31536000	Partial Upfront	208.0	0.05
31536000	All Upfront	261.0	0.0
ana@laptop:~/aws/commit$ aws ce get-savings-plans-purchase-recommendation --savings-plans-type COMPUTE_SP --term-in-years ONE_YEAR --payment-option NO_UPFRONT --lookback-period-in-days SIXTY_DAYS 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the GetSavingsPlansPurchaseRecommendation operation (reached max retries: 2): <!doctype html>
```

moto lists reserved instance offerings for `m7g.large` with prices it **makes up**, and makes up again on
every run: the three above are the first of dozens it listed, a one-year term in seconds, an upfront price
and an hourly one, for an instance whose real one-year all-upfront price the previous section read as
659 USD. That is the reason this course takes prices only from the
price list. And it has no recommendations, no Savings Plans service and no utilisation reports, so this
lesson's commitments are arithmetic on public prices and a made-up month, which is what a recommendation
is too, on a real month.

## Before buying

- **A commitment cannot be cancelled.** Savings Plans cannot be sold; standard RIs can be listed on the
  RI Marketplace, for a buyer, and convertible ones only exchanged.
- **Rightsize first.** Committing to instances that are twice the size they need to be locks the waste in
  for the term; lesson 23 is about finding it.
- **The discount covers compute only.** Data transfer, storage and requests are paid as before, and a
  bill of which compute is a third cannot be cut by more than a third by any commitment.
