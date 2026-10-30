---
title: HA VPN, two tunnels and a router
version: 1
---

**Cloud VPN joins a VPC network to another network over the internet, through encrypted IPsec tunnels.** The
other end is usually an office or a datacentre, sometimes another cloud. It is the cheap way in: no circuit to
order, no colocation, running within an hour of deciding to, over whatever internet connection the office
already has.

There are two kinds, and only one is worth building now:

| | HA VPN | Classic VPN |
|---|---|---|
| gateway | **two interfaces, two external addresses**, in one region | one interface |
| routing | **dynamic only, over BGP**, with a Cloud Router | static or dynamic |
| availability Google offers | **99.99%**, with two tunnels set up as Google describes | 99.9% |

An HA VPN gateway has two interfaces so that one can fail, or be maintained by Google, while the other
carries the traffic. The design that earns the 99.99% has **a tunnel from each interface**, to two addresses
on the office's router, or to two routers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l21-ha-vpn\" aria-label=\"The planner's HA VPN. On the left, in southamerica-east1, an HA VPN gateway with two interfaces, 0 and 1, and a Cloud Router with ASN 64514. On the right, the office router with two public addresses, 198.51.100.10 and 198.51.100.11, and ASN 65010. Two encrypted tunnels cross the internet, one from each interface to one address. Inside each tunnel runs a BGP session on link-local addresses, 169.254.0.1 to .2 and 169.254.1.1 to .2. Over BGP, the Cloud Router announces the planner's subnets, 10.10.0.0/16 and 10.11.0.0/16, and learns the office's 192.168.0.0/16.\"><rect x=\"20.0\" y=\"30.0\" width=\"220.0\" height=\"190.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">southamerica-east1</text><rect x=\"40.0\" y=\"64.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HA VPN gateway</text><text x=\"70.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">if 0</text><text x=\"190.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">if 1</text><rect x=\"40.0\" y=\"150.0\" width=\"180.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud Router</text><text x=\"130.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">ASN 64514</text><rect x=\"480.0\" y=\"64.0\" width=\"220.0\" height=\"138.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">office router</text><text x=\"590.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">198.51.100.10</text><text x=\"590.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">198.51.100.11</text><text x=\"590.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">ASN 65010</text><text x=\"590.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><path d=\"M242.0 90.0 L478.0 104.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M242.0 120.0 L478.0 122.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">tunnel 0: BGP 169.254.0.1 – .2</text><text x=\"360.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">tunnel 1: BGP 169.254.1.1 – .2</text><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">announced: 10.10.0.0/16, 10.11.0.0/16 · learned: 192.168.0.0/16</text><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">either tunnel can carry everything; that is the 99.99%</text></svg>", "caption": "Two interfaces, two tunnels, BGP in each: no route written by hand."}
```

## BGP, and why the routes are not written by hand

HA VPN does not take static routes. A **Cloud Router** speaks BGP with the office's router over each tunnel:
it tells the office the planner's subnet ranges, and learns the office's, `192.168.0.0/16`, which appear in
the planner network as the **dynamic routes** of lesson 17. A new subnet on either side is announced without
anybody writing a route, and when a tunnel goes down its routes are withdrawn and traffic moves to the other.
The network's **global routing mode**, lesson 15, is what lets a route learned by the router in São Paulo be
used by machines in Santiago too.

Each BGP session needs two things the file below spells out: an **ASN** for each side, from the ranges set
aside for private use, and a pair of addresses inside the tunnel from **`169.254.0.0/16`**, the link-local
range, one `/30` per tunnel.

## The planner's office link, written

In `~/gcp/vpn`, with lesson 2's provider file:

```sh
mkdir -p ~/gcp/vpn && cd ~/gcp/vpn
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `vpn.tf`. The office's router has two public addresses, written here from `198.51.100.0/24`, a
documentation range; `count = 2` makes two of each resource that comes in pairs:

