---
title: Release channels and how nodes are upgraded
version: 1
---

The common belief about a managed cluster is that upgrades are Google's problem. Half of that is
true. **Google upgrades the control plane on its own schedule; the nodes are upgraded on the same
schedule but in your cluster, with your pods on them, and how that goes is set by you.** A team
that never looks at the second half finds out about it the morning a node drains under a service
with one replica.

## Release channels

A cluster on a release channel is upgraded automatically, both control plane and nodes, to
versions Google has promoted on that channel. The provider names the channels in the refusal you
get for writing one that does not exist:

```
ana@laptop:~/gcp/gke$ sed -i 's/"REGULAR"/"WEEKLY"/' main.tf
ana@laptop:~/gcp/gke$ terraform validate -no-color

Error: expected release_channel.0.channel to be one of ["UNSPECIFIED" "RAPID" "REGULAR" "STABLE" "EXTENDED"], got WEEKLY

  with google_container_cluster.shop,
  on main.tf line 22, in resource "google_container_cluster" "shop":
  22:     channel = "WEEKLY"
```

- **`RAPID`** gets new Kubernetes versions first, weeks after they are released upstream. It is
  for trying what is coming, not for production.
- **`REGULAR`** is the default and the usual choice: versions arrive after they have spent time on
  Rapid.
- **`STABLE`** waits longer again, for teams that value proven versions over new features.
- **`EXTENDED`** lets a cluster stay on a minor version past its standard support. Google's
  pricing page states that an extra management fee applies while the version is in that extended
  period, so it buys time at a price.

`UNSPECIFIED` means no channel, and versions managed by hand. It is still accepted and it is the
path Google discourages: a cluster nobody upgrades eventually reaches the end of support, and GKE
then upgrades it anyway, at a moment nobody chose.

The order is always the same: **the control plane first, then the node pools**, because the API
server supports nodes up to some minor versions behind it and never ahead.

## What happens to a node

Upgrading a node means replacing it. GKE creates a node at the new version, then **cordons and
drains** an old one: no new pods are scheduled there, and the pods running there are evicted and
rescheduled elsewhere, respecting each workload's PodDisruptionBudget. How many nodes are replaced
at once is the pool's `upgrade_settings`, and the strategy is one of the values the provider knows:

```
ana@laptop:~/gcp/gke$ sed -i 's/"SURGE"/"ROLLING"/' pool.tf
ana@laptop:~/gcp/gke$ terraform validate -no-color

Error: expected upgrade_settings.0.strategy to be one of ["SURGE" "BLUE_GREEN" "SHORT_LIVED"], got ROLLING

  with google_container_node_pool.general,
  on pool.tf line 19, in resource "google_container_node_pool" "general":
  19:     strategy        = "ROLLING"
```

**`SURGE`**, the default, works in small steps:

- `max_surge` is how many extra nodes GKE may add during the upgrade. With `1`, the pool briefly
  has one node more than usual, and you pay for it while it exists;
- `max_unavailable` is how many nodes may be missing at once. With `0`, capacity never drops below
  the normal count, at the cost of a slower upgrade.

The shop's `1` and `0` is the cautious setting: one node at a time, capacity never down.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"A surge upgrade of a three-node pool with max_surge 1 and max_unavailable 0, as five rows. At the start, three old nodes. Then a fourth node at the new version is added. Then one old node is cordoned and drained while the other three keep serving. The same two steps repeat, and at the end the pool has three new nodes. The pool never has fewer than three nodes ready and never more than four.\"><defs><marker id=\"l13s-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"24\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">start</text><rect x=\"200\" y=\"20\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><rect x=\"324\" y=\"20\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><rect x=\"448\" y=\"20\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><text x=\"24\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">add one new node</text><rect x=\"200\" y=\"76\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><rect x=\"324\" y=\"76\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><rect x=\"448\" y=\"76\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><rect x=\"572\" y=\"76\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">new version</text><text x=\"24\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">drain one old node</text><rect x=\"200\" y=\"132\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"254\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">draining</text><rect x=\"324\" y=\"132\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><rect x=\"448\" y=\"132\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><rect x=\"572\" y=\"132\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">new version</text><text x=\"24\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the same, twice more</text><rect x=\"200\" y=\"188\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">new version</text><rect x=\"324\" y=\"188\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><rect x=\"448\" y=\"188\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old version</text><rect x=\"572\" y=\"188\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">new version</text><text x=\"24\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">end</text><rect x=\"200\" y=\"244\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">new version</text><rect x=\"324\" y=\"244\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">new version</text><rect x=\"448\" y=\"244\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">new version</text></svg>", "caption": "With max_surge 1 and max_unavailable 0 the pool trades speed for capacity: one extra node at a time, paid for while it exists, and never fewer nodes ready than usual."}
```

The provider also knows a third, `SHORT_LIVED`, which is newer than this lesson and outside it.

**`BLUE_GREEN`** creates a complete second set of nodes at the new version, moves the pods across
in batches, and keeps the old set for a soak period during which you can roll back. It is safer
and it doubles the pool's machines for the length of the upgrade, so it suits a small pool running
something that must not misbehave, and not a large one on a budget.

## What makes an upgrade go badly

The drain is the moment that hurts, and almost never because of GKE. A Deployment with one replica
is down while its pod is rescheduled. A pod with no PodDisruptionBudget can be evicted alongside
its siblings. A pod that ignores SIGTERM is killed when its grace period ends, mid-request. None of
that shows during the months between upgrades, which is why the setting that matters most is the
next section's: when they are allowed to happen at all.

None of this was run here. What the lab checked is that the channel and the strategy you wrote are
ones the provider accepts; the upgrade itself is described from Google's documentation.
