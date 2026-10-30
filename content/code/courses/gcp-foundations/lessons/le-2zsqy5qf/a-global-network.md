---
title: One network, every region
version: 1
---

**A VPC network in Google Cloud is global: one network, in every region at once, with no address range of
its own.** The ranges belong to its **subnets**, and a subnet is regional: it covers every zone of one
region. Two machines in the same network, one in São Paulo and one in Santiago, reach each other on their
internal addresses with nothing in between to create, configure or pay for by the hour. The traffic is still
billed per crossing, at lesson 1's prices: the network being global changes what has to be built, not what
the bytes cost.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-global\" aria-label=\"The planner network drawn as one box that spans two regions. Inside it, the region southamerica-east1, São Paulo, holds the subnet planner-sao-paulo with range 10.10.0.0/20, and the subnet stretches across the three zones a, b and c. The region southamerica-west1, Santiago, holds planner-santiago with range 10.11.0.0/20, across its zones. A line between a machine in each subnet is labelled internal addresses, nothing to build in between, billed per crossing. Along the bottom: the network, its routes and its firewall rules are global; a subnet is regional; a machine is zonal.\"><defs><marker id=\"l15-global-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"16.0\" width=\"680.0\" height=\"226.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"40.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">network planner: global</text><text x=\"190.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">southamerica-east1</text><text x=\"190.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">São Paulo</text><rect x=\"40.0\" y=\"84.0\" width=\"300.0\" height=\"52.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"190.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planner-sao-paulo</text><text x=\"190.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">10.10.0.0/20</text><rect x=\"40.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"86.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone a</text><rect x=\"144.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"190.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone b</text><rect x=\"248.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"294.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone c</text><text x=\"190.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the subnet covers all three</text><text x=\"530.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">southamerica-west1</text><text x=\"530.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Santiago</text><rect x=\"380.0\" y=\"84.0\" width=\"300.0\" height=\"52.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"530.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planner-santiago</text><text x=\"530.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">10.11.0.0/20</text><rect x=\"380.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"426.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone a</text><rect x=\"484.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"530.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone b</text><rect x=\"588.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"634.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone c</text><text x=\"530.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the subnet covers all three</text><path d=\"M342.0 110.0 L378.0 110.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-global-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">global: the network, its routes, its firewall rules</text><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">regional: a subnet, across every zone of its region · zonal: a machine</text></svg>", "caption": "One network across regions; a subnet across the zones of one."}
```

Each kind of thing in the network has its own scope, and the scope is part of its address:

| resource | scope | example address |
|---|---|---|
| **network** | global | `projects/planner-dev/global/networks/planner` |
| **subnet** | one region | `projects/planner-dev/regions/southamerica-east1/subnetworks/planner-sao-paulo` |
| **firewall rule**, **route** | global, belonging to one network | lessons 16 and 17 |
| **machine** | one zone, with its interface in one subnet of that zone's region | the next course |

**A subnet is not a zone.** A machine in `southamerica-east1-a` and one in `southamerica-east1-c` can share a
subnet and its range; spreading machines across zones for resilience never means cutting more ranges.

## What the tools assume

A network can be made in two modes, the next section's subject: **auto**, in which Google creates a subnet in
every region, and **custom**, in which nothing exists until somebody writes it. Ask gcloud which it assumes:

```
ana@laptop:~/gcp$ gcloud compute networks create --help | grep -A1 "subnet-mode=MODE$"
     --subnet-mode=MODE
        The subnet mode of the network. If not specified, defaults to AUTO.
```

Terraform's provider assumes the same. Make a directory with lesson 2's provider file:

```sh
mkdir -p ~/gcp/network && cd ~/gcp/network
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save the shortest network there is as `network.tf`:

```hcl
resource "google_compute_network" "planner" {
  project = "planner-dev"
  name    = "planner"
}
```

```
ana@laptop:~/gcp/network$ terraform plan -input=false -no-color | grep -E "^Plan:|# google|auto_create|routing_mode|mtu"
  # google_compute_network.planner will be created
      + auto_create_subnetworks                   = true
      + mtu                                       = (known after apply)
      + routing_mode                              = (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Both default to auto mode.** A network written with nothing but a name gets a subnet in every region
Google runs, now and as new ones open. The next section says why the planner turns that off.

## Asking Google

The command that creates the network the planner wants, in custom mode with global routing, is short, and
it reaches Google:

```
ana@laptop:~/gcp$ gcloud compute networks create planner --subnet-mode=custom --bgp-routing-mode=global
ERROR: (gcloud.compute.networks.create) Could not fetch resource:
 - Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.
```

Refused, in Compute Engine's words, for the reason every call to Google in this course is refused: the lab
holds no credential. Everything else in this lesson is planned or computed on the laptop.
