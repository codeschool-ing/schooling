---
title: What you give up, and when Standard is right
version: 1
---

Automatic is easy to read as Standard with the tedious parts done, a strict improvement that
costs nothing but a different SKU name. **Every preconfigured feature in this lesson is a decision
you can no longer make differently**, and most of what Automatic gives you is the absence of a
choice. For many clusters that is the whole value. For some it is a wall, and the wall is easier
to find before the cluster exists than after. This section is read from Microsoft's documentation,
on 30 October 2026, and nothing in it ran.

## The nodes are not yours to enter

On Standard, the nodes are virtual machines in your node resource group, and you can reach them:
by SSH with a key, by SSH through Entra ID, or with `kubectl debug node`. On Automatic, three
things close that door:

- the system nodes are in Microsoft's subscriptions, not yours. The documentation lists what
  AKS prevents there: changing anything in the namespaces AKS manages, `exec`, `attach` or
  `port-forward` into its system pods, labelling a node of yours as a system node, and running a
  pod of yours on a system node, even one with a broad toleration;
- the node resource group is locked. The documentation calls it fully managed: a deny
  assignment blocks changes to what AKS put there, so a role assignment on it, a disk resized by
  hand or a virtual network link to its private DNS zone is refused. Entra ID SSH to nodes is not
  supported on Automatic for that reason;
- the requirements for moving a Standard cluster to Automatic include **SSH access disabled on the
  system node pool.**

So when a node misbehaves, the tools are Kubernetes's: `kubectl describe node`, the events, the
logs Container insights collects. If your way of finding out why a process is slow has been to log
in to the machine and look, that habit has to change before the cluster does.

## Fewer knobs

Lesson 11 ended with a cluster of decisions: the tier, the channels, the pools, the surge. Here is
what an Automatic cluster lets you move and what it does not, as the documentation describes it:

| you can | you cannot |
|---|---|
| set a planned maintenance window | pick a tier other than Standard, so no Free tier and no Premium with long-term support |
| exclude namespaces from the safeguards | move the safeguards to `Warn`, or turn the baseline Pod Security Standard off |
| write NodePools and AKSNodeClasses of your own | create, upgrade or delete the managed system node pools, which `az aks nodepool list` does not even show |
| use your own virtual network instead of the managed one | stop the cluster at night, which node auto-provisioning does not allow |
| choose Azure Linux or Ubuntu for your nodes | run Windows nodes, or the Dapr and Azure Machine Learning extensions |

Two of those cost money in ways that are easy to miss. **A Standard cluster on the Free tier
costs nothing for its control plane**, and a development cluster that is stopped every evening
pays for its nodes only by day. An Automatic cluster can do neither: it is on the Standard tier,
charged per cluster and per hour, and it cannot be stopped. The price of the tier is on the AKS
pricing page and not in this course, as lesson 11 said.

The Dapr point matters to this course in particular. Lesson 9 ran the shop with Dapr in Container
Apps; the Dapr extension for AKS, which would bring the same sidecars to a cluster, is on the
documentation's list of extensions an Automatic cluster does not support.

## Where it runs, and the way back

Automatic is generally available in a list of regions, and the documentation gives it: 46 names,
`brazilsouth` among them, so the shop's region is covered. A region missing from the list is a
reason for Standard that no setting can fix.

Moving between the two SKUs is not symmetrical. **From Automatic to Standard is supported**: you
add a system pool of your own, because a Standard cluster has to run its system pods on your
machines, and change the SKU to `base`. None of this ran here:

```sh
az aks nodepool add --resource-group shop --cluster-name shop-auto --name systempool --mode System --node-count 3
az aks update --resource-group shop --name shop-auto --sku base
```

The other direction is harder. The migration guide describes moving a Standard cluster to
Automatic as a preview, behind a feature flag. It lists more than twenty settings the cluster must
have first, among them Azure CNI Overlay with Cilium, a managed NAT gateway, Azure Linux and an
ephemeral OS disk on the system pool, both upgrade channels as Automatic sets them, KEDA and node
resource group lockdown. The limitations list on the same documentation set still says the move
is not supported. Read those
two together as **"plan to create Automatic clusters new, and to leave them if you must"**, and
check the current guide on the day you need it.

## The cost model

What you pay for on Automatic, by the documentation's account:

- the Standard tier, per cluster and per hour;
- the nodes NAP creates, billed as the virtual machines of lessons 1 to 5, in your subscription;
- not the managed system nodes, which are not charged to your subscription;
- the usual extras: disks, load balancers, the NAT gateway, the monitoring data you keep.

The second line is where Automatic moves the decision rather than removing it. On Standard, you
chose `Standard_D4s_v5` and three of them, and the bill followed from that choice. On Automatic,
**the bill follows from the requests in your manifests**, because those are what NAP sizes
machines from, and consolidation packs pods by their requests, not by what they use. A team that
lets the mutator write 2 GiB on every container, or that copies a request from a tutorial, pays
for that number on every replica. The node size is still chosen, just by the person writing the
Deployment, often without knowing it.

## When Standard is right

Automatic is Microsoft's recommended default for production, and the documentation says so on
almost every page this lesson read. Standard is still the right answer when one of these is true:

- you need something Automatic does not run: Windows nodes, the Dapr extension, a region
  outside the list;
- you need a cluster to cost little when idle: a learning or development cluster on the Free
  tier, or one stopped outside working hours;
- you need a version for longer: long-term support needs the Premium tier, which Automatic
  does not offer, and Automatic follows the `stable` channel whether you like it or not;
- your workloads cannot meet the safeguards yet: a vendor's chart that pulls `latest`, a
  monitoring agent that needs the host's network. Excluding their namespace is possible, and is
  also the first step to having no safeguards worth the name;
- you tune the nodes: a fixed size because a licence is counted per core, a kernel setting
  applied by hand, a habit of logging in.

**And Automatic is right when none of those is true and the team is small.** The shop has three
developers, and no one of them wants to own node pools, surge settings and upgrade channels. Lesson
11's decisions were worth learning because they are what Automatic makes on your behalf; on most
days the shop is better served by not making them at all.
