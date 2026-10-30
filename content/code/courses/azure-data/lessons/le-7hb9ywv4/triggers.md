---
title: Triggers: a clock, a window, or a file
version: 1
---

**A trigger decides when a pipeline runs, and the three kinds disagree about what "the night of the
29th" means.** A schedule trigger fires at a time on a clock. A tumbling window trigger fires once for
every slice of time since a start date, and remembers which slices have run. An event trigger fires
when a file arrives. This section checks two declarations with Terraform, offline, and teaches the
behaviour from Microsoft's documentation; no trigger fired.

## The tumbling window

**A tumbling window trigger cuts time into back-to-back windows of a fixed size, and runs the pipeline
once per window, with the window's start and end as values the pipeline can use.** That is the
trigger for a nightly load, because each run has a day that belongs to it. Save this beside
`main.tf`, in `~/azure/tf/factory`:

`triggers.tf`:

```hcl
resource "azurerm_data_factory_trigger_tumbling_window" "nightly" {
  name            = "tr_orders_nightly"
  data_factory_id = azurerm_data_factory.etl.id
  start_time      = "2026-10-01T06:00:00Z"
  frequency       = "Hour"
  interval        = 24
  delay           = "00:30:00"
  max_concurrency = 4

  retry {
    count    = 3
    interval = 600
  }

  pipeline {
    name = azurerm_data_factory_pipeline.nightly.name
    parameters = {
      day = "@formatDateTime(trigger().outputs.windowStartTime, 'yyyy-MM-dd')"
    }
  }
}
```

```
ana@laptop:~/azure/tf/factory$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/factory$ sed -i 's/= "Hour"/= "Day"/' triggers.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/= "Day"/= "Hour"/' triggers.tf
Error: expected frequency to be one of ["Hour" "Minute" "Month"], got Day
ana@laptop:~/azure/tf/factory$ sed -i 's/"00:30:00"/"30m"/' triggers.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/"30m"/"00:30:00"/' triggers.tf
Error: invalid value for delay (invalid timespan, must be of format hh:mm:ss)
ana@laptop:~/azure/tf/factory$ sed -i 's/max_concurrency = 4/max_concurrency = 60/' triggers.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/max_concurrency = 60/max_concurrency = 4/' triggers.tf
Error: expected max_concurrency to be in the range (1 - 50), got 60
```

**There is no `Day`: a day is 24 hours**, which is why the window above says `Hour` and `24`. The
four settings that matter, read against Quitanda's night:

- **`start_time` is in UTC, and it is the first window's start.** `2026-10-01T06:00:00Z` is three in
  the morning in São Paulo, which has had no summer time since 2019, so each window runs from three in
  the morning of one day to three in the morning of the next.
- **`delay` waits after the window closes before running**, thirty minutes here, so the run for the
  window that closes at 03:00 starts at 03:30, after the shop's export has had time to land. The
  provider checks its format, `hh:mm:ss`.
- **the pipeline gets the window's start as a parameter**, formatted as a date by the expression in
  `parameters`. The run that starts at 03:30 on the 2nd loads `day = 2026-10-01`.
- **`retry` reruns a failed window**, three times, ten minutes apart, before the window is marked
  failed. A failed window stays failed and visible, and can be rerun by hand once the cause is fixed.

**A start date in the past is a backfill.** Activated at noon on 30 October, this trigger owes the
pipeline every window that has closed since 1 October, 29 of them, and runs them, at most `max_concurrency` at a time; the
provider allows 1 to 50. That is how a new pipeline loads its history, and also how a careless start
date runs a year of loads in an afternoon. A pipeline run by a tumbling window should therefore be
safe to run twice for the same day: write the day's partition whole, replacing what was there, so that
a retry or a rerun leaves the same result. Lesson 24 comes back to that property and its name.

## The schedule trigger

**A schedule trigger fires on a clock and knows nothing about what each run was for.** It can start
several pipelines and it understands time zones, but it keeps no record of which nights have been
done: a start date in the past is not a backfill, and a run that failed is not owed again. Saved
beside the others as `schedule.tf`:

`schedule.tf`:

```hcl
resource "azurerm_data_factory_trigger_schedule" "nightly" {
  name            = "tr_orders_3am"
  data_factory_id = azurerm_data_factory.etl.id
  pipeline_name   = azurerm_data_factory_pipeline.nightly.name
  frequency       = "Day"
  interval        = 1
  time_zone       = "E. South America Standard Time"
  activated       = false

  schedule {
    hours   = [3]
    minutes = [0]
  }
}
```

```
ana@laptop:~/azure/tf/factory$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/factory$ terraform fmt -check && echo formatted
formatted
```

`terraform fmt -check` prints nothing and succeeds when every file is laid out the way Terraform
would lay it out, which is the other check a team's pipeline runs on these files before anybody
reviews them.

**`Day` is accepted here, and the time zone is a Windows name**, `E. South America Standard Time`,
which is how Azure names Brasília time, rather than `America/Sao_Paulo`. The pipeline gets no window,
so its `day` has to be worked out inside it, for example as yesterday's date at the moment it runs,
and a run that is late or rerun the next morning works out a different day. `activated = false` keeps
it declared and switched off: Quitanda runs the tumbling window, and the schedule is shown for the
difference.

## The storage event trigger

**An event trigger runs the pipeline when a blob is created or deleted**, with the blob's folder and
name as parameters, through Event Grid, which has to be registered in the subscription. It is the
right trigger when files arrive at no fixed time, such as a partner who uploads whenever their system
finishes. Its weakness is the mirror of its strength: a file that never comes starts nothing, and no
run fails to say so. A tumbling window that finds no file fails loudly at 03:30, which is the
behaviour a nightly load wants.
