---
title: Cloud NAT: out, and never in
version: 1
---

**A machine with no external address can reach the internet only through Cloud NAT**, and through Cloud NAT
it can only start connections, never accept them. That asymmetry is the point. The planner's application
servers download packages and call a payment provider; nobody on the internet has any reason to open a
connection to them, and with no external address and no inbound path, nobody can.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l17-ways-out\" aria-label=\"A machine in the São Paulo subnet with only an internal address, 10.10.0.5. All its traffic out leaves by the default internet gateway route. Towards the internet, it passes through Cloud NAT, configured on a Cloud Router in the region, which lets the machine start connections and gives the replies back. Towards Google's APIs, such as Cloud Storage, Private Google Access on the subnet lets it through without NAT. A connection started from the internet towards the machine is drawn crossed out: there is no path in.\"><defs><marker id=\"l17-ways-out-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-ways-out-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"230.0\" height=\"190.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planner-sao-paulo</text><text x=\"135.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Private Google Access: on</text><rect x=\"55.0\" y=\"110.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a machine</text><text x=\"135.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.10.0.5</text><text x=\"135.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no external address</text><rect x=\"320.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"395.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Cloud NAT</text><text x=\"395.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">on a Cloud Router</text><rect x=\"540.0\" y=\"40.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the internet</text><rect x=\"540.0\" y=\"150.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Google's APIs</text><text x=\"620.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">storage.googleapis.com</text><path d=\"M252.0 112.0 L316.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l17-ways-out-af-ah-amber)\"></path><path d=\"M472.0 70.0 L536.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l17-ways-out-af-ah-amber)\"></path><text x=\"505.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">out, and replies back</text><path d=\"M252.0 160.0 L536.0 180.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l17-ways-out-af-ah-phosphor)\"></path><text x=\"380.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">no NAT needed</text><path d=\"M620 102 L620 112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"620.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in: no path</text><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every way out leaves by the default internet gateway route</text></svg>", "caption": "NAT for the internet, Private Google Access for Google; nothing comes in."}
```

Cloud NAT is not a machine either. There is no instance to size, patch or make redundant: it is a
configuration on a **Cloud Router** in one region, and Google's network translates the addresses of the
packets that leave by the **default internet gateway** route. Two consequences follow from that sentence:

- **it is regional**: a NAT in São Paulo serves the São Paulo subnets, and Santiago needs its own;
- **it needs the default route.** A network that deleted it, as the previous section did, has nothing for
  NAT to translate. That is the planner's production: no default route, no NAT, and nothing from outside but
  Google's own APIs, the next section's subject. The development and staging networks keep both.

## Writing one

In `~/gcp/nat`, with lesson 2's provider file:

```sh
mkdir -p ~/gcp/nat && cd ~/gcp/nat
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `nat.tf`. The route at the end is the one for Google's private API range from the previous
section, written as Terraform:

```hcl
resource "google_compute_router" "sao_paulo" {
  project = "planner-dev"
  name    = "planner-sao-paulo"
  network = "planner"
  region  = "southamerica-east1"
}

resource "google_compute_router_nat" "sao_paulo" {
  project                            = "planner-dev"
  name                               = "planner-sao-paulo"
  router                             = google_compute_router.sao_paulo.name
  region                             = "southamerica-east1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_route" "private_google" {
  project          = "planner-dev"
  name             = "private-googleapis"
  network          = "planner"
  dest_range       = "199.36.153.8/30"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}
```

```
ana@laptop:~/gcp/nat$ terraform plan -input=false -no-color | grep -E "^Plan|# google|min_ports|nat_ip_allocate|dest_range|next_hop_gateway|enable_endpoint|udp_idle|tcp_established"
  # google_compute_route.private_google will be created
      + dest_range                 = "199.36.153.8/30"
      + next_hop_gateway           = "default-internet-gateway"
  # google_compute_router.sao_paulo will be created
  # google_compute_router_nat.sao_paulo will be created
      + enable_endpoint_independent_mapping = (known after apply)
      + min_ports_per_vm                    = (known after apply)
      + nat_ip_allocate_option              = "AUTO_ONLY"
      + tcp_established_idle_timeout_sec    = 1200
      + udp_idle_timeout_sec                = 30
Plan: 3 to add, 0 to change, 0 to destroy.
```

Three resources, planned and not created. **`AUTO_ONLY`** lets Google choose the NAT's external addresses and
add more as they are needed; the alternative, `MANUAL_ONLY`, names reserved addresses, which is what a
company does when a partner allows calls only from a fixed list. The timeouts came back from the provider's
own defaults, 30 seconds for an idle UDP mapping and 1200 for an established TCP connection; the ports each
machine may use are Google's to fill in. **Logging only errors** records the moment NAT runs out of ports for
a machine, which is the failure a NAT has, and not every connection, which would be a bill of its own.

## What it costs

The Cloud NAT pricing page, read on 30 October 2026, prices a public NAT gateway in three parts, the same in
every region:

| part | price |
|---|---|
| the gateway | 0.0014 USD an hour for each machine using it, up to 32 machines; 0.044 an hour above that |
| data processed | 0.045 USD per GiB, in both directions |
| each external address it uses | 0.005 USD an hour |

**The processing charge is the one that grows.** Ten machines all month cost about 10 dollars for the
gateway and under 4 for one address; a terabyte of package downloads through it costs about 46 dollars of
processing, on top of whatever the traffic itself costs. A machine that pulls a large container image every
time it starts can make NAT the largest line of a small project's bill, which is the first thing to look for
when lesson 13's list leads to the networking SKUs.
