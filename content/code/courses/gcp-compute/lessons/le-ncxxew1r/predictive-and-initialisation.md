---
title: Prediction, initialisation and scaling in slowly
version: 1
---

A schedule knows what a person wrote down. **Predictive autoscaling learns the pattern itself from the
group's own history and starts machines ahead of a rise it has seen before.** It is the last of the
three ways to scale, and it only works well together with two settings that every autoscaler should
get right whether it predicts or not.

## The initialisation period

Between a machine starting and its serving properly there is a gap: the boot, the service starting,
the caches warming. During that gap its CPU is misleading, high from startup work or low because no
traffic reaches it yet. **The initialisation period tells the autoscaler how long to ignore a new
machine's numbers.** In Terraform it is still called `cooldown_period`, from the setting's older
name, and gcloud's help says what it is for:

```
ana@laptop:~/gcp/autoscale$ gcloud compute instance-groups managed set-autoscaling --help | sed -n '/^     --cool-down-period/,/^$/p'
     --cool-down-period=COOL_DOWN_PERIOD
        The number of seconds that your application takes to initialize on a VM
        instance. This is referred to as the initialization period
        (https://cloud.google.com/compute/docs/autoscaler#cool_down_period).
        Specifying an accurate initialization period improves autoscaler
        decisions. For example, when scaling out, the autoscaler ignores data
        from VMs that are still initializing because those VMs might not yet
        represent normal usage of your application. The default initialization
        period is 60 seconds. See $ gcloud topic datetimes for information on
        duration formats. Initialization periods might vary because of numerous
        factors. We recommend that you test how long your application may take
        to initialize. To do this, create a VM and time your application's
        startup process.
```

Set it too short and the autoscaler reads a booting machine's startup CPU as load and adds more
machines for no reason. Set it too long and the predictive scaler starts machines later than it
should, because it plans backwards from how long a machine takes. The right number is the same
measurement as lesson 4's initial delay: from creation to the first healthy answer.

## Prediction

Prediction is one line in the policy, and it applies to the CPU signal:

```hcl
# autoscale/main.tf, prediction
    cpu_utilization {
      target            = 0.6
      predictive_method = "OPTIMIZE_AVAILABILITY"
    }
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E 'predictive_method|^              \+ target'
              + predictive_method = "OPTIMIZE_AVAILABILITY"
              + target            = 0.6
```

It needs history to learn from: Google's documentation asks for at least three days of the group
running with CPU autoscaling before forecasts begin, and it uses several weeks when it has them. It is
for **load that repeats**: a daily rise, a weekly shape. For a group whose load is random it predicts
nothing useful, and for a new group it has nothing to learn from yet.

## Scaling in slowly

Growing late costs users; shrinking early costs them too, because the load that just fell often comes
straight back. Two mechanisms slow the way down:

- the **stabilisation period**: before removing machines, the autoscaler looks at its recommendations
  over the last ten minutes and uses the highest of them, so a dip has to last before the group
  follows it down;
- **scale-in controls**, which cap how many machines may go within a window of time.

```hcl
# autoscale/main.tf, scale-in control
    scale_in_control {
      time_window_sec = 600

      max_scaled_in_replicas {
        fixed = 2
      }
    }
```

```
ana@laptop:~/gcp/autoscale$ terraform plan -no-color | grep -E 'scale_in_control|time_window_sec|fixed|^Plan'
          + scale_in_control {
              + time_window_sec = 600
                  + fixed = 2
Plan: 3 to add, 0 to change, 0 to destroy.
```

Read it as: **in any ten minutes, remove at most two machines.** A group that peaked at twelve then
takes at least half an hour to come back to six, and if the load returns in that half hour the
machines are still there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A bar chart of the group size against time after the load falls at minute 0. The load needs six machines from then on, drawn as a dashed line. The group has 12 machines at minute 0, 10 at minute 10, 8 at minute 20 and 6 at minute 30, because the scale-in control removes at most two machines in any ten minutes.\"><defs><marker id=\"l5s-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M70 250 L680 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"60\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><rect x=\"100\" y=\"70\" width=\"70\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"135\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minute 0</text><rect x=\"215\" y=\"100\" width=\"70\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><text x=\"250\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minute 10</text><rect x=\"330\" y=\"130\" width=\"70\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><text x=\"365\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minute 20</text><rect x=\"445\" y=\"160\" width=\"70\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"480\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minute 30</text><rect x=\"560\" y=\"160\" width=\"70\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"595\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minute 40</text><path d=\"M80 160 L98 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M172 160 L213 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M287 160 L328 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M402 160 L443 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M517 160 L558 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M632 160 L680 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"676\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">dashed: what the load needs</text></svg>", "caption": "With at most two machines removed per ten minutes, a group that peaked at 12 takes half an hour to come back to the 6 the load needs."}
```

None of this can be watched in this lab: there is no group, no load and no ten minutes of history to
look back on. What the lab shows is the policy as Compute Engine would receive it, and the arithmetic
of section 02 that the autoscaler would apply to it.
