---
title: Upgrades, one minor version at a time, on a clock
version: 1
---

Two beliefs about upgrades cost teams money on EKS. One is that a managed service keeps itself up
to date, and the other that a cluster two versions behind can jump straight to the current one.
**Neither is true. You start every upgrade, the control plane moves one minor version per upgrade,
and each version has a date after which it costs six times as much.**

## The clock

Kubernetes releases a minor version about three times a year, and EKS supports each one for a
fixed time from the day EKS releases it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline of one Kubernetes version on EKS. Standard support for 14 months at 0.10 USD an hour, then extended support for 12 more at 0.60 USD an hour in all, after which AWS upgrades the control plane itself. A cluster whose upgrade policy is STANDARD is upgraded automatically at month 14 instead.\"><defs><marker id=\"eks-sup-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40 40 L684 40\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40 34 L40 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"34\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">release on EKS</text><path d=\"M376 34 L376 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"376\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">month 14</text><path d=\"M664 34 L664 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"664\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">month 26</text><text x=\"40\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">upgradePolicy EXTENDED, the default</text><rect x=\"40\" y=\"82\" width=\"336\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"208\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">standard support</text><text x=\"208\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.10 USD an hour</text><rect x=\"376\" y=\"82\" width=\"288\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"520\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">extended support</text><text x=\"520\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.60 USD an hour in all</text><text x=\"660\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">AWS upgrades it</text><text x=\"40\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">upgradePolicy STANDARD</text><rect x=\"40\" y=\"184\" width=\"336\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"208\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">standard support</text><text x=\"208\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.10 USD an hour</text><text x=\"384\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">upgraded here, automatically</text></svg>", "caption": "One minor version's life on EKS. The clock starts when EKS releases the version, not when you create the cluster, so a cluster created late in the window has little of it left."}
```

**Standard support lasts 14 months, and extended support 12 more.** The price sheet prints the two
meters, as published on 16 October 2026: 0.10 USD an hour for a cluster, and 0.50 an hour for
extended support. AWS's pricing page gives a cluster in extended support as 0.60 an hour in all,
which is the two lines charged together. Over a month of 730 hours that is 73 USD in standard
support and 438 in extended, and a year spent in extended support costs one cluster
0.50 × 730 × 12 = 4,380 USD more than upgrading would have.

What happens at month 14 is the cluster's **upgrade policy**. AWS's API reference gives the default
as `EXTENDED`: the cluster slides into extended support and its bill rises without anything
announcing it. `STANDARD` makes AWS upgrade the control plane at the end of standard support
instead. At the end of extended support, AWS upgrades it either way.

moto accepts the setting and keeps nothing of it, and it accepts versions AWS stopped offering long
ago:

```
ana@laptop:~/aws$ aws eks create-cluster --name shop-standard --kubernetes-version 1.35 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=$SUBNETS --upgrade-policy supportType=STANDARD --query 'cluster.[version,upgradePolicy]'
[
    "1.35",
    null
]
ana@laptop:~/aws$ aws eks create-cluster --name shop-old --kubernetes-version 1.10 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=$SUBNETS --query 'cluster.[version,status]'
[
    "1.10",
    "ACTIVE"
]
```

On AWS the second call is refused, because 1.10 is not a version EKS offers; the versions that are
offered on a given day, with their support dates, are what `aws eks describe-cluster-versions`
answers. **The 1.35 and 1.36 in this lesson are examples**, chosen to make the steps readable.

## The order

The upgrade itself is not something moto can show. The call answers 404, like the add-ons:

```
ana@laptop:~/aws$ aws eks update-cluster-version --name shop --kubernetes-version 1.36

aws: [ERROR]: An error occurred (404) when calling the UpdateClusterVersion operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

So the sequence below is AWS's documented one, and **none of it was run**. It starts with reading
and ends with the nodes:

1. **Read the upgrade insights.** `aws eks list-insights --cluster-name shop` reports what EKS
   found that would break on the next version, above all Kubernetes APIs your workloads still use
   and the next version removes.
2. **Upgrade the control plane by one minor version.**
   `aws eks update-cluster-version --name shop --kubernetes-version 1.36` returns an update id, and
   AWS documents that the cluster keeps serving while the update runs, usually for a few minutes.
3. **Upgrade the add-ons** to versions published for 1.36, with `describe-addon-versions` and
   `update-addon` from the previous section.
4. **Upgrade every node group**:
   `aws eks update-nodegroup-version --cluster-name shop --nodegroup-name general`. EKS launches
   nodes on the new image, drains the old ones, which moves their pods, and terminates them,
   `maxUnavailable` at a time.

Then the next version, if there is one to reach, from step 1 again. A cluster on 1.33 that has to
reach 1.36 does that three times.

Two rules make the order strict. **A node group has to be on the cluster's version before the
cluster can move again**: AWS's API reference refuses the next control plane upgrade while a
managed node group lags behind. And **nothing goes back**: neither a control plane nor a node group
can be returned to an earlier version. That is why the insights come first, and why a team that
can afford it upgrades a copy of the cluster before the real one.

## Draining is where it goes wrong

Step 4 moves every pod in the cluster at least once, and that is where an upgrade meets the
workloads. A pod is evicted from a node that is being replaced and started again elsewhere, so
**anything that cannot survive being restarted will notice**: a single replica, a pod that keeps
state on its node's disk, a service with no readiness check that receives traffic before it is
ready.

A **PodDisruptionBudget** is how a workload says how much of itself may be down at once, such as
"at least two of my three replicas". Draining respects it, and AWS documents that a managed node
group update fails rather than break one, unless it is forced. A budget that can never be met,
"at least three of my three", blocks every upgrade until somebody notices, and the clock in the
figure keeps running meanwhile.
