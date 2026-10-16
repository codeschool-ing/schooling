---
title: Scaling by the clock
version: 1
---

Every policy in the last two sections reacts. The load rises, a metric follows, an alarm fires,
and instances arrive minutes later. **A scheduled action does not look at the load at all.** It
changes the group's numbers at a time you name, which makes it the one kind of scaling that can act
before the load arrives. For a load that arrives at the same time every weekday, it is the
cheapest fix there is.

## The schedule is cron, in UTC unless you say otherwise

`put-scheduled-update-group-action` takes a cron expression in five fields (minute, hour, day of
the month, month, day of the week) and the numbers to set when it fires. **The expression is read
in UTC unless the action carries a `--time-zone`**, and that is where scheduled actions go wrong
in São Paulo. The city is three hours behind UTC all year, since Brazil stopped changing its
clocks in 2019, so 07:30 in São Paulo is 10:30 UTC:

```
ana@laptop:~/aws$ date -u -d 'TZ="America/Sao_Paulo" 2026-10-19 07:30'
Mon Oct 19 10:30:00 UTC 2026
```

An action written as `30 7 * * 1-5` with no time zone would fire at 04:30 São Paulo time, three
hours before anybody arrives. Ana writes both actions in the city's own time instead, and lets AWS
do the conversion:

```
ana@laptop:~/aws$ aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name web --scheduled-action-name weekday-morning --recurrence '30 7 * * 1-5' --time-zone America/Sao_Paulo --min-size 6 --desired-capacity 6
ana@laptop:~/aws$ aws autoscaling put-scheduled-update-group-action --auto-scaling-group-name web --scheduled-action-name weekday-evening --recurrence '0 19 * * 1-5' --time-zone America/Sao_Paulo --min-size 2 --desired-capacity 2
ana@laptop:~/aws$ aws autoscaling describe-scheduled-actions --auto-scaling-group-name web
{
    "ScheduledUpdateGroupActions": [
        {
            "AutoScalingGroupName": "web",
            "ScheduledActionName": "weekday-morning",
            "Recurrence": "30 7 * * 1-5",
            "MinSize": 6,
            "DesiredCapacity": 6,
            "TimeZone": "America/Sao_Paulo"
        },
        {
            "AutoScalingGroupName": "web",
            "ScheduledActionName": "weekday-evening",
            "Recurrence": "0 19 * * 1-5",
            "MinSize": 2,
            "DesiredCapacity": 2,
            "TimeZone": "America/Sao_Paulo"
        }
    ]
}
```

Every weekday at 07:30 the minimum and the desired capacity go to six; at 19:00 both go back to
two. **moto stores the actions and never runs them**: it has no clock that fires anything, so the
group in this lab stays where the last command put it. On AWS each one runs at its time and is
recorded as a scaling activity. The rest of this section is AWS's behaviour.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A weekday in São Paulo time, from 00:00 to 24:00, with capacity from 0 to 10 instances. A dashed line is the minimum the schedule sets: 2 until 07:30 (10:30 UTC), 6 until 19:00 (22:00 UTC), then 2. A solid line is the desired capacity a policy moves: 6 at 07:30, rising to 9 by late afternoon, cut to 2 at 19:00 by the evening action, then raised again to 6 minutes later and falling back to 2 by 22:00.\"><defs><marker id=\"dy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60 250 L676 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dy-ah)\"></path><path d=\"M60 250 L60 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dy-ah)\"></path><text x=\"52\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"52\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"52\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"52\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"52\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"52\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M60 250 L60 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M247.5 250 L247.5 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"247.5\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">07:30</text><path d=\"M360 250 L360 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M535 250 L535 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"535\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:00</text><path d=\"M660 250 L660 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24:00</text><text x=\"247.5\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10:30 UTC</text><text x=\"535\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22:00 UTC</text><text x=\"676\" y=\"282\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">São Paulo time</text><text x=\"66\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">instances</text><path d=\"M60 208 L247.5 208 L247.5 128 L310 128 L310 108 L360 108 L360 88 L485 88 L485 68 L535 68 L535 208 L542.5 208 L542.5 128 L585 128 L585 168 L610 168 L610 208 L660 208\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M60 212 L247.5 212 L247.5 132 L535 132 L535 212 L660 212\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"372.5\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">minimum, set by the schedule</text><text x=\"385\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">desired, moved by the policy</text><text x=\"547.5\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19:00 cuts to 2; the policy adds back</text><path d=\"M547.5 50 L538.75 202\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dy-ah)\"></path><text x=\"660\" y=\"16\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">illustrative shape, invented load</text></svg>", "caption": "A drawing of the shape, not a measurement: the load behind it is invented. The schedule moves the floor at 07:30 and 19:00 São Paulo time, which are 10:30 and 22:00 in the UTC a cron expression is read in by default. The evening action also sets the desired capacity, which is why the policy has to add back what it had just cut."}
```

## The schedule and the policies share one group

A scheduled action sets numbers, and a target tracking policy keeps moving the desired capacity
between them. The morning action raises the **minimum** to six, so the policy cannot scale below six
during the day however quiet it gets, and it can still scale above. That is the useful
combination: the schedule supplies the floor you can predict, and the policy handles the
part you cannot.

The evening action is the one to look at twice. It sets the desired capacity to two as well as the
minimum. At 19:00, a group that the policy had taken to nine for a busy evening is cut to two,
and the policy adds instances back a few minutes later, once its alarm sees the CPU the cut caused.
**Setting only the minimum in the evening lets the policy decide when to shrink**, which is
usually what was meant. The morning one is different: setting the desired capacity there is the
whole point, because the instances have to be booting before the load arrives.

## What the schedule costs

The morning floor is four instances more than the night's two, for eleven and a half hours, on
about 22 weekdays a month. That is 4 × 11.5 × 22 = 1,012 instance-hours. A `t3.micro` in
São Paulo is 0.0168 USD an hour on demand, on the price sheet of lesson 1 for 16 October 2026,
so the floor costs about 17.00 USD a month. **Whether that is cheap is a question about the
minutes it buys**: the ones every weekday morning in which the reacting policies would otherwise
still be launching.

## One-off actions

A scheduled action can also fire once, with `--start-time` instead of `--recurrence`: a minimum of
twenty from the evening before a sale, with a second action putting it back afterwards. A sale is
the case reacting policies handle worst, because the rise is too steep for the minutes they need,
and the one where the date is known weeks ahead.
