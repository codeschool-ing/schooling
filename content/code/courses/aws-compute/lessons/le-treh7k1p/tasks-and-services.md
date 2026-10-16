---
title: "Tasks and services: once, or always N"
version: 1
---

There are two ways to ask ECS for a task, and they differ in what happens when the task ends.
**`run-task` starts tasks and forgets them**: when the container exits, for any reason, the task
stops and nothing starts another. **A service holds a number**: keep this many tasks of this
revision running, and when one stops, start a replacement. It is the same promise an auto scaling
group makes about instances in lesson 4, made about tasks.

So the choice is not about size or importance. A nightly export, a database migration or a report
that runs for twenty minutes and exits is a `run-task`, and a service would be wrong for it,
because a service would restart it the moment it finished. A web front that must answer at three
in the morning is a service.

## What moto shows, and what it cannot

The cluster below has one container instance, which the next section explains. Running the
definition once:

```
ana@laptop:~/aws$ aws ecs run-task --cluster shop --task-definition web --query "tasks[0].[lastStatus,containers[0].lastStatus]" --output text
RUNNING	PENDING
ana@laptop:~/aws$ aws ecs describe-container-instances --cluster shop --container-instances "$CI" --query "containerInstances[0].[runningTasksCount,remainingResources[?name==\`CPU\`||name==\`MEMORY\`].integerValue]" --output text
1
3840	6970
```

**moto records the task as `RUNNING` and its container as `PENDING`, and nothing is running at
all.** moto has no agent and no Docker: the task is a row with a state, and the state never moves
on. What the second command shows is real bookkeeping. The instance had 256 CPU units and 512 MiB
less to offer after the task was placed, exactly what the definition reserved, because ECS
places tasks by subtracting what they ask for from what each instance has left.

A service, asked for three:

```
ana@laptop:~/aws$ aws ecs create-service --cluster shop --service-name web --task-definition web:2 --desired-count 3 --deployment-configuration minimumHealthyPercent=50,maximumPercent=200 --query "service.[desiredCount,runningCount,pendingCount]" --output text
3	0	3
ana@laptop:~/aws$ aws ecs list-tasks --cluster shop --query "length(taskArns)"
1
ana@laptop:~/aws$ aws ecs describe-services --cluster shop --services web --query "services[0].deploymentConfiguration"
null
```

The service says it wants 3, has 0 running and 3 pending, and moto never starts them: the one
task in the cluster is the `run-task` from before. moto also returned no
`deploymentConfiguration` at all, although the command set one. **On AWS the scheduler starts
three tasks, spreads them across the instances it can, and starts a fourth whenever one of them
stops.** That loop is the whole value of a service, and it is the part of this lesson that moto
cannot run. The fifth section runs one task's container for real, on your own machine.

## Deploying a new revision

A service is pointed at one revision. Changing that is a deployment, and it is shaped by the two
numbers the command above passed, both percentages of the desired count:

- `maximumPercent` is how many tasks may exist at once during the change. 200 with a desired
  count of 4 allows 8.
