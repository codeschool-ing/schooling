---
title: Compute Optimizer, the same question asked by AWS
version: 1
---

**Compute Optimizer** does at scale what `rightsize.py` did for four instances: it reads CloudWatch metrics
of EC2 instances, auto scaling groups, EBS volumes, Lambda functions, ECS services on Fargate and RDS
databases, and recommends a configuration for each. It is free at its default level, once an account
**opts in**:

```
ana@laptop:~/aws/rightsize$ aws compute-optimizer update-enrollment-status --status Active 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the UpdateEnrollmentStatus operation (reached max retries: 2): <!doctype html>
```

moto has no Compute Optimizer at all, so what follows is from AWS's documentation, not run.

## What it says

Each resource gets a **finding** and up to three **recommendations**:

| finding | meaning |
|---|---|
| over-provisioned | a smaller or cheaper option would carry the load |
| under-provisioned | the resource is short of at least one dimension, as `worker` was |
| optimized | the current configuration fits |

Each recommendation carries the projected utilisation on the new size, a **performance risk** from very
low to very high, and the estimated monthly saving at on-demand prices. **The performance risk is the
column to read first**: a recommendation that saves 40% at high risk is a recommendation to test, not to
apply.

## What it needs

- **Time.** It needs at least 30 hours of metrics before it says anything, and looks back fourteen days by
  default. **Enhanced infrastructure metrics**, a paid option per resource-hour, extend the look-back to
  three months, which matters for a workload with a monthly peak, such as month-end reports.
- **Memory.** As with `rightsize.py`, memory is in the analysis only when the CloudWatch agent publishes
  it. Without it, an EC2 recommendation is about CPU and network, and says so.
- **A different family is in scope.** It recommends across families, Graviton included, which is where
  much of the saving is: in São Paulo's EC2 offer an `m7g.large` is 0.1301 USD an hour and an
  `m7i.large` 0.16065, about 19% more for the same size.

A recommendation is advice computed from history. The change is still made by the team, tested in staging
with the load of a real day, and rolled out like any other change, through lessons 1 to 3.
