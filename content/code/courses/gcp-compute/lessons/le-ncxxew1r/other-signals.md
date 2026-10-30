---
title: Signals other than CPU
version: 1
---

CPU is a good signal for work that is mostly computation and a poor one for everything else. **A
service that spends its time waiting on a database or a queue can be overwhelmed while its CPU looks
idle**, and an autoscaler watching CPU will keep the group small while users wait. Compute Engine's
autoscaler can follow two other kinds of signal, alone or together.

## The load balancer's own measure

When the group sits behind an HTTP(S) load balancer, the balancer knows how many requests each machine
is handling against a capacity you declared for it. **Load-balancing utilisation** scales on that
ratio. It is the right signal for a web service whose cost per request is roughly constant and whose
limit is how many requests it can hold at once rather than how hard it computes. It is written as a
`load_balancing_utilization` block in place of, or beside, `cpu_utilization`, and it only means
something once the balancer from `gcp-foundations` lesson 20 is in front of the group.

## A metric of your own

Any metric in Cloud Monitoring can drive the group, and the one that fits a worker best is the length
of the queue it drains. The rule then is not "keep each machine 60% busy" but **"keep about this many
messages per machine"**:

```hcl
# autoscale/queue.tf
resource "google_compute_region_autoscaler" "photos" {
  name   = "photos"
  region = "southamerica-east1"
  target = "projects/planner-dev/regions/southamerica-east1/instanceGroupManagers/photos"

  autoscaling_policy {
    min_replicas = 0
    max_replicas = 20

    metric {
      name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
      filter                     = "resource.type = pubsub_subscription AND resource.labels.subscription_id = photos-resize"
      single_instance_assignment = 50
    }
  }
}
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E '^  #|single_instance_assignment|num_undelivered|^Plan'
  # google_compute_instance_template.web will be created
  # google_compute_region_autoscaler.photos will be created
              + name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
              + single_instance_assignment = 50
  # google_compute_region_autoscaler.web will be created
  # google_compute_region_instance_group_manager.web will be created
Plan: 4 to add, 0 to change, 0 to destroy.
```

`single_instance_assignment = 50` is the rule: fifty undelivered messages per machine. A backlog of
400 asks for eight workers; an empty queue asks for none, which is why `min_replicas` can be 0 here
and could not be for the web group. **A queue is the one signal that measures the work waiting rather
than the work being done**, so it scales out before anybody is slow, and it scales a worker to zero when
there is nothing to do, which no CPU target can.

## When several signals disagree

An autoscaler may have more than one signal. It works out a size for each and **takes the largest**, so
adding a signal can only make the group bigger at a given moment, never smaller. That is the safe
direction, and it means a signal that is always high, a metric stuck at a stale value, holds the group
at its maximum until somebody notices the bill.
