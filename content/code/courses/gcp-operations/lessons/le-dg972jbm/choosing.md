---
title: Choosing, buying and watching a commitment
version: 1
---

**A commitment is chosen from history, bought once, and watched for its whole term.** History says what the base
really is; the purchase fixes it; watching says whether the base moved. Every step happens in a billing account and
none of it can run here; this section is from Google's documentation.

## Choosing from history

The base is not "how many machines we usually have"; it is the minimum over the last few months, hour by hour. Two
places give it:

- **The billing export** (lesson 23), queried for the machine-hours of each hour of the last 90 days: the lowest
  hours are the base.
- **Google's commitment recommendations**, which do the same calculation over recent usage and propose a commitment
  per region, with the expected saving. They are a starting point, computed from the past; they know nothing about
  the migration planned for next quarter.

**Commit below the measured base, not at it.** A base of four machines measured over three months is a base of four
until the day somebody right-sizes them (lesson 22) down to smaller types, at which point a commitment to four of
the old size covers usage that no longer exists. Committing to three leaves room for that.

## Buying

```sh
gcloud compute commitments create shop-batch-1y \
  --region=southamerica-east1 --plan=12-month \
  --resources=vcpu=12,memory=48GB
```

Not run: commitments are purchases. Two details of this command decide whether it saves anything. **The region**:
a resource-based commitment covers usage in one region only, so a commitment in São Paulo does nothing for a
machine in Iowa. **The resources are vCPUs and memory, not machines**: twelve vCPUs and 48 GB cover four machines
of four vCPUs and 16 GB each, or any other combination of the same family that adds up to it.

## Watching

Two numbers, every month, for the whole term:

| number | what it says | where |
|---|---|---|
| **utilisation** | the share of committed resources actually used | the billing console's commitment report, or the billing export |
| **coverage** | the share of eligible usage the commitment paid for | the same report |

Utilisation below 100% is money paid for nothing: the commitment is larger than the usage. Coverage well below 100%
is money left on the table: the base grew and a further commitment would save more. **Neither number is checked by
anything unless somebody puts it on a dashboard**, and lesson 25 makes the bill itself something an alert can read.
