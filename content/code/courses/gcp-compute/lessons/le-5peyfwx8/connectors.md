---
title: Serverless VPC Access connectors
version: 1
---

Before direct egress existed, the only way from Cloud Run into a VPC was a **connector**: a small
managed group of virtual machines in your network, in a `/28` of their own, that receive the
service's outbound traffic and forward it. Connectors still work, many services still use them,
and a few situations still need one. **The difference that decides most cases is that a connector
is machines, and machines are billed whether or not anything goes through them.**

## Writing one down

Create a folder `run-connector` in `~/gcp` with this `main.tf`. The connector is its own resource,
and the service names it instead of a network interface:

```hcl
# run-connector/main.tf
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

resource "google_vpc_access_connector" "shop" {
  name          = "shop-connector"
  region        = "southamerica-east1"
  network       = "shop"
  ip_cidr_range = "10.8.0.0/28"
  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 3
}

resource "google_cloud_run_v2_service" "orders" {
  name     = "orders"
  location = "southamerica-east1"

  template {
    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1.0.0"
    }

    vpc_access {
      connector = google_vpc_access_connector.shop.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }
}
```

After `terraform init`, the plan:

```
ana@laptop:~/gcp/run-connector$ terraform plan -no-color | grep -E '^  #|connector|egress|machine_type|instances|ip_cidr|^Plan'
  # google_cloud_run_v2_service.orders will be created
              + connector = (known after apply)
              + egress    = "PRIVATE_RANGES_ONLY"
  # google_vpc_access_connector.shop will be created
  + resource "google_vpc_access_connector" "shop" {
      + ip_cidr_range      = "10.8.0.0/28"
      + machine_type       = "e2-micro"
      + max_instances      = 3
      + min_instances      = 2
      + name               = "shop-connector"
Plan: 2 to add, 0 to change, 0 to destroy.
```

**The connector is two to three `e2-micro` machines**, and the plan says so in the same words you
wrote. `ip_cidr_range` is a `/28`, sixteen addresses, that must not overlap anything else in the
VPC. The connector never scales below `min_instances`, so its floor is a standing cost:

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E 'per hour|e2-micro'
                                    per hour   per month   Spot/hour
  e2-micro        2 vCPU   1 GiB   0.008376428        6.11           -
```

Two machines at 6.11 a month each are about 12 dollars a month before any traffic, for a
connector that might carry nothing at night. That is Compute Engine's list price for the machine
type, which is how Google bills a connector's instances. A bigger `machine_type` buys more
throughput and multiplies the floor; a connector also **scales out under load and does not scale
back in by itself**, so after a burst it can stay at its maximum until somebody notices.

## One or the other

A revision uses a connector or network interfaces, never both. Put a `network_interfaces` block
back beside `connector` and see who notices:

```
ana@laptop:~/gcp/run-connector$ sed -i 's/^      connector = .*/&\n      network_interfaces {\n        network = "shop"\n      }/' main.tf
ana@laptop:~/gcp/run-connector$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/gcp/run-connector$ terraform plan -no-color | grep -E 'Error|conflicts|^Plan'
Plan: 2 to add, 0 to change, 0 to destroy.
```

**Nobody did.** The provider has the rule, but it can only apply it to values it knows, and
`google_vpc_access_connector.shop.id` is unknown until the connector exists. Terraform cannot
compare an unknown value with anything, so the plan goes through, and the refusal would come from
Cloud Run when the revision is created. Write the connector's id as a literal string and the same
rule fires at once:

```
ana@laptop:~/gcp/run-connector$ sed -i 's#google_vpc_access_connector.shop.id#"projects/planner-dev/locations/southamerica-east1/connectors/shop-connector"#' main.tf
ana@laptop:~/gcp/run-connector$ terraform validate -no-color

Error: Conflicting configuration arguments

  with google_cloud_run_v2_service.orders,
  on main.tf line 36, in resource "google_cloud_run_v2_service" "orders":
  36:       connector = "projects/planner-dev/locations/southamerica-east1/connectors/shop-connector"

"template.0.vpc_access.0.connector": conflicts with
template.0.vpc_access.0.network_interfaces

Error: Conflicting configuration arguments

  with google_cloud_run_v2_service.orders,
  on main.tf line 37, in resource "google_cloud_run_v2_service" "orders":
  37:       network_interfaces {

"template.0.vpc_access.0.network_interfaces": conflicts with
template.0.vpc_access.0.connector
```

Both blocks are named in both errors, which is the provider stating the rule from each side.
**A clean plan with references in it has checked less than it seems to**, and this is the
general form of lesson 1's limit: Terraform checks what it can know on your laptop. Choose one
mechanism per revision.

## When a connector is still the answer

Direct egress covers the common case, and Google's own guidance points new services at it. A
connector still fits when:

- the service already runs through one and works, and the migration has no reason other than
  tidiness; moving later is one new revision;
- the subnet has no room for the addresses direct egress would take at the service's maximum, and
  a `/28` for a connector is all the address space the network team will give;
- something on the network side was built around the connector's fixed range, such as a firewall
  rule that admits `10.8.0.0/28` and nothing else.

For the shop, with an empty subnet set aside for Cloud Run, direct egress is the plain choice: no
floor on the bill, no machines to grow stuck at their maximum.
