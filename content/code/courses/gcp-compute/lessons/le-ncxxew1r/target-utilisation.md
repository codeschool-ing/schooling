---
title: Scaling to a target utilisation
version: 1
---

Lesson 4 left the group defending a number someone typed. **An autoscaler replaces that number with
a rule: keep a measured signal near a target, and let the group's size be whatever achieves it.** The
commonest signal is CPU, and the rule is simple enough to work out by hand, which is the best way to
trust it.

## The arithmetic the autoscaler does

Google's documentation describes the CPU rule plainly: the autoscaler adds up how busy the machines
are, divides by the target, and rounds up. A group of four machines running at 90%, 85%, 95% and 80%
of their CPU, with a target of 60%, is carrying 3.5 machines' worth of work, and 3.5 divided by 0.6 is
5.83, so it wants six machines. Here is that rule as a short program; save it as `~/gcp/recommend.py`:

```python
# recommend.py
import math
import sys

target = float(sys.argv[1])
busy = [float(x) for x in sys.argv[2:]]

work = sum(busy)
print(f'{len(busy)} machines, {work:.2f} machines of work, target {target:.0%}')
print(f'recommended size: {math.ceil(work / target)}')
```

```
ana@laptop:~/gcp$ python3 recommend.py 0.6 0.9 0.85 0.95 0.8
4 machines, 3.50 machines of work, target 60%
recommended size: 6
ana@laptop:~/gcp$ python3 recommend.py 0.6 0.2 0.2 0.2 0.2
4 machines, 0.80 machines of work, target 60%
recommended size: 2
```

The two runs say the same thing from two sides. Busy machines and a low target make the group grow;
the same group at 20% each makes it shrink to two, because two machines at 40% each would carry the
work under the target. **The target is the headroom you keep**: at 60% each machine has 40% spare for
the minute it takes to add more. A target of 90% is cheaper and leaves no room for a burst; a target of
30% pays for two machines in three to stand idle.

## Writing it

An autoscaler is a resource attached to a group. In a folder `autoscale`, a minimal group and the
autoscaler beside it:

```hcl
# autoscale/main.tf
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

resource "google_compute_instance_template" "web" {
  name_prefix  = "web-"
  machine_type = "e2-standard-2"

  disk {
    source_image = "debian-cloud/debian-12"
    boot         = true
  }

  network_interface {
    network = "default"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "web" {
  name               = "web"
  base_instance_name = "web"
  region             = "southamerica-east1"

  version {
    instance_template = google_compute_instance_template.web.id
  }
}

resource "google_compute_region_autoscaler" "web" {
  name   = "web"
  region = "southamerica-east1"
  target = google_compute_region_instance_group_manager.web.id

  autoscaling_policy {
    min_replicas    = 3
    max_replicas    = 12
    cooldown_period = 90

    cpu_utilization {
      target = 0.6
    }
  }
}
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E '^  #|_replicas|cooldown_period|^          \+ target|^Plan'
  # google_compute_instance_template.web will be created
  # google_compute_region_autoscaler.web will be created
          + cooldown_period = 90
          + max_replicas    = 12
          + min_replicas    = 3
  # google_compute_region_instance_group_manager.web will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

**The group no longer has a `target_size`.** Once an autoscaler is attached, the autoscaler sets the
size, and a number in the group's own resource would only fight it on every `terraform apply`.
`min_replicas` is the floor the autoscaler never goes under, three here so that one machine per zone
survives the quietest night, and `max_replicas` is the ceiling that keeps a bug or an attack from
running up a bill of a hundred machines.

The target is a fraction, and gcloud's help says what range it has to be in. The plan does not check
it: `target = 1.5` plans as cleanly as `0.6`, and Compute Engine refuses it when the autoscaler is
created.

```
ana@laptop:~/gcp/autoscale$ gcloud compute instance-groups managed set-autoscaling --help | sed -n '/^     --target-cpu-utilization/,/^$/p'
     --target-cpu-utilization=TARGET_CPU_UTILIZATION
        Autoscaler aims to maintain CPU utilization at target level (0.0 to
        1.0).
```
