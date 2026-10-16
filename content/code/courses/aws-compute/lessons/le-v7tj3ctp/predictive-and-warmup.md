---
title: Predictive scaling, and the minutes an instance needs
version: 1
---

A schedule is a forecast written by a person. **Predictive scaling is a forecast written by AWS**:
it reads the group's own history of load, finds the daily and weekly pattern in it, and launches
instances ahead of the rise it expects. It is a schedule that rewrites itself, and it helps
exactly as much as the load repeats.

## What AWS documents about it

None of this section's predictive part was run, because moto has neither the history nor the
forecast. According to AWS's documentation:

- a predictive policy needs at least 24 hours of metric history before it forecasts anything, and
  reads up to 14 days of it;
- it forecasts the next 48 hours, hour by hour, and makes a new forecast every 6 hours;
- in `ForecastOnly` mode it forecasts and does nothing else, which is how to find out whether the
  forecast is any good before letting it act; in `ForecastAndScale` it raises the group's minimum
  capacity ahead of each forecast hour;
- `SchedulingBufferTime` says how many seconds early to launch, which is the boot time it is
  buying;
- it does not scale in on its own. It works beside a target tracking policy: the forecast lifts the
  floor before the rise, and the dynamic policy handles what the forecast missed.

In the lab the policy can be created, in the mode to start with, and its forecast cannot be read:

```
ana@laptop:~/aws$ aws autoscaling put-scaling-policy --auto-scaling-group-name web --policy-name forecast --policy-type PredictiveScaling --predictive-scaling-configuration '{"MetricSpecifications": [{"TargetValue": 50, "PredefinedMetricPairSpecification": {"PredefinedMetricType": "ASGCPUUtilization"}}], "Mode": "ForecastOnly"}'
ana@laptop:~/aws$ aws autoscaling get-predictive-scaling-forecast --auto-scaling-group-name web --policy-name forecast --start-time 2026-10-19T00:00:00Z --end-time 2026-10-20T00:00:00Z

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

`put-scaling-policy` is silent as before, and `get-predictive-scaling-forecast` is another call
moto does not implement. **On AWS that call returns the forecast load and the forecast capacity**,
hour by hour for the period asked, and it is what to look at for a week in `ForecastOnly`, against
what actually happened, before switching the mode.

A load that is spiky but not periodic gains nothing from it. A forecast is a pattern projected
forward, and a launch announced on social media at a time nobody chose is not in any pattern.

## The minutes an instance needs

Every policy above counts instances, and a new instance is not useful the moment it exists. It
boots, runs its user data, starts the application and fills its caches, and during that time its
metrics are misleading: its CPU may sit at 100% while it starts, or near zero because nothing is
sent to it yet. Counted in the group's average either way, it distorts the very number the policy
is steering by.

**The default instance warmup is the time, after an instance comes into service, during which its
metrics are left out of the group's aggregate.** Step and target tracking policies use it to avoid
scaling out again for a rise that the warming instances are about to absorb, and an instance
refresh (lesson 4) uses it as the warmup between batches when none is given. AWS recommends
setting it on every group, to the time the application really takes to be ready.

It is not the same thing as two settings it is easily confused with:

| setting | what it decides |
| --- | --- |
| health check grace period | how long before a failed health check counts against a new instance |
| default instance warmup | how long before a new instance's metrics count in the group's average |
| cooldown | how long a simple scaling policy waits before acting again |

The group of this lesson was created with a warmup of 180 seconds. Here is what moto kept:

```
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].{grace: HealthCheckGracePeriod, warmup: DefaultInstanceWarmup, cooldown: DefaultCooldown}"
[
    {
        "grace": 300,
        "warmup": null,
        "cooldown": 300
    }
]
```

**`null` is moto discarding the setting.** It accepted `--default-instance-warmup 180` without an
error and stored nothing; on AWS the same description shows `DefaultInstanceWarmup` as 180. The
grace period and the cooldown are moto's defaults, 300 each, which lesson 4 already compared with
AWS's.

## Shortening the minutes instead of waiting for them

Warmup tells the policies to be patient. The other direction is to need less patience. A baked
image (lesson 2) boots ready instead of installing at boot (lesson 7), and a **warm pool** keeps a
number of instances already launched and then stopped, so that a scale-out starts one in seconds
rather than booting a new one from nothing. A stopped instance in the pool costs its EBS volumes
and not its hours. Warm pools were not exercised here; lesson 6 meets the other way of getting
capacity cheaply, which is to accept that AWS may take it back.
