---
title: Direct VPC egress
version: 1
---

**Direct VPC egress puts each instance of a revision into a subnet of your VPC, with an address of
its own taken from that subnet.** There is no machine in between, so there is nothing to size,
patch or pay for by the hour; the bill carries the traffic and nothing else. It is the mechanism
Google recommends for new services, and the one to reach for first.

## Writing it down

Create a folder `run-vpc` in `~/gcp` and save this as `main.tf` in it. It is the orders service
with the two lines that matter added: a `vpc_access` block in the revision template, and the
database address the service is told about:

```hcl
# run-vpc/main.tf
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

resource "google_cloud_run_v2_service" "orders" {
  name     = "orders"
  location = "southamerica-east1"
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1.0.0"
      env {
        name  = "DATABASE_HOST"
        value = "10.20.0.3"
      }
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = "shop"
        subnetwork = "shop-run"
      }
    }
  }
}
```

Run `terraform init` in the folder, as in lesson 1, and then the plan, filtered to what this
section is about:

```
ana@laptop:~/gcp/run-vpc$ terraform plan -no-color | grep -E '^  #|image|value|egress|network|^Plan'
  # google_cloud_run_v2_service.orders will be created
              + image      = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1.0.0"
                  + value = "10.20.0.3"
              + egress = "PRIVATE_RANGES_ONLY"
              + network_interfaces {
                  + network    = "shop"
                  + subnetwork = "shop-run"
Plan: 1 to add, 0 to change, 0 to destroy.
```

Read the plan as the revision Cloud Run would build: an image, an environment variable, and a
network interface in `shop-run`. The `egress` line is section 05's subject; `PRIVATE_RANGES_ONLY`
sends only private addresses into the VPC and lets everything else go out the way it always did.

## The subnet is a budget of addresses

The one thing direct egress asks you to plan is the subnet, because **every running instance holds
addresses in it.** When the service scales out, new instances take addresses as they start; when
it scales in, the addresses are released some time after the instances stop, not at the same
moment. A subnet that runs out does not slow the service down. New instances simply fail to
start, and the symptom is requests waiting for capacity during exactly the burst that needed it.

So size the subnet for the service's maximum instance count with room to spare, and give Cloud
Run a subnet of its own, rather than sharing one with virtual machines whose addresses you also
have to count. Google's documentation gives the current figures for how many addresses an
instance takes and how long they are held; read them for the release you deploy against, because
they have changed before. The lab's `shop-run` is a `/26`, 64 addresses, of which Google reserves
four in every subnet.

## What the plan cannot tell you

Terraform accepted `shop` and `shop-run` as names. **Whether they exist, are in
`southamerica-east1`, and have free addresses is checked by Cloud Run when it creates the
revision**, the same limit lesson 1 met with machine types. The commands that would show it are
documented and need an account; in this lab they stop at the missing account like every remote
`gcloud` command:

```sh
gcloud run services update orders --region=southamerica-east1 \
  --network=shop --subnet=shop-run --vpc-egress=private-ranges-only
gcloud compute networks subnets describe shop-run --region=southamerica-east1
```

Those two are shown from Google's documentation and were not run. The first is how you would add
direct egress to a service that already exists, which creates a new revision just as the
Terraform change would.
