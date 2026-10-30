---
title: Maintenance windows and exclusions
version: 1
---

A release channel decides **which** versions arrive. A maintenance policy decides **when** GKE may
apply them. Without one, automatic maintenance can start at any hour, and the shop's busiest
evening is as good a moment as any. **A window says when maintenance may happen; an exclusion says
when it must not.**

## The recurring window

The shop's cluster in section 02 already has one:

```
ana@laptop:~/gcp/gke$ terraform plan -no-color | grep -E 'start_time|end_time|recurrence|exclusion_name|\+ scope'
              + end_time       = "2026-12-02T00:00:00Z"
              + exclusion_name = "black-friday"
              + start_time     = "2026-11-25T00:00:00Z"
                  + scope             = "NO_UPGRADES"
              + end_time   = "2026-11-07T11:00:00Z"
              + recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
              + start_time = "2026-11-07T05:00:00Z"
```

The three strings are written in standards, not in Google's own format. `start_time` and
`end_time` are timestamps in UTC, and only their time of day and length matter for a recurring
window: here, six hours from 05:00. `recurrence` is an RRULE from the iCalendar standard, the same
syntax a calendar invitation uses: weekly, on Saturdays and Sundays.

**The times are UTC, and the shop is not.** Ask your own computer what 05:00 UTC on the first
Saturday is in São Paulo:

```
ana@laptop:~/gcp/gke$ TZ=America/Sao_Paulo date -d 2026-11-07T05:00:00Z
Sat Nov  7 02:00:00 -03 2026
ana@laptop:~/gcp/gke$ TZ=America/Sao_Paulo date -d 2026-11-07T11:00:00Z
Sat Nov  7 08:00:00 -03 2026
```

Two to eight in the morning, local time, which is the point: the window was chosen for when the shop's
customers are asleep, and writing it in UTC without converting is the commonest way to put
maintenance in the middle of somebody's evening.

Google requires a window to leave room for maintenance: its documentation asks for at least 48
hours of availability in any 32-day period, in stretches of at least four hours. **Any 32 days
contain at least eight weekend days, and eight days of six hours is exactly 48.** Four-hour
windows on the same days would give 32 hours and be refused. That rule is checked when the cluster
is created or updated, not by the plan; the lab cannot tell you a window is too short.

## Exclusions

An exclusion is a period with a name, a start and an end, during which a stated kind of upgrade
does not happen even inside the window. The shop has one for the week of Black Friday. The
`scope` says how much is held back:

| scope | what is held back |
|---|---|
| `NO_UPGRADES` | every upgrade, control plane and nodes; Google limits how long such an exclusion may last |
| `NO_MINOR_UPGRADES` | moves to a new minor version; patches still arrive |
| `NO_MINOR_OR_NODE_UPGRADES` | minor versions anywhere, and any change to the nodes |

The narrower scopes may last much longer than `NO_UPGRADES`, up to the end of the version's
support, which makes them the tool for "nothing changes on the nodes during the migration" rather
than for a busy week.

## What a window cannot hold back

Two things go through regardless, and Google's documentation lists them: **security fixes it
judges urgent**, and **the end of a version's support**. A cluster still on a version whose support
has ended is upgraded whether or not a window or exclusion is open. An exclusion is a way to
choose the moment, not a way to stay still, and a cluster whose exclusions keep getting renewed is a
cluster accumulating a large upgrade for later.