```hcl
variable "shared_secret" {
  type      = string
  sensitive = true
}

resource "google_compute_ha_vpn_gateway" "office" {
  project = "planner-network"
  name    = "planner-office"
  network = "planner"
  region  = "southamerica-east1"
}

resource "google_compute_external_vpn_gateway" "office" {
  project         = "planner-network"
  name            = "office-router"
  redundancy_type = "TWO_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = "198.51.100.10"
  }
  interface {
    id         = 1
    ip_address = "198.51.100.11"
  }
}

resource "google_compute_router" "office" {
  project = "planner-network"
  name    = "planner-office"
  network = "planner"
  region  = "southamerica-east1"

  bgp {
    asn = 64514
  }
}

resource "google_compute_vpn_tunnel" "office" {
  count                           = 2
  project                         = "planner-network"
  name                            = "planner-office-${count.index}"
  region                          = "southamerica-east1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.office.id
  vpn_gateway_interface           = count.index
  peer_external_gateway           = google_compute_external_vpn_gateway.office.id
  peer_external_gateway_interface = count.index
  router                          = google_compute_router.office.id
  shared_secret                   = var.shared_secret
  ike_version                     = 2
}

resource "google_compute_router_interface" "office" {
  count      = 2
  project    = "planner-network"
  name       = "office-${count.index}"
  router     = google_compute_router.office.name
  region     = "southamerica-east1"
  ip_range   = "169.254.${count.index}.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.office[count.index].name
}

resource "google_compute_router_peer" "office" {
  count           = 2
  project         = "planner-network"
  name            = "office-${count.index}"
  router          = google_compute_router.office.name
  region          = "southamerica-east1"
  interface       = google_compute_router_interface.office[count.index].name
  peer_ip_address = "169.254.${count.index}.2"
  peer_asn        = 65010
}
```

```
ana@laptop:~/gcp/vpn$ terraform plan -input=false -no-color 2>&1 | tail -5
   1: variable "shared_secret" {

The root module input variable "shared_secret" is not set, and has no default
value. Use a -var or -var-file command line argument to provide a value for
this variable.
```

**The file has no secret in it, and Terraform refuses to guess one.** The pre-shared key both ends of a tunnel
must agree on is a variable, marked sensitive, and it comes from outside the file: an environment variable
here, a secret manager in a pipeline. Give it one that is plainly not a key:

```
ana@laptop:~/gcp/vpn$ TF_VAR_shared_secret=placeholder-only terraform plan -input=false -no-color | grep -E "^Plan|# google|shared_secret|ip_range|peer_asn|asn "
  # google_compute_external_vpn_gateway.office will be created
  # google_compute_ha_vpn_gateway.office will be created
  # google_compute_router.office will be created
          + asn                = 64514
  # google_compute_router_interface.office[0] will be created
      + ip_range            = "169.254.0.1/30"
  # google_compute_router_interface.office[1] will be created
      + ip_range            = "169.254.1.1/30"
  # google_compute_router_peer.office[0] will be created
      + peer_asn                           = 65010
  # google_compute_router_peer.office[1] will be created
      + peer_asn                           = 65010
  # google_compute_vpn_tunnel.office[0] will be created
      + shared_secret                   = (sensitive value)
      + shared_secret_hash              = (known after apply)
      + shared_secret_wo                = (write-only attribute)
  # google_compute_vpn_tunnel.office[1] will be created
      + shared_secret                   = (sensitive value)
      + shared_secret_hash              = (known after apply)
      + shared_secret_wo                = (write-only attribute)
Plan: 9 to add, 0 to change, 0 to destroy.
```

Nine resources. The secret is shown as *(sensitive value)*, and the router's ASN, 64514, and the office's,
65010, are both private ones. **Sensitive is not secret**: Terraform hides the value on the screen and still
writes it into its state file, which is why the provider also offers `shared_secret_wo`, a write-only
attribute that is sent to Google and never stored, and why a state file is guarded like the keys it may hold.

An ASN outside the private ranges is refused before anything is asked. Change the router's to 100 and plan:

```
ana@laptop:~/gcp/vpn$ sed -i 's/asn = 64514/asn = 100/' vpn.tf
ana@laptop:~/gcp/vpn$ TF_VAR_shared_secret=placeholder-only terraform plan -input=false -no-color 2>&1 | grep -A1 "^Error"
Error: expected "bgp.0.asn" to be a RFC6996-compliant Local ASN:
must be either in the private ASN ranges: [64512..65534], [4200000000..4294967294];
```

The provider names the ranges in its refusal. Put 64514 back before moving on.
