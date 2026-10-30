---
title: Zones, public and private
version: 1
---

**Cloud DNS serves zones: a zone is the set of records for one domain name and everything under it**, kept by
Google and answered by Google's name servers. A **managed zone** is the Cloud DNS resource that holds one,
and it is one of two kinds:

| kind | who can ask it | what it is for |
|---|---|---|
| **public** | anybody on the internet | the names customers type: `planner.example.com`, `api.planner.example.com` |
| **private** | only machines in the VPC networks the zone lists | names that exist only inside: databases, internal services, and overrides of public names, lesson 17's `googleapis.com` |

A public zone does nothing until the world is told about it. When it is created, Google assigns it four name
servers, with names like `ns-cloud-a1.googledomains.com`, and **the domain's registrar has to be given those
four names**: that delegation is what sends a stranger's resolver to Google to ask about
`planner.example.com`. Until it is made, the zone exists and nobody asks it. It is a step outside Google
Cloud, at whichever company the domain was bought from, and it is the step people forget.

A private zone needs no delegation. Machines in the networks it names ask the **metadata server's resolver**,
at `169.254.169.254`, lesson 16's address that is always reachable, and that resolver knows the private zones
those networks may see.

## The planner's two zones

Zones are a shared service, so the planner keeps them in `planner-network` with the network itself. In
`~/gcp/dns-zones`, with lesson 2's provider file:

```sh
mkdir -p ~/gcp/dns-zones && cd ~/gcp/dns-zones
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `zones.tf`. Every name in Cloud DNS is written **fully qualified, with its final dot**:
`planner.example.com.` is the name; without the dot it would be a name relative to something.

```hcl
resource "google_dns_managed_zone" "public" {
  project  = "planner-network"
  name     = "planner-example-com"
  dns_name = "planner.example.com."

  dnssec_config {
    state = "on"
  }
}

resource "google_dns_managed_zone" "internal" {
  project    = "planner-network"
  name       = "planner-internal"
  dns_name   = "planner.internal."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = "projects/planner-network/global/networks/planner"
    }
  }
}
```

```
ana@laptop:~/gcp/dns-zones$ terraform plan -input=false -no-color | grep -E "^Plan|# google|dns_name|name_servers|visibility|state"
  # google_dns_managed_zone.internal will be created
      + dns_name         = "planner.internal."
      + name_servers     = (known after apply)
      + visibility       = "private"
      + private_visibility_config {
  # google_dns_managed_zone.public will be created
      + dns_name         = "planner.example.com."
      + name_servers     = (known after apply)
      + visibility       = "public"
          + state         = "on"
Plan: 2 to add, 0 to change, 0 to destroy.
```

**The name servers are *known after apply***: Google chooses them when the zone is made, and the registrar is
told them afterwards, which is why delegation is a step after the apply rather than part of it. `name` is
the resource's name in the project and `dns_name` the domain it serves; the two are different strings for
different readers.

**DNSSEC is on** for the public zone: Google signs its records, so a resolver that checks signatures can tell
a real answer from a forged one. Switching it on in Cloud DNS is half of the work; the other half is a `DS`
record that the registrar publishes in the parent zone, and until that is done the signatures are made and
nobody checks them.

The private zone uses `.internal`, a top-level name set aside in 2024 for exactly this, private names that
will never exist on the internet, so a name in it can never collide with somebody's public one.
