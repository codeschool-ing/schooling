---
title: Rolling updates, and the canary
version: 1
---

A new template does nothing to the machines that already exist. **The group replaces them according
to its update policy, a few at a time, so that the service keeps answering while every machine is
swapped for one made from the new template.** The policy decides how few, and getting it wrong is
how a release takes a service down.

## Two numbers

The policy turns on two numbers, and every rolling update is a trade between them:

- **`max_surge`**: how many machines above the target the group may create during the update. Surge
  adds capacity before removing any, at the price of paying for the extra machines while they run.
- **`max_unavailable`**: how many machines may be out of service at once. Unavailability updates
  without extra machines, at the price of less capacity during the update.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four steps of a rolling update of a group of three, with max_surge 3 and max_unavailable 0. Step 1: three machines on the old template, serving. Step 2: three new machines boot beside them, six in all, while the three old ones keep serving. Step 3: the new machines pass their health checks and serve, and the old ones are deleted. Step 4: three machines on the new template. At no step do fewer than three healthy machines serve.\"><defs><marker id=\"l4r-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"160\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">step 1</text><text x=\"100\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">three old, serving</text><rect x=\"40\" y=\"84\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old</text><rect x=\"40\" y=\"115\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old</text><rect x=\"40\" y=\"146\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old</text><rect x=\"195\" y=\"20\" width=\"160\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"207\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">step 2</text><text x=\"275\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">three new booting</text><rect x=\"215\" y=\"84\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old</text><rect x=\"215\" y=\"115\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old</text><rect x=\"215\" y=\"146\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old</text><rect x=\"215\" y=\"177\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275.0\" y=\"189.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new, booting</text><rect x=\"215\" y=\"208\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new, booting</text><rect x=\"215\" y=\"239\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new, booting</text><rect x=\"370\" y=\"20\" width=\"160\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"382\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">step 3</text><text x=\"450\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">new serving, old deleted</text><rect x=\"390\" y=\"84\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old, deleting</text><rect x=\"390\" y=\"115\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old, deleting</text><rect x=\"390\" y=\"146\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old, deleting</text><rect x=\"390\" y=\"177\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"189.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new</text><rect x=\"390\" y=\"208\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new</text><rect x=\"390\" y=\"239\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new</text><rect x=\"545\" y=\"20\" width=\"160\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"557\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">step 4</text><text x=\"625\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">three new, serving</text><rect x=\"565\" y=\"84\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new</text><rect x=\"565\" y=\"115\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new</text><rect x=\"565\" y=\"146\" width=\"120\" height=\"25\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new</text></svg>", "caption": "With surge and no unavailability, the group pays for up to six machines for a few minutes and never serves with fewer than three."}
```

The shop's choice is surge and no unavailability: the update never runs with fewer than three
healthy machines. Add the policy inside the group's resource:

```hcl
# group/main.tf, update policy
  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
    instance_redistribution_type = "PROACTIVE"
  }
```

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E 'max_surge_fixed|max_unavailable_fixed|minimal_action|"PROACTIVE"|^Plan'
          + max_surge_fixed       = 3
          + max_unavailable_fixed = 0
          + minimal_action        = "REPLACE"
          + type                  = "PROACTIVE"
Plan: 3 to add, 0 to change, 0 to destroy.
```

`PROACTIVE` means the group starts replacing machines as soon as the template changes; the other
type, `OPPORTUNISTIC`, only applies the new template to machines the group creates for some other
reason. `REPLACE` means a new machine with a new name rather than a restart of the old one. This is
the one block where the provider does check a word, as it did for the snapshot schedule in lesson 3.
Write `SOMETIMES` in place of `PROACTIVE` on the `type` line and plan again:

```
ana@laptop:~/gcp/group$ grep -n "type " main.tf
18:  machine_type = "e2-standard-2"
67:    type                         = "SOMETIMES"
71:    instance_redistribution_type = "PROACTIVE"
ana@laptop:~/gcp/group$ terraform plan -no-color

Error: expected update_policy.0.type to be one of ["OPPORTUNISTIC" "PROACTIVE"], got SOMETIMES

  with google_compute_region_instance_group_manager.web,
  on main.tf line 67, in resource "google_compute_region_instance_group_manager" "web":
  67:     type                         = "SOMETIMES"
```

Put `PROACTIVE` back before going on.

**For a regional group, a fixed surge or unavailability must be zero or at least the number of
zones**, because the group moves machines zone by zone. Three zones, so `max_surge_fixed = 3` or
nothing; the plan does not check that rule, and Compute Engine refuses a 2 when the group is created.

## The canary

Replacing every machine at once is fine until the new template is wrong. **A canary sends a small
share of the group to the new template first and leaves the rest on the old one**, so a mistake shows
up on one machine instead of all of them. Terraform writes it as two `version` blocks, the second with
a `target_size`. In place of the single `version` block of section 03:

```hcl
# group/main.tf, canary
  version {
    name              = "stable"
    instance_template = "projects/planner-dev/global/instanceTemplates/web-stable"
  }

  version {
    name              = "canary"
    instance_template = google_compute_instance_template.web.id

    target_size {
      fixed = 1
    }
  }
```

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E '^      \+ version|instance_template = |name += "(stable|canary)"|^              \+ fixed|^Plan'
      + version {
          + instance_template = "projects/planner-dev/global/instanceTemplates/web-stable"
          + name              = "stable"
      + version {
          + instance_template = (known after apply)
          + name              = "canary"
              + fixed = 1
Plan: 3 to add, 0 to change, 0 to destroy.
```

One machine of the three runs the new template and two keep the old one. Watch the canary's errors
and latency against the others; if it is worse, remove the second block and the group puts all three
back on the stable template. If it holds, the next step is to make the new template the only version.
The stable template's name is written out because it already exists and Terraform does not manage
it in this file: the canary is a moment between two releases, not a permanent shape.

Every one of these steps is a change to a running group, so this lab can plan them and cannot show
them happening. What a reader can check here is the file: the shape of the policy and of the versions
that Compute Engine would act on.
