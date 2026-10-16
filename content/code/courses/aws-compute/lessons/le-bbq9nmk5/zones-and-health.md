---
title: Zones, health checks and the replacement
version: 1
---

The group of the previous section was given three subnets in three zones. **On AWS that is an
instruction to spread**: the group launches its instances evenly across the zones it can use, and
works to keep them even. Here is where moto put the three instances it is keeping now:

```
ana@laptop:~/aws$ aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=web Name=instance-state-name,Values=running --query "Reservations[].Instances[].[InstanceId,Placement.AvailabilityZone,SubnetId]" --output table
-------------------------------------------------------------------
|                        DescribeInstances                        |
+----------------------+-------------+----------------------------+
|  i-2992055efed5159c1 |  sa-east-1a |  subnet-a320d80c3247aca2b  |
|  i-8e6c6519b05e2cbc1 |  sa-east-1a |  subnet-a320d80c3247aca2b  |
|  i-d44b8eadb87097a01 |  sa-east-1a |  subnet-a320d80c3247aca2b  |
+----------------------+-------------+----------------------------+
```

All three are in `sa-east-1a`, in the first subnet of the list. **That placement is moto's, not
AWS's.** moto 5.2.3 launches every instance of a group into its first subnet, however many it is
given. On AWS the same group would hold one instance in each of `sa-east-1a`, `sa-east-1b` and
`sa-east-1c`, and with six it would hold two in each. Nothing else in this lesson depends on the
zone, so the rest of the lab is still faithful; the arithmetic below is AWS's.

## What balancing buys, and when it moves instances

