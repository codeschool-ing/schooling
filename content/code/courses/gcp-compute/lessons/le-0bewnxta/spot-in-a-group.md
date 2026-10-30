---
title: Spot machines in a group
version: 1
---

A single Spot machine that is taken back stays down until somebody acts. **A managed group of Spot
machines heals itself: a preempted machine is recreated from the template as soon as capacity allows,
and the group's target is defended exactly as lesson 4 described.** That makes a group the natural
home for Spot machines, and it also makes it easy to forget what can still go wrong.

## The template carries the condition

Spot is a property of the template, so every machine the group makes is a Spot machine. In the same
folder as section 03, add a template and a group:

```hcl
# spot/group.tf
resource "google_compute_instance_template" "photos" {
  name_prefix  = "photos-"
  machine_type = "e2-standard-2"

  disk {
    source_image = "debian-cloud/debian-12"
    boot         = true
  }

  network_interface {
    network = "default"
  }

  scheduling {
    provisioning_model          = "SPOT"
    preemptible                 = true
    automatic_restart           = false
    instance_termination_action = "DELETE"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "photos" {
  name               = "photos"
  base_instance_name = "photos"
  region             = "southamerica-east1"
  target_size        = 4

  distribution_policy_target_shape = "ANY"

  version {
    instance_template = google_compute_instance_template.photos.id
  }
}
```

```
ana@laptop:~/gcp/spot$ terraform plan -no-color | grep -E '^  #|provisioning_model|instance_termination_action|target_shape|target_size +=|^Plan'
  # google_compute_instance.photos_batch will be created
          + instance_termination_action = "STOP"
          + provisioning_model          = "SPOT"
  # google_compute_instance_template.photos will be created
          + instance_termination_action = "DELETE"
          + provisioning_model          = "SPOT"
  # google_compute_region_instance_group_manager.photos will be created
      + distribution_policy_target_shape = "ANY"
      + target_size                      = 4
Plan: 3 to add, 0 to change, 0 to destroy.
```

The template says `DELETE`, as section 03 recommended for groups: the group will make a new machine
anyway, so a stopped one would only hold a disk and a name.

## What the group cannot promise

**A group can recreate a machine only when there is capacity to create it on**, and the condition for
a preemption is that there is not. A Spot group can therefore sit below its target for minutes or
hours, in exactly the moments when Google is short of that type in that zone. Two habits soften that:

- **spread the group over the zones of a region**, because capacity runs short zone by zone, and
  let it put machines wherever there is room: `distribution_policy_target_shape = "ANY"` frees a
  regional group from the even spread of lesson 4, which is right for batch work and wrong for a web
  service that must survive a zone;
- **do not let the whole service depend on Spot.** A web service keeps a base of standard machines
  that answers on its own, and adds a Spot group behind the same load balancer for the extra capacity
  it can lose without harm.

The second habit is two groups, not one: Compute Engine's groups take one provisioning model from their
template, so a mixed fleet is a standard group and a Spot group side by side. GKE does the same thing
with node pools, which lesson 13 is about.
