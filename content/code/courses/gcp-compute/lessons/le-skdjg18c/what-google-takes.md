---
title: What Google takes over
version: 1
---

Lesson 13 ended with a cluster whose nodes are yours: their machine type, their count per zone,
their upgrades, the bill for every hour they exist. **Autopilot moves that line. Google runs the
nodes as well as the control plane, and you describe pods instead of machines.** You still write
Deployments and Services; what disappears is every decision lesson 13 asked about node pools.

## The same cluster, one line different

Create a folder `autopilot` in `~/gcp` and save this as `main.tf`:

```hcl
# autopilot/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_container_cluster" "shop" {
  name                = "shop-autopilot"
  location            = "southamerica-east1"
  enable_autopilot    = true
  deletion_protection = false

  release_channel {
    channel = "REGULAR"
  }
}
```

There is no node pool, no machine type and no maintenance of nodes in it. After `terraform init`,
the plan:

```
ana@laptop:~/gcp/autopilot$ terraform plan -no-color | grep -E '^  #|autopilot|\+ location|^Plan'
  # google_container_cluster.shop will be created
      + autopilot_privileged_admission           = (known after apply)
      + enable_autopilot                         = true
      + location                                 = "southamerica-east1"
      + name                                     = "shop-autopilot"
      + autopilot_cluster_policy_config (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

**`enable_autopilot = true` is the whole difference**, and the plan already carries attributes a
Standard cluster does not, such as `autopilot_cluster_policy_config`, known only after Google
creates the cluster. An Autopilot cluster is always regional, and it comes with Workload Identity,
the subject of lesson 15, switched on.

## The line, drawn

| | Standard | Autopilot |
|---|---|---|
| control plane | Google | Google |
| choosing machine types | you, per node pool | Google, from what the pods request |
| how many nodes | you, with autoscaling bounds | Google, as pods are scheduled |
| node upgrades and repairs | you set the strategy | Google |
| node security settings | you | Google, fixed and hardened |
| what you pay for | the nodes, whether full or empty | what the pods request, while they run |

Two rows matter most. **Google chooses and scales the nodes**, so there is nothing to size and
nothing left running empty overnight. And **you pay for pods rather than nodes**, so the shape of
the bill changes, which section 03 works through with numbers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two panels with the same five pods. On the left, Standard: three nodes, one in each zone, with the pods filling part of each node and the rest of each node marked as paid and empty; the bill is the three nodes. On the right, Autopilot: the same five pods with no node drawn around them; the bill is what the pods request.\"><defs><marker id=\"l14b-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"24\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard: you pay for the nodes</text><rect x=\"24\" y=\"44\" width=\"112\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zone a</text><rect x=\"34\" y=\"150\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"34\" y=\"114\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><text x=\"80\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">paid, empty</text><rect x=\"148\" y=\"44\" width=\"112\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"204\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zone b</text><rect x=\"158\" y=\"150\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"204\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"158\" y=\"114\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"204\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><text x=\"204\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">paid, empty</text><rect x=\"272\" y=\"44\" width=\"112\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"328\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zone c</text><rect x=\"282\" y=\"150\" width=\"92\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"328\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><text x=\"328\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">paid, empty</text><text x=\"24\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3 nodes, whatever they hold</text><text x=\"420\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Autopilot: you pay for the requests</text><rect x=\"420\" y=\"80\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"516\" y=\"80\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"558\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"612\" y=\"80\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"654\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"420\" y=\"130\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><rect x=\"516\" y=\"130\" width=\"84\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"558\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pod</text><text x=\"420\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5 pods, while they run</text></svg>", "caption": "The same pods, billed two ways. Standard charges for the boxes, full or not; Autopilot charges for what is inside them."}
```

## What you still own

Autopilot does not run your application for you. The Deployments, the replica counts, the
requests each container declares, the PodDisruptionBudgets that make an upgrade safe, the Services
and the Gateway that lesson 16 puts in front: all of that is the same work as on Standard. A pod
with one replica is still down while its node is replaced, and on Autopilot you have no say over
when that node is replaced beyond the cluster's maintenance window.

**The requests are the one part that becomes more important.** On Standard a request is a
scheduling hint and the bill is the nodes; on Autopilot the request is the bill. A container that
asks for two vCPU and uses a tenth of one costs two vCPU, every hour it runs.
