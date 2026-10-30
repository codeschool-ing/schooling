---
title: Scaling by schedule
version: 1
---

Some load is not a surprise. The shop's traffic rises every weekday at nine and the Black Friday sale
starts at midnight on a known date. **A schedule tells the autoscaler about load before it arrives,
so the machines are already up when it does**, instead of being started by the first slow minute of
it.

## A schedule sets a floor, not a size

The thing to understand first: **a scaling schedule raises the minimum for a window of time; it does
not set the size.** During the window the group has at least that many machines, and the CPU rule can
still add more on top. Outside the window the schedule has no effect at all. So a schedule can never
make the group smaller than the load needs, which is what makes it safe to add.

Add two schedules to the web autoscaler of section 02, inside its `autoscaling_policy`:

```hcl
# autoscale/main.tf, schedules
    scaling_schedules {
      name                  = "weekday-mornings"
      min_required_replicas = 6
      schedule              = "0 8 * * MON-FRI"
      time_zone             = "America/Sao_Paulo"
      duration_sec          = 36000
    }

    scaling_schedules {
      name                  = "black-friday"
      min_required_replicas = 10
      schedule              = "0 0 27 11 *"
      time_zone             = "America/Sao_Paulo"
      duration_sec          = 86400
    }
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E 'scaling_schedules|min_required_replicas|schedule +=|time_zone|duration_sec'
          + scaling_schedules {
              + duration_sec          = 36000
              + min_required_replicas = 6
              + schedule              = "0 8 * * MON-FRI"
              + time_zone             = "America/Sao_Paulo"
          + scaling_schedules {
              + duration_sec          = 86400
              + min_required_replicas = 10
              + schedule              = "0 0 27 11 *"
              + time_zone             = "America/Sao_Paulo"
```

The first reads: from eight in the morning, Monday to Friday, São Paulo time, for ten hours, keep at
least six machines. It starts an hour before the rise on purpose, because a new machine needs time to
boot and pass its health check, which lesson 4 measured with the initial delay. The second keeps ten
machines for the whole of 27 November.

**`schedule` is a cron expression and `time_zone` decides how it is read.** Unlike the snapshot
schedule of lesson 3, which is in UTC, this one takes a time zone by name, and writing it is what
keeps eight in the morning at eight when the clocks of some other country change. A cron line that
names the 27th of November fires on that date every year, which is right for a sale with a fixed
date and wrong for one that moves; such a schedule is deleted after the event.

## What a schedule costs

The morning schedule lifts the floor from three machines to six, so at most three extra
`e2-standard-2` machines run for ten hours on each weekday. A month with 22 weekdays is 660
machine-hours, about **44.23 dollars** at the sheet's 0.06701142 an hour, and less whenever the CPU
rule would have added those machines anyway. It is paid whether or not
the morning rise happens, which is the trade: a little money for not having the first users of each
day meet a group that is still growing.
