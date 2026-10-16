---
title: Cluster Autoscaler or Karpenter
version: 1
---

Both answer the same event, a pod that stays `Pending` because no node has room for it. **They
differ in what they are allowed to change.** Cluster Autoscaler changes the desired count of a node
group you defined in advance. Karpenter chooses the machine. Everything else about the two follows
from that one difference:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two loops from a pending pod to a running one. Cluster Autoscaler asks which node group could fit the pod, raises that Auto Scaling group's desired count, and the group launches its one instance type, an m7i.2xlarge. Karpenter reads the pod's requests and requirements, calls EC2 CreateFleet with a list of types, and gets the cheapest that fits, a c7g.large. Both end with the node joining and the pod scheduled.\"><defs><marker id=\"k8s-loops-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"12\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">Cluster Autoscaler</text><rect x=\"12\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a pod is Pending</text><text x=\"76.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing has room</text><path d=\"M140 86 L152 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"154\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"218.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">which group</text><text x=\"218.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">would fit it?</text><path d=\"M282 86 L294 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"296\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its Auto Scaling</text><text x=\"360.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">group: desired + 1</text><path d=\"M424 86 L436 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"438\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"502.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the group's one type</text><text x=\"502.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">m7i.2xlarge</text><path d=\"M566 86 L578 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"580\" y=\"54\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"644.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the node joins,</text><text x=\"644.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the pod is scheduled</text><text x=\"12\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Karpenter</text><rect x=\"12\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a pod is Pending</text><text x=\"76.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing has room</text><path d=\"M140 216 L152 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"154\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"218.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reads the pod:</text><text x=\"218.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">requests, requirements</text><path d=\"M282 216 L294 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"296\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EC2 CreateFleet</text><text x=\"360.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">with a list of types</text><path d=\"M424 216 L436 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"438\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"502.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the cheapest that fits</text><text x=\"502.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c7g.large</text><path d=\"M566 216 L578 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#k8s-loops-ah)\"></path><rect x=\"580\" y=\"184\" width=\"128\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"644.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the node joins,</text><text x=\"644.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the pod is scheduled</text></svg>", "caption": "The same pending pod, two loops. Cluster Autoscaler changes a number on a group you defined in advance; Karpenter chooses the machine for the pods it is looking at, and talks to EC2 directly."}
```

## The Cluster Autoscaler loop

Cluster Autoscaler is the Kubernetes project's own autoscaler, and it works with node groups on
every cloud that has them. When pods are pending, it simulates the scheduler against each node
group's instance type and picks a group whose new node would hold them. Then it raises that Auto
Scaling group's desired count by as many nodes as are needed. The group launches **its own type**,
the node joins, and the scheduler places the pods. When a node has been underused for a while and its
pods would fit elsewhere, it lowers the count again and the node is drained and removed.

That design has two consequences. **The shapes are yours to anticipate**: a pod that needs 30 GiB in
a cluster whose only group is `m7g.large` stays pending for ever. The usual answer is a second
group for big pods, then a third for Arm, then one for spot. And the machine is the group's, even
when the pending pods are small: one tiny pod in a group of `m7i.2xlarge` gets a whole
`m7i.2xlarge`.

## The Karpenter loop

Karpenter reads the pending pods' requests and their requirements, such as the architecture, the
zone or spot against on-demand. It intersects those with the NodePool's range and asks EC2 for the
cheapest machine that holds them, through the `CreateFleet` call of the previous section. A node
group with its fixed type never enters the loop. Later, consolidation keeps asking whether the same
pods would fit on fewer or cheaper machines.

## What the difference is worth

Three pending pods ask for 1.5 vCPU and 3 GiB between them. Cluster Autoscaler, with a group of
`m7i.2xlarge`, adds one of those. Karpenter, with the NodePool of the previous section, can add a
`c7g.large`, two Arm vCPUs and 4 GiB. Both prices are lines of the sheet of lesson 1, as published on
16 October 2026, and are in the capture of the first section: `m7i.2xlarge` at 0.6426 USD an hour
and `c7g.large` at 0.1111. **The difference is 0.5315 USD an hour, or about 388 USD a month of
730 hours, for one node.** The arithmetic leaves out what every node also carries, the DaemonSets of
lesson 11 among them, and it assumes the pods' images run on Arm. The second is a real condition:
an image built only for x86, as lesson 10's was, cannot use the `c7g` at all, and the NodePool would
have to allow x86 types too.

## Choosing

| | Cluster Autoscaler | Karpenter |
|---|---|---|
| what it changes | the desired count of your node groups | which instances exist |
| instance types | one per group, chosen in advance | a range, chosen per batch of pods |
| removing nodes | nearly empty nodes | empty nodes, and nodes it can pack better |
| where it works | every cloud with node groups | AWS, and other providers that have written support |
| what you manage | the groups, one per shape | NodePools, an EC2NodeClass, an SQS queue for interruptions |

**Karpenter is the better fit for clusters whose pods vary**: batch jobs of different sizes, a mix of
Arm and x86, heavy use of spot. Cluster Autoscaler still fits a cluster with a few stable kinds of
workload, and a team that wants every machine to come from a group it can read in one place. It is
also the one that works the same way on another cloud. The two should not manage the same nodes:
pick one per group of capacity.

And Fargate, the first section's answer, belongs beside both. It removes nodes from the question
altogether for the pods a profile selects, at the price of the restrictions listed there and of
paying for every pod's requests.
