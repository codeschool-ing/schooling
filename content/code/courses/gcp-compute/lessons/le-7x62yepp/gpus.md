---
title: Machines with a GPU
version: 1
---

A GPU is not a bigger processor. **It is a separate device, priced separately, that only a few
machine series can carry and only some zones can supply.** Asking for one is less like choosing a
size and more like booking a scarce resource, and the rules around it follow from that.

## Two ways to get one

The newer way is a machine type from the **accelerator-optimised** family, where the GPU is part of
the type: `g2-standard-4` is four vCPUs, 16 GiB and one NVIDIA L4, and you cannot have the machine
without the GPU or the other way round. The A2, A3 and G4 series work the same way with larger
GPUs, up to eight of them per machine.

The older way is an **N1** machine with a GPU attached, which Terraform writes as a
`guest_accelerator` block. It lets you pick the GPU and the machine separately, which is how
cheaper and older GPUs such as the NVIDIA T4 are still offered. In a folder `gpu`:

```hcl
# gpu/main.tf
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

resource "google_compute_instance" "infer" {
  name         = "infer-1"
  machine_type = "g2-standard-4"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }
}

resource "google_compute_instance" "train" {
  name         = "train-1"
  machine_type = "n1-standard-4"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }

  guest_accelerator {
    type  = "nvidia-tesla-t4"
    count = 1
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }
}
```

```
ana@laptop:~/gcp/gpu$ terraform plan -no-color | grep -E '^  #|machine_type|on_host_maintenance|^          \+ (count|type) |^Plan'
  # google_compute_instance.infer will be created
      + machine_type         = "g2-standard-4"
          + on_host_maintenance = "TERMINATE"
  # google_compute_instance.train will be created
      + machine_type         = "n1-standard-4"
          + count = 1
          + type  = "nvidia-tesla-t4"
          + on_host_maintenance = "TERMINATE"
Plan: 2 to add, 0 to change, 0 to destroy.
```

## Why `TERMINATE`

Compute Engine moves ordinary machines to another host while it maintains the first one, a **live
migration** the machine barely notices. A GPU is a physical card in one host, and its memory cannot
be moved with the machine. So a machine with a GPU has to **stop for host maintenance** instead, and
Google requires `on_host_maintenance = "TERMINATE"` on it. The plan above accepted the setting; it
would also have accepted `MIGRATE`, and the refusal would come from Compute Engine at creation, the
same limit lesson 1 met with a machine type that did not exist.

The documented flag on gcloud says what the default is, and help works without an account:

```
ana@laptop:~/gcp$ gcloud compute instances create --help | sed -n '/^     --maintenance-policy/,/^     --max-run/p'
     --maintenance-policy=MAINTENANCE_POLICY
        Specifies the behavior of the VMs when their host machines undergo
        maintenance. The default is MIGRATE. For more information, see
        https://cloud.google.com/compute/docs/instances/host-maintenance-options.
        MAINTENANCE_POLICY must be one of:

         MIGRATE
            The instances should be migrated to a new host. This will
            temporarily impact the performance of instances during a migration
            event.
         TERMINATE
            The instances should be terminated.

     --max-run-duration=MAX_RUN_DURATION
```

What `TERMINATE` means for the software is the same as lesson 6 means for Spot machines: the
machine is stopped from outside, with notice, and the work on it has to be written to survive that.

## What one costs, and the two other obstacles

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E "per hour|e2-standard-2|g2-standard-4"
                                    per hour   per month   Spot/hour
  e2-standard-2   2 vCPU   8 GiB    0.06701142       48.92    0.040212
  g2-standard-4   4 vCPU  16 GiB   0.706832276      515.99           -
```

**516 dollars a month for one `g2-standard-4` left running**, ten times the `e2-standard-2`
beside it, which is why a GPU machine is the one most worth stopping when it is idle. The T4 on an N1
is cheaper per hour: Google's GPU page listed it at 0.35 dollars an hour per GPU in Iowa on
30 October 2026, on top of the N1 machine itself.

Two obstacles come before the price, and neither can be seen from this lab:

- **Not every zone has every GPU.** Each zone offers a list of accelerator types, and a type missing
  from it is refused at creation. `gcloud compute accelerator-types list
  --filter="zone:southamerica-east1-a"` is the question to ask, with an account.
- **A new project's GPU quota is zero in most regions.** The quota is a separate request, reviewed by
  Google, and it is worth making days before the machine is needed rather than on the afternoon it
  is.
