---
title: Zones, health checks and autohealing
version: 1
---

A group that only counted machines would keep three machines running that all answer with errors.
**Autohealing adds a second test: the group asks each machine a question over the network, and a
machine that fails it often enough is deleted and made again from the template.** A machine that
is up and broken is the commonest kind of broken, and this is what finds it.

## The question a health check asks

A health check is a resource of its own: what to ask, how often, and how many answers decide. Add it
to `group/main.tf`:

```hcl
# group/main.tf, health
resource "google_compute_health_check" "web" {
  name                = "web-health"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 8080
    request_path = "/healthz"
  }
}
```

Read it as a rule: **every 10 seconds, ask for `/healthz` on port 8080 and wait 5 for an answer;
three failures in a row make a machine unhealthy, two successes make it healthy again.** So a machine
that stops answering is noticed within about 30 seconds, and a single slow answer is not enough to
condemn it. The path is the application's to provide, and what it checks matters: a `/healthz` that
always answers `200` because the web server is up says nothing about whether the database behind it
is reachable.

## Tying it to the group

The group uses the check through an `auto_healing_policies` block. Add it inside the group's
resource, after `named_port`:

```hcl
# group/main.tf, inside the group
  auto_healing_policies {
    health_check      = google_compute_health_check.web.id
    initial_delay_sec = 120
  }
```

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E '^  #|initial_delay_sec|request_path|unhealthy_threshold|^Plan'
  # google_compute_health_check.web will be created
      + unhealthy_threshold = 3
          + request_path = "/healthz"
  # google_compute_instance_template.web will be created
  # google_compute_region_instance_group_manager.web will be created
          + initial_delay_sec = 120
Plan: 3 to add, 0 to change, 0 to destroy.
```

**`initial_delay_sec` is the most important number in the block.** A new machine needs time to boot,
start its service and warm up, and during that time it fails every health check. Without a delay the
group would see a new machine fail, delete it, make another, see that one fail, and go round for
ever without a single machine ever finishing its boot. 120 seconds is a guess to replace with a
measurement: time how long a machine takes from creation to its first healthy answer, and add a
margin.

Health checks come from Google's own probe addresses, and the firewall has to let them in, or every
machine fails its check and the group recreates them all in a loop. Those ranges and the rule that
allows them belong to `gcp-foundations` lesson 16, on firewall rules.

## How a regional group places machines

The group of section 03 named three zones and asked for three machines, so it puts one in each. With
`target_size = 4` the fourth goes to one of the zones and the spread is two, one, one; the group keeps
the difference between zones to at most one machine. If a zone fails, the group creates replacements
in the zones that remain, and when the zone comes back it moves machines back to even out the spread,
**which means deleting some and creating others**. That move is controlled by the update policy of
section 05, and it is one more reason the machines have to be stateless.