The reason to spread is that a zone can fail on its own. `aws-foundations` lesson 1 says what a
zone is. For a group, it means that when one zone is impaired, the instances there stop passing
their health checks and the group replaces them, in the zones that still work. A group of six across three zones that loses one zone is a group of four for a few minutes,
and a group of six again once the replacements are serving.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Three panels of a group of six over three zones. Before: two instances in each of sa-east-1a, 1b and 1c. Zone b impaired: its instances are replaced in the other two zones, three in 1a and three in 1c. Zone b back: AZRebalance launches in 1b and then terminates in the others, two in each again.\"><defs><marker id=\"az-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">before</text><rect x=\"16\" y=\"40\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"28\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"92\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"16\" y=\"132\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"28\" y=\"160\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"92\" y=\"160\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"16\" y=\"224\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"28\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"92\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><path d=\"M228 178 L248 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#az-ah)\"></path><text x=\"356\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">zone b impaired</text><rect x=\"252\" y=\"40\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"264\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"292\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"328\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"356\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"392\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"252\" y=\"132\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"262\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sa-east-1b</text><text x=\"356\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">impaired</text><rect x=\"252\" y=\"224\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"264\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"292\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"328\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"356\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"392\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><path d=\"M464 178 L484 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#az-ah)\"></path><text x=\"592\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">zone b back, rebalanced</text><rect x=\"488\" y=\"40\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"500\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"528\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"564\" y=\"68\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"592\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"488\" y=\"132\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"500\" y=\"160\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"528\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"564\" y=\"160\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"592\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"488\" y=\"224\" width=\"208\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"500\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"528\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><rect x=\"564\" y=\"252\" width=\"56\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"592\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">running</text><text x=\"360\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the replacements go where the group can launch; rebalancing launches first, then terminates</text></svg>", "caption": "A group of six over three zones, on AWS. The group keeps the count, not the places: losing a zone moves its share into the zones that work, and AZRebalance moves it back afterwards without letting the count fall. moto, as the transcript above shows, would put all six in sa-east-1a."}
```

When the zone recovers, the group is unbalanced: three, none, three. A process called
**`AZRebalance`** puts it right, and it does it in the order that keeps capacity up. **It launches
in the thin zone first and terminates in the full ones afterwards.** To make room, AWS lets the
group exceed its maximum during a rebalance, by 10% of it or by one instance, whichever is larger.
The same process moves instances when you add a subnet to the group, or when a zone did not have
capacity for the instance type at launch.

## Two ways of asking whether an instance is healthy

The group asks about every instance, periodically, and it has two sources of answers.

- **`EC2`** is the default: the instance's status checks. They ask whether the hardware under it
  and the operating system on it are working, and they catch a failed host or a kernel that
  stopped. They do not catch a web server that crashed on a machine that is otherwise fine.
- **`ELB`** adds the load balancer's health check. The target group requests a path such as
  `/health` on each instance, and an instance that stops answering is marked unhealthy. That is
  the check that sees what a user sees, and a group behind a load balancer should use it;
  `aws-foundations` lesson 22 builds the load balancer and its target group.

Both sources count: with `ELB` set, an instance failing either one is unhealthy. Ana's group has
the default:

```
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web --query "AutoScalingGroups[].[HealthCheckType,HealthCheckGracePeriod]" --output text
EC2	300
```

The second number is the **health check grace period**: how many seconds after an instance comes
into service the group ignores its health checks. A new instance spends its first minutes booting
and running its user data, and fails every check while it does. **A grace period shorter than the
boot is a group that kills each new instance before it is ready, and launches another, forever.**
moto shows 300 seconds because it defaults to 300. AWS's API defaults to 0 when the call leaves it
out, and the console fills in 300, so a group created from a script without one starts with no
grace at all. Lesson 5 meets a second setting with a similar purpose, the default instance warmup,
and says how the two differ.

## An unhealthy instance is replaced, not repaired

**When an instance is found unhealthy, the group terminates it and launches another from the
template.** Nobody logs in to fix it, because there is nothing on it worth fixing: whatever it held
that mattered was supposed to live somewhere else. `set-instance-health` lets a person, or a
monitoring script, declare an instance unhealthy, and here is what moto does with it:

```
ana@laptop:~/aws$ aws autoscaling set-instance-health --instance-id i-8e6c6519b05e2cbc1 --health-status Unhealthy
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,HealthStatus]" --output text
i-8e6c6519b05e2cbc1	Unhealthy
i-2992055efed5159c1	Healthy
i-d44b8eadb87097a01	Healthy
```

moto writes the word down and does nothing else. **On AWS that instance would be gone within a
minute or so, and a new one would be launching in its place.** The replacement itself is something
moto does do, through the call that terminates an instance and keeps the count:

```
ana@laptop:~/aws$ aws autoscaling terminate-instance-in-auto-scaling-group --instance-id i-8e6c6519b05e2cbc1 --no-should-decrement-desired-capacity --query 'Activity.[StatusCode,Cause]' --output text
InProgress	At 2026-10-16 16:26:01.573069, instance i-8e6c6519b05e2cbc1 was taken out of service in response to a user request.
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,HealthStatus]" --output text
i-2992055efed5159c1	Healthy
i-d44b8eadb87097a01	Healthy
i-e87c31b75179ed4be	Healthy
```

`--no-should-decrement-desired-capacity` is the part that matters: it terminates the instance and
leaves the desired capacity at three, so the group launches a replacement straight away, and a
new id takes the old one's place at the end of the list. With `--should-decrement-desired-capacity` the count
would drop to two instead, and nothing would replace it.

## When the replacing is the problem

A group that keeps replacing instances is sometimes doing exactly what it was told, about the wrong
thing. An application that crashes on start, a health check path that does not exist, a grace
period shorter than the boot: each one produces a loop of launches and terminations, and every
launch is billed for at least a minute. For the hour somebody needs to look at an instance in that
state, `suspend-processes` stops named parts of the loop (`HealthCheck`, `ReplaceUnhealthy`,
`Launch`, `Terminate`, `AZRebalance`), and `resume-processes` starts them again. **Suspending
replacement is for investigating, never for running**, because a suspended group no longer keeps
its promise.
