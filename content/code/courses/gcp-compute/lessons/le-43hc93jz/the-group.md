---
title: A managed instance group
version: 1
---

A template describes a machine. **A managed instance group, a MIG, is the thing that keeps a number
of machines made from that template alive: you tell it how many, and it creates, replaces and
deletes machines until the count is right.** You stop managing machines and start managing a number.

## Zonal or regional

A **zonal** MIG puts every machine in one zone. A **regional** MIG spreads them across the zones of a
region, so the loss of one zone leaves the others serving. For anything that answers users, the
regional one is the default, and it is what the shop uses. Add it to `group/main.tf`, below the
template:

```hcl
# group/main.tf, continued
resource "google_compute_region_instance_group_manager" "web" {
  name               = "web"
  base_instance_name = "web"
  region             = "southamerica-east1"

  distribution_policy_zones = [
    "southamerica-east1-a",
    "southamerica-east1-b",
    "southamerica-east1-c",
  ]

  version {
    instance_template = google_compute_instance_template.web.id
  }

  target_size = 3

  named_port {
    name = "http"
    port = 8080
  }
}
```

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E '^  #|^      \+ target_size +=|base_instance_name|^Plan'
  # google_compute_instance_template.web will be created
  # google_compute_region_instance_group_manager.web will be created
      + base_instance_name               = "web"
      + target_size                      = 3
Plan: 2 to add, 0 to change, 0 to destroy.
```

**`target_size` is the number the group defends.** Delete one of the three machines by hand and the
group creates another, because three is still the target. That is the first surprise for somebody
used to looking after machines: in a group, deleting a machine is not how you get rid of it. You
change the number, or you delete the group.

`base_instance_name` is the start of every machine's name: the group adds a short random suffix,
`web-` and four characters, so machines come and go without colliding. `named_port` gives the port
a name, `http`, which is how a load balancer in front of the group, the subject of
`gcp-foundations` lesson 20, refers to it.

## Stateless, which is the condition

A group can only do this because it treats every machine as interchangeable. **When it replaces a
machine, the new one starts from the template, and whatever was on the old one's boot disk is
gone.** So what runs in a group has to keep nothing it cannot lose on the machine: sessions in a
shared store, uploads in Cloud Storage, data in a database. The `orders` database of lesson 3, with
its data disk, is the opposite of this kind of machine and does not belong in a group like this one.

Compute Engine has a feature for the exception, **stateful MIGs**, which keep a named disk or an
address with a particular machine through replacement. It exists for software that genuinely cannot
be made stateless, such as some older databases, and it gives back part of what a group was for. Reach
for it last.
