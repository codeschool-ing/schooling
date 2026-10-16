---
title: "Fargate Spot: the same task, cheaper, until AWS wants it back"
version: 1
---

Fargate Spot is Fargate run on capacity AWS has spare, at a discount, with one condition: **AWS
can take the capacity back, and gives the task two minutes' warning when it does.** Lesson 6 made
the same bargain for EC2 instances. Here the unit taken back is a task, and nothing about the task
definition changes: the same image, the same size, the same network. What changes is that a
service using it has to be one where losing a task now and then is ordinary.

The discount is not on the price sheet, because AWS's price list publishes Fargate Spot's rate
separately and it moves with spare capacity. **AWS describes it as up to 70% off the Fargate
price**, and this lesson quotes no figure beyond that.

## Choosing it: a capacity provider strategy

Fargate Spot is not a launch type. It is the capacity provider `FARGATE_SPOT`, and a cluster has
to list it before a service can use it:

```
ana@laptop:~/aws$ aws ecs put-cluster-capacity-providers --cluster shop --capacity-providers FARGATE FARGATE_SPOT --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 --query "cluster.capacityProviders" --output text
FARGATE	FARGATE_SPOT
ana@laptop:~/aws$ aws ecs create-service --cluster shop --service-name worker --task-definition web-fargate --desired-count 5 --capacity-provider-strategy capacityProvider=FARGATE,base=1,weight=1 capacityProvider=FARGATE_SPOT,weight=3 --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG]}" --query "service.[serviceName,desiredCount,capacityProviderStrategy]" --output text
worker	5	None
```

The strategy is lesson 8's arithmetic: `base=1` keeps the first task on ordinary Fargate whatever
happens, and the weights of 1 and 3 put one in four of the rest there too. With five tasks, that
is two on `FARGATE` and three on `FARGATE_SPOT`; with the service scaled to 41, it is eleven and
thirty. **The base is the floor that interruption cannot touch**, so it is sized for the load the
service must carry while Spot tasks are being replaced, not for the average.

moto stored the service and answered `None` for its strategy, so it has not kept even the record
of what the command asked. On AWS the service's `capacityProviderStrategy` comes back as given, and
each task it starts names the provider it ran on.

## What the interruption looks like

When AWS reclaims the capacity, ECS does three things, and none of them can be shown with moto:

1. It sends an event, `ECS Task State Change`, to EventBridge, with the stop code
   `SpotInterruption`. That is the signal to act on from outside the task, and lesson 21 is
   EventBridge.
2. It stops the task the way any task is stopped: **the container's main process receives
   `SIGTERM`, and after the container definition's `stopTimeout`, `SIGKILL`.** On Fargate the
   timeout may be set as high as 120 seconds, which is the whole of the warning.
3. A service, seeing a task gone, starts a replacement, on whichever provider its strategy says,
   Spot again if Spot has room.

So the part your code owns is the second step, and it can be tried on your own machine with
Docker. The image `nginx:1.29-alpine` contains a shell, and a shell can stand in for a worker: it
says it is working, and on `SIGTERM` it saves and exits.

Before running it, one detail of the image:

```
ana@laptop:~/aws$ docker image inspect --format "{{.Config.StopSignal}}" nginx:1.29-alpine
SIGQUIT
```

**An image can name its own stop signal**, and nginx's does: `SIGQUIT` is nginx's graceful
shutdown. Docker sends that signal instead of `SIGTERM` when it stops the container, so the runs
below set `--stop-signal SIGTERM` to make the shell receive the one this section is about. Check
what your own image declares the same way before trusting a `SIGTERM` handler.

A worker that finishes inside the timeout:

```
ana@laptop:~/aws$ docker run -d --name job --stop-signal SIGTERM nginx:1.29-alpine sh -c "trap 'echo SIGTERM: saving; sleep 3; echo saved, exiting; exit 0' TERM; echo working; while true; do sleep 1; done" > /dev/null
ana@laptop:~/aws$ time docker stop -t 120 job
job

real	0m4.213s
user	0m0.004s
sys	0m0.029s
ana@laptop:~/aws$ docker logs job
working
SIGTERM: saving
saved, exiting
ana@laptop:~/aws$ docker inspect --format "{{.State.ExitCode}}" job
0
```

`docker stop -t 120` is the same 120 seconds Fargate allows. The handler ran, took its three
seconds and exited with status 0. The stop took about four seconds, not 120: **the timeout is
a ceiling, and a process that exits sooner is not kept waiting.**

A worker that needs longer than it is given:

```
ana@laptop:~/aws$ docker run -d --name job --stop-signal SIGTERM nginx:1.29-alpine sh -c "trap 'echo SIGTERM: saving; sleep 30; echo saved' TERM; while true; do sleep 1; done" > /dev/null
ana@laptop:~/aws$ time docker stop -t 5 job
job

real	0m5.606s
user	0m0.019s
sys	0m0.060s
ana@laptop:~/aws$ docker logs job
SIGTERM: saving
ana@laptop:~/aws$ docker inspect --format "{{.State.ExitCode}}" job
137
```

The handler started, `SIGKILL` arrived at five seconds, and `saved` was never printed. Exit
status 137 is 128 plus 9, the number of `SIGKILL`, and it is what a stopped task's container
reports when its process was killed rather than finished.

## What can live on Spot

The two runs are the whole design rule. **Work that can stop within `stopTimeout` and start again
elsewhere belongs on Spot.** That covers web tasks behind a load balancer, which drain their
connections and go; queue workers, which stop taking messages and let unfinished ones become visible again, as
lesson 21's visibility timeout arranges; batch jobs that write a checkpoint every few minutes.
Work that cannot, a task holding the only copy of a session or a job of an hour that starts over
from zero, belongs on `FARGATE`, in the base or in a service of its own.