- `minimumHealthyPercent` is how many must keep serving throughout. 50 with 4 allows ECS to
  drop to 2.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 312\" role=\"img\" aria-label=\"Two rolling deployments of a service with a desired count of 4. With minimum 100 percent and maximum 200 percent, four new tasks start beside the four old ones, and the old ones stop once the new ones are healthy: never fewer than 4 running, up to 8 tasks at once. With minimum 50 percent and maximum 100 percent, two old tasks stop first, two new ones start, then the other two old ones are replaced: never more than 4 tasks, as few as 2 running.\"><rect x=\"12\" y=\"18\" width=\"696\" height=\"124\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">room to spare: start the new ones first</text><text x=\"694\" y=\"36\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minimumHealthyPercent 100, maximumPercent 200</text><rect x=\"59.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"83.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"107.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"131.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 serving</text><path d=\"M190.0 62 L190.0 110\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"229.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"253.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"277.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"301.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"229.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"253.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"277.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"301.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"275.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 serving</text><path d=\"M360.0 62 L360.0 110\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"399.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"423.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"447.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"471.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"399.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"423.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"447.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"471.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">8 serving</text><path d=\"M530.0 62 L530.0 110\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"569.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"593.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"617.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 serving</text><rect x=\"12\" y=\"156\" width=\"696\" height=\"124\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">no room: stop half, then replace</text><text x=\"694\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minimumHealthyPercent 50, maximumPercent 100</text><rect x=\"30.666666666666657\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"54.66666666666666\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"78.66666666666666\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"102.66666666666666\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"76.66666666666666\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 serving</text><path d=\"M133.33333333333331 200 L133.33333333333331 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"167.99999999999997\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"191.99999999999997\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"189.99999999999997\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 serving</text><path d=\"M246.66666666666663 200 L246.66666666666663 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"257.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"281.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"305.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"329.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"303.3333333333333\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 serving</text><path d=\"M360.0 200 L360.0 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"370.6666666666667\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"394.6666666666667\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"418.6666666666667\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"442.6666666666667\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416.6666666666667\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 serving</text><path d=\"M473.33333333333337 200 L473.33333333333337 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"484.0\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"508.0\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"532.0\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"556.0\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 serving</text><path d=\"M586.6666666666666 200 L586.6666666666666 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"597.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"621.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"645.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"669.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"643.3333333333333\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 serving</text><rect x=\"150\" y=\"285\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"184\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">old revision</text><rect x=\"320\" y=\"285\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"354\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">new, starting</text><rect x=\"490\" y=\"285\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"524\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">new revision</text></svg>", "caption": "A service's deployment is two percentages of its desired count. The maximum says how many tasks may exist at once, the minimum how many must keep serving; between them they decide whether new tasks start before old ones stop or after."}
```

**The two numbers decide whether you pay for capacity or for risk.** Room to spare starts the new
tasks first, so serving never drops, but the cluster must hold twice the tasks for a while; on
instances you run, that is spare instances. No room stops half the old tasks first, so the
cluster holds no more than it does on an ordinary day, and for the length of the deployment half
the capacity serves all the traffic. The AWS defaults are 100 and 200.

ECS replaces a task only when its replacement is healthy, which with a load balancer in front, as
`aws-foundations` lesson 22 built, means passing the target group's health check. A revision that
never becomes healthy would be retried for ever; the **deployment circuit breaker**, switched on
in the service's deployment configuration, stops after repeated failures and can roll the service
back to the last revision that worked. Blue/green and canary deployments, which shift traffic
rather than tasks, are `aws-operations` lesson 3.

In moto the deployment is accepted and does not happen:

```
ana@laptop:~/aws$ aws ecs register-task-definition --cli-input-json file://web.json --query taskDefinition.revision
3
ana@laptop:~/aws$ aws ecs update-service --cluster shop --service web --task-definition web:3 --query "service.[taskDefinition,deployments[].[status,taskDefinition]]" --output text
web:3
PRIMARY	arn:aws:ecs:sa-east-1:123456789012:task-definition/web:2
```

The service now names `web:3`, and its only deployment is still the one for `web:2`. On AWS the
same call creates a new `PRIMARY` deployment for `web:3` and turns the old one `ACTIVE` while
its tasks drain.

## Removing a service

```
ana@laptop:~/aws$ aws ecs delete-service --cluster shop --service web

aws: [ERROR]: An error occurred (InvalidParameterException) when calling the DeleteService operation: The service cannot be stopped while it is scaled above 0.
ana@laptop:~/aws$ aws ecs update-service --cluster shop --service web --desired-count 0 --query service.desiredCount
0
ana@laptop:~/aws$ aws ecs delete-service --cluster shop --service web --query service.status --output text
INACTIVE
```

ECS refuses to delete a service that still wants tasks, so the desired count goes to 0 first.
That refusal is AWS's behaviour too, and `--force` skips it. The order is worth keeping: a
service at 0 stops its tasks cleanly, and deleting it afterwards removes only the record.
