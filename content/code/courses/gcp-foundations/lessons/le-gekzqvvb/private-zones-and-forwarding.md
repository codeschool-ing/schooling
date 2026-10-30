---
title: Private zones, overrides and forwarding
version: 1
---

**A private zone answers only the networks it lists, and for them it wins over the internet.** That second
half is what makes private zones useful beyond internal names: a private zone for a public domain overrides
the public answer, for those networks and nobody else. It is how lesson 17's production network sends every
call to `*.googleapis.com` to the private range.

## The override lesson 17 promised

Save this as `googleapis.tf` in `~/gcp/dns-zones`, beside the zones of the first section:

```hcl
resource "google_dns_managed_zone" "googleapis" {
  project    = "planner-network"
  name       = "googleapis"
  dns_name   = "googleapis.com."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = "projects/planner-network/global/networks/planner"
    }
  }
}

resource "google_dns_record_set" "private_a" {
  project      = "planner-network"
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "private.googleapis.com."
  type         = "A"
  ttl          = 300
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
}

resource "google_dns_record_set" "everything_else" {
  project      = "planner-network"
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["private.googleapis.com."]
}
```

The four addresses are the ones `getent` returned in lesson 17. The wildcard says that **any other name in
`googleapis.com` is `private.googleapis.com`**, so `storage.googleapis.com`, asked from the planner network,
comes back as one of the four private addresses, while the same question asked anywhere else gets Google's
public answer. The real one, from the laptop:

```
ana@laptop:~/gcp/dns-zones$ getent hosts storage.googleapis.com | head -3
74.125.201.207  storage.googleapis.com
192.178.209.207 storage.googleapis.com
74.125.69.207   storage.googleapis.com
```

**Public addresses**, because the laptop is not in the planner network and no private zone applies to it.
From a machine in that network, after an apply, the same command would print one of `199.36.153.8` to
`.11`; that was not run here.

## Forwarding to the office

The office has its own DNS server, at `192.168.0.53`, which knows the names of the office's machines under
`office.planner.internal`. A **forwarding zone** is a private zone that answers by asking somebody else: Cloud
DNS sends questions for that name to the office server, over the VPN of lesson 21, and returns what it says.
Add to `googleapis.tf`:

```hcl
resource "google_dns_managed_zone" "office" {
  project    = "planner-network"
  name       = "office"
  dns_name   = "office.planner.internal."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = "projects/planner-network/global/networks/planner"
    }
  }

  forwarding_config {
    target_name_servers {
      ipv4_address = "192.168.0.53"
    }
  }
}
```

```
ana@laptop:~/gcp/dns-zones$ terraform plan -input=false -no-color | grep -E "^Plan|# google|dns_name|ipv4_address"
  # google_dns_managed_zone.googleapis will be created
      + dns_name         = "googleapis.com."
  # google_dns_managed_zone.internal will be created
      + dns_name         = "planner.internal."
  # google_dns_managed_zone.office will be created
      + dns_name         = "office.planner.internal."
              + ipv4_address    = "192.168.0.53"
  # google_dns_managed_zone.public will be created
      + dns_name         = "planner.example.com."
  # google_dns_record_set.everything_else will be created
  # google_dns_record_set.private_a will be created
Plan: 6 to add, 0 to change, 0 to destroy.
```

Six resources: the two zones of the first section, the override and its two record sets, and the forwarding
zone. The other direction, the office asking Cloud DNS about `planner.internal`, needs a **DNS server policy**
with inbound forwarding on the planner network, which gives Cloud DNS an address in each region's subnet for
the office server to forward to.

## Who answers what

A machine in the planner network asks the metadata server's resolver, and it answers in this order:

1. a private zone, forwarding zone or peering zone visible to the network, the **most specific** name first:
   `office.planner.internal.` before `planner.internal.`;
2. the internal names Compute Engine gives every machine, `NAME.ZONE.c.PROJECT.internal`;
3. the internet's public DNS.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l19-order\" aria-label=\"A machine in the planner network asks the metadata server's resolver at 169.254.169.254 for a name. The resolver tries three places in order and stops at the first that holds the name. First, the private zones the network may see, the most specific first: office.planner.internal is forwarded to the office server at 192.168.0.53, planner.internal is answered by Cloud DNS, and googleapis.com is the override that sends every API to the private range. Second, the internal names Compute Engine gives machines. Third, public DNS on the internet. A note says that a private zone takes its whole domain: a name missing from it is answered as not existing, and the internet is never asked.\"><defs><marker id=\"l19-order-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"100.0\" width=\"170.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a machine asks</text><text x=\"105.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">169.254.169.254</text><rect x=\"260.0\" y=\"20.0\" width=\"440.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"276.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1. private zones, most specific first</text><text x=\"276.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">office.planner.internal.</text><text x=\"684.0\" y=\"64.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">forwarded to 192.168.0.53</text><text x=\"276.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner.internal.</text><text x=\"684.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">answered by Cloud DNS</text><text x=\"276.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">googleapis.com.</text><text x=\"684.0\" y=\"116.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">override: the private range</text><rect x=\"260.0\" y=\"156.0\" width=\"440.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. internal names of machines</text><text x=\"684.0\" y=\"173.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">NAME.ZONE.c.PROJECT.internal</text><rect x=\"260.0\" y=\"206.0\" width=\"440.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. public DNS</text><path d=\"M192.0 120.0 L256.0 80.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l19-order-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the first place that holds the domain answers, even with no such name</text></svg>", "caption": "A private zone is asked first, and takes its whole domain."}
```

**The first match is final.** If the private zone for `googleapis.com` has no record for a name and no
wildcard, the answer is *no such name*, not the public answer: a private zone for a domain takes the whole
domain. That is why the override needs its wildcard, and why a private zone for a domain the company does not
own is a decision to read carefully.
