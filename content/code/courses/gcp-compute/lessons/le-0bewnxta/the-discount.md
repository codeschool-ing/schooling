---
title: The discount
version: 1
---

Google has machines that nobody is renting at a given moment, and it sells that spare capacity at a
discount on one condition: **it can take the machine back whenever it needs the capacity, with
thirty seconds' notice.** A Spot VM is an ordinary machine of an ordinary type with that condition
attached. Everything this lesson teaches follows from the condition, and the price is the reason to
put up with it.

## What it saves

The sheet from lesson 1 lists the Spot price beside the on-demand one for the types the Spot page
showed:

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E "Spot|0\.0[0-9]*$"
                                    per hour   per month   Spot/hour
  e2-standard-2   2 vCPU   8 GiB    0.06701142       48.92    0.040212
  n4-standard-2   2 vCPU   8 GiB        0.0907       66.21    0.053652
  n2-standard-2   2 vCPU   8 GiB      0.097118       70.90    0.058256
  c4-standard-2   2 vCPU   7 GiB      0.096866       70.71    0.057979
  c4a-standard-2  2 vCPU   8 GiB        0.0898       65.55    0.044388
```

Divide one column by the other and the discount is about **40% on E2, N2, N4 and C4**, and about
**51% on C4A**: `e2-standard-2` falls from 0.067 to 0.040 an hour, `c4a-standard-2` from 0.0898 to
0.0444. Google's Spot page advertises discounts of up to 91% on some types, and the size of the
discount depends on the type and the region. These five, in Iowa on 30 October 2026, were all
between 40% and 51%.

**Spot prices move.** On-demand prices change rarely and with notice; Spot prices are revised by
Google as spare capacity changes, which is why the price pages list them apart. A budget built on a
Spot price is built on a number that will not be the same next quarter, so the arithmetic is worth
redoing rather than remembering.

## Spot and preemptible

Older documentation and older Terraform talk about **preemptible** machines. They are the same idea
with one more limit: a preemptible machine is stopped after at most 24 hours even if nobody needs the
capacity. Spot machines replaced them and have no such limit; a Spot machine can run for weeks if
Google never needs it back. In Terraform both are written in the `scheduling` block, and Spot is
the one to write today. gcloud's help describes the provisioning models in a sentence each:

```
ana@laptop:~/gcp$ gcloud compute instances create --help | sed -n '/^         SPOT/,/^$/p'
         SPOT
            Compute Engine may stop a Spot VM instance whenever it needs
            capacity. Because Spot VM instances don't have a guaranteed
            runtime, they come at a discounted price.
         STANDARD
            The default option. The STANDARD provisioning model gives you full
            control over your VM instances' runtime.
```

**"Don't have a guaranteed runtime"** is the whole contract, and it is not a probability anybody
publishes. A Spot machine may run for a month or be taken back in its first hour, and the rest of
this lesson is about building work that does not care which.
