---
title: Rolling a new version through the group
version: 1
---

The wrong picture is that changing the template changes the instances. **It changes what the next
launch looks like, and nothing else.** An instance is launched once, from one version, and keeps
what it was given until it is terminated. Ana makes version 3, the `t3.medium`, the default, and
looks at the group:

```
ana@laptop:~/aws$ aws ec2 modify-launch-template --launch-template-name web --default-version 3 --query LaunchTemplate.DefaultVersionNumber
3
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,InstanceType]" --output text
i-2992055efed5159c1	t3.micro
i-d44b8eadb87097a01	t3.micro
i-e87c31b75179ed4be	t3.micro
```

Three instances, all still `t3.micro`. Each new instance from now on will be a `t3.medium`, so the
group will drift towards the new version as instances happen to be replaced, over hours or weeks,
in an order nobody chose. Rolling it through on purpose is a separate act.

## Instance refresh

**An instance refresh** replaces every instance of a group in batches, waiting for each batch to
be healthy before it starts the next. It is AWS's own answer to "put the new version on every
machine without taking the service down", and its preferences say how careful it is:

- **`MinHealthyPercentage`** is the share of the desired capacity that must stay healthy while it
  works, 90 by default. With ten instances and 90%, it replaces one at a time; with 50%, five.
- **`MaxHealthyPercentage`**, if given, lets it launch new instances before terminating old
  ones, up to that share of the desired capacity. With a minimum of 100% and a maximum of 110% on
  ten instances, it launches one new instance before each old one goes, so capacity never dips.
- **`InstanceWarmup`** is how long, in seconds, a new instance is given after it is in service
  before it counts as ready and the next batch begins.
- **`SkipMatching`** leaves alone the instances already on the desired template version, so a
  refresh that stopped halfway can be started again without replacing what it already replaced.
- **`CheckpointPercentages`** pause the refresh at chosen points, say 20% and 50%, so somebody can
  look before the rest goes, and **`AutoRollback`** returns the group to its previous version if
  the refresh fails.

Here is the command, with the preferences Ana would use:

```
ana@laptop:~/aws$ aws autoscaling start-instance-refresh --auto-scaling-group-name web --preferences '{"MinHealthyPercentage": 90, "InstanceWarmup": 120, "SkipMatching": true}'

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**That error is moto failing, not AWS answering.** moto 5.2.3 does not implement instance refresh:
the request reaches it, its server raises an error, and it answers `500 Internal Server Error`
with an HTML page where the command line expects XML. On AWS the same command returns an
`InstanceRefreshId`, and `describe-instance-refreshes` reports its status (`Pending`,
`InProgress`, `Successful`, `Failed`, `Cancelled` and the states of a rollback) and its percentage
complete. Nothing in this section about the refresh itself was run.

## The same thing by hand

What a refresh does to one instance, moto can show: terminate an old instance, keep the count, and
watch what the group launches in its place.

```
ana@laptop:~/aws$ aws autoscaling terminate-instance-in-auto-scaling-group --instance-id i-2992055efed5159c1 --no-should-decrement-desired-capacity --query Activity.StatusCode --output text
InProgress
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,InstanceType]" --output text
i-d44b8eadb87097a01	t3.micro
i-e87c31b75179ed4be	t3.micro
i-e01965b78caa05cd2	t3.medium
```

The replacement is a `t3.medium`, because version 3 is the default now. **That is one batch of
an instance refresh, with none of its checks**: nothing waited for the new instance to be healthy,
nothing would stop if it were not, and nothing would put the old version back. A refresh is this
step, repeated, with those three things added, which is why the step is worth knowing and why the
refresh is worth using.

## How long it takes

A refresh is slow on purpose, and the arithmetic is worth doing before starting one at five in
the afternoon. Take ten instances, a minimum healthy percentage of 90 and a warmup of 120 seconds.
Batches of one means ten batches. Each batch waits for its instance to launch, boot and pass its
health check, and then 120 seconds more; at three minutes of booting that is five minutes a batch,
and **about fifty minutes for the group**. At 50% it would be two batches and ten minutes, with
half the capacity missing while each runs.

Neither is wrong. The careful setting costs time and the fast one costs capacity, and the group's
headroom (lesson 5) is what decides which one the service can afford.

## Where this stops

A refresh replaces instances in place, inside one group, and the old and new versions serve side
by side until it finishes. Two groups behind one load balancer, switching traffic from one to the
other, is blue/green deployment, and sending a small share first is a canary; both belong to
`aws-operations` lesson 3. The refresh is what you have before either, and for a change of
instance type or image it is often all you need.
