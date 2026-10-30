---
title: What Autopilot will not let you do
version: 1
---

Google takes over the nodes on one condition: **nothing you deploy may depend on the node being
yours.** So Autopilot refuses a set of things that are ordinary on Standard. Most teams never miss
them; a few workloads cannot run there at all, and it is better to find out before choosing.

## Node pools, as the provider sees them

Add a node pool to the Autopilot cluster of section 02, in a file `pool.tf` beside `main.tf`:

```hcl
# autopilot/pool.tf
resource "google_container_node_pool" "general" {
  name       = "general"
  cluster    = google_container_cluster.shop.id
  node_count = 1
}
```

Then validate and plan:

```
ana@laptop:~/gcp/autopilot$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/gcp/autopilot$ terraform plan -no-color | grep -E '^  #|^Plan'
  # google_container_cluster.shop will be created
  # google_container_node_pool.general will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

**Terraform has no objection.** The pool is a separate resource, and the provider cannot tell from
the pool alone that its cluster will be an Autopilot one. GKE would refuse it when Terraform tried
to create it, after the cluster existed. A setting on the cluster itself is another matter. Ask the
cluster to remove its default pool, a Standard idea, and the provider knows at once:

```
ana@laptop:~/gcp/autopilot$ sed -i 's/^  enable_autopilot    = true$/&\n  remove_default_node_pool = true/' main.tf
ana@laptop:~/gcp/autopilot$ terraform validate -no-color

Error: Conflicting configuration arguments

  with google_container_cluster.shop,
  on main.tf line 20, in resource "google_container_cluster" "shop":
  20:   remove_default_node_pool = true

"remove_default_node_pool": conflicts with enable_autopilot
```

Delete `pool.tf` and that line before going on. The lesson is the same as lesson 12's: the plan
catches the rules that live inside one resource and misses the ones that cross between them.

## What a pod may not ask for

These are refused when the pod is created, by the cluster's admission controls. None of them can
be shown here, because there is no cluster; they are Google's documented restrictions:

- **privileged containers** and most added Linux capabilities. Software that needs to load kernel
  modules or manage the host's network does not run;
- **host access**: `hostPath` volumes outside a few read-only paths, `hostNetwork`, `hostPort`
  for most uses;
- **SSH to a node**. There is no node you are allowed to log in to; debugging happens through
  `kubectl`, logs and the metrics the platform exports;
- **choosing a node by name** or anything that assumes a particular machine.

A DaemonSet is allowed, and billed like any other pod on every node it lands on, so a monitoring
agent that runs everywhere costs as many times over as there are nodes Google decides to run.

## How you still choose hardware

Not choosing a node does not mean not choosing hardware. A pod asks for what it needs, and
Autopilot picks a node to match:

- a **compute class**, by a node selector, for a different balance of processor and price, such
  as one for heavier CPU or for Arm;
- a **GPU**, by asking for it in the pod's resources, for the accelerator work lesson 2 describes;
- **Spot capacity**, by the selector `cloud.google.com/gke-spot: "true"`, for pods that can be
  interrupted.

That last one is how the shop's photo resizing gets Spot pricing on Autopilot without a pool of its
own: the same choice lesson 13 made with a tainted node pool, made per pod instead.
