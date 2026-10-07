---
title: EKS, AKS and GKE, by what they charge and what they differ on
version: 1
---

::: track cloud-engineering
The `cloud` course, which comes before this one in your track, compared the three providers as a
whole in its lesson 3 and their billing in its lesson 10. What follows is only the part of their
catalogue that runs Kubernetes.
:::

::: track devops devsecops
The `cloud` course comes after this one in your track, and its lesson 3 compares the three
providers as a whole. What follows is only the part of their catalogue that runs Kubernetes.
:::

::: track *
The `cloud` course compares the three providers as a whole, in its lesson 3. What follows is only
the part of their catalogue that runs Kubernetes.
:::

**On the Kubernetes itself the three agree, and they have to.** Each is certified by the CNCF's
conformance programme, which runs the same suite of tests against every certified distribution, so
a Deployment, a Service or a ConfigMap behaves the same on all three and on the laptop's cluster.
Where they differ is the fee, how long a version is supported, and how the cluster is wired into the
rest of the provider.

## The fee for the control plane, read from the price lists

Amazon publishes its whole price list as files anybody can download. This reads one version of the
EKS file, pinned so the numbers stay the numbers it says:

```
ana@laptop:~/shop$ python3 eks-prices.py | sort
price list published 2026-09-28T19:42:55Z
sa-east-1  cluster, standard support  USD 0.10 per hour
sa-east-1  extended support, added    USD 0.50 per hour
us-east-1  cluster, standard support  USD 0.10 per hour
us-east-1  extended support, added    USD 0.50 per hour
```

**An EKS cluster costs 0.10 dollars an hour while its version is in standard support, in both
regions**, and 0.50 more once that version moves into extended support. Google publishes no such
file, so the next reading is its pricing page as it stood on the day this lesson was recorded:

```
ana@laptop:~/shop$ python3 gke-prices.py
- that's financially backed providing the following availability: 99.95% for the control plane of Autopilot clusters and regional Standard clusters.
- 99.5% for the control plane of zonal Standard clusters.
- Free tier The GKE free tier provides $74.40 in monthly credits per billing account, which is equivalent to one free Autopilot or zonal Standard cluster per month.
- Cluster management fee A flat cluster management fee of $0.10 per cluster per hour (charged in 1 second increments)
- The GKE extended period cluster management fee is in addition to the GKE cluster management fee at $0.10 per cluster per hour, for a total of $0.60 per cluster per hour.
```

**GKE charges the same 0.10 dollars an hour per cluster**, and its free tier, 74.40 dollars a month,
is exactly that fee for a month of 744 hours: one zonal or Autopilot cluster costs nothing to run as
a control plane. Its extended support also adds 0.50, to 0.60 an hour. The page also states the
service level: 99.95% for a regional cluster's control plane, 99.5% for a zonal one.

*Microsoft's price list for AKS could not be read from the machine this was recorded on*, whose
network refused the address, so no AKS figure is quoted here. Its arrangement is published in tiers:
a free tier with no cluster fee and no financially backed uptime commitment, a standard tier with a
fee per cluster hour and one, and a premium tier that adds long-term support for old versions. Read
the current numbers on Azure's own page before you compare.

## The fee is the small part

A control plane at 0.10 dollars an hour is 74.40 dollars for a 31-day month. **The machines that run
your pods usually cost several times that**, and they are billed at the provider's ordinary price
for virtual machines whichever orchestrator runs on them. So the fee rarely decides between the
three. What does:

| | EKS | AKS | GKE |
|---|---|---|---|
| a pod's address comes from | the VPC itself, by default | an overlay, or the virtual network | the VPC, through alias ranges |
| a pod gets cloud permissions through | EKS Pod Identity or IAM roles for service accounts | Microsoft Entra Workload ID | Workload Identity Federation |
| versions move along | a version you choose, upgraded when you ask | a version you choose, or automatic channels | release channels: Rapid, Regular, Stable, Extended |
| nodes run by the provider | EKS Auto Mode, or Fargate | node auto-provisioning | Autopilot |

**Most teams choose the provider they already use**, because their accounts, networks, identity and
billing are already there, and a cluster in another cloud would have to reach all of it across the
internet. The table above is what you meet on the second day, not a reason to move.
