---
title: What a control plane costs in money
version: 1
---

Start with the numbers that lesson 6 read from the price lists, and turn them into months. A month of
730 hours is the average a year of 8,760 hours gives:

| | per hour | per month of 730 hours | per year |
|---|---|---|---|
| EKS or GKE control plane, standard support | 0.10 dollars | 73.00 dollars | 876 dollars |
| the same, in extended support | 0.60 dollars | 438.00 dollars | 5,256 dollars |
| GKE free tier, per billing account | | a credit of 74.40 dollars | |

**A managed control plane is 73 dollars a month**, and on GKE the first zonal or Autopilot cluster
costs nothing. The extended-support line is the one to notice: a
cluster left on an old version costs six times as much, which is the providers' way of saying
"upgrade".

## Running the control plane yourself

A control plane you run needs machines of its own. **For it to survive the loss of one machine, etcd
needs three members**, as lesson 4 explained: a majority of three is two. So the cost in machines is

`3 × (price of one machine per hour) × 730`

and the price per hour is whatever your provider charges for the size you choose. This course has not
read a virtual machine price list, so no figure is given here; put in your own. At any price above
about 0.033 dollars an hour per machine, three machines already cost more than the 73-dollar fee,
before anybody has spent an hour on them.

Worker nodes do not enter the comparison at all. **They cost the same whether the control plane is
yours or the provider's**, because they are the same machines at the same price, and they are almost
always the largest line of the bill.

::: track cloud-engineering
The `cloud` course, earlier in your track, set budgets and spend alerts in its lesson 10. A cluster's
account deserves one: a forgotten node pool or a cluster left in extended support is exactly what they
catch.
:::

::: track *
Whichever way you run it, set a budget and a spend alert on the account the cluster bills to: a
forgotten node pool or a cluster left in extended support is exactly what they catch.
:::
