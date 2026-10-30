---
title: What App Service is for, beside Container Apps and AKS
version: 1
---

App Service is easy to file as the old way of hosting a website on Azure, the one from before
containers, kept for applications nobody has moved yet. The shop is the counterexample: the
container of lesson 7, unchanged, runs on it, and the last two sections gave it a staging copy and
a release with no break. **What App Service sells is a fixed number of machines for web
applications, rented by the instance, with the release machinery already built.** Container Apps,
lesson 8, sells replicas that come and go with the traffic. AKS, lesson 11, sells a Kubernetes
cluster whose machines you size and pay for. The three can run the same image, and the choice
between them is a choice about how the bill behaves and how much of the platform the team
operates. This section is read from Microsoft's documentation and from the earlier lessons; it has
nothing to run.

## What a plan gives you

**Machines that stay.** A plan's instances run whether or not anybody is calling them, and with
`alwaysOn` the app on them stays loaded. Without it, the documentation says, an app is unloaded
after 20 minutes without a request, and the next caller pays for its warm-up. A web application
with customers through the day, in one time zone, is the case this fits. Its bill is the instance
count times the hours, which is easy to predict and easy to read.

**The release machinery.** Slots, the swap with its warm-up, swap with preview and a rollback that
is one more swap are built into the Standard tier and above, at no extra charge. Container Apps
has the equivalent in revisions and traffic weights, lesson 8, and AKS has whatever the team
installs and maintains for it.

**Features a web application needs and nobody wants to build.** Custom domains with certificates,
including free managed certificates from Basic up; built-in sign-in, which the documentation calls
App Service authentication; Always On; backups; WebJobs for background work beside the app; and
deployment from code, with Microsoft's runtime, for a team that has no Dockerfile yet. A container
is optional on App Service, where on the other two it is the starting point.

## What it costs you

**The plan is paid for when it is idle.** There is no scale to zero on a dedicated tier. Autoscale,
from Standard, and automatic scaling, on Premium v2 to v4, add instances under load and take them
away afterwards, but a plan never has none, and the night in São Paulo is billed like the
afternoon. A revision on Container Apps with a minimum of zero costs nothing while nobody calls it,
lesson 8, and that is the shop's strongest reason to stay there if its nights are empty.

**Slots share production's machines.** Section 02's figure is the cost as well as the saving. A load
test against staging runs on the instances production is serving from. A team that wants staging
on machines of its own gives it a plan of its own, and then a swap is no longer possible, because a
swap is between slots of one app.

**One app, one port, one scale.** App Service sends HTTP to one port of a container,
`WEBSITES_PORT`. On Linux an app may also carry up to nine sidecar containers beside the main one,
sharing its network and scaled with it, which suits a telemetry agent or a cache. Several services
that call each other and each scale on events of their own are what a Container Apps environment
is built for.

**Fewer controls underneath.** There is no Kubernetes API, no node to log into, no choice of how
the load balancer in front behaves. For a web application that is the bargain. For a workload that
needs a scheduler, custom networking per service or an operator from the Kubernetes ecosystem, it
is the reason AKS exists.

## The four, side by side

| | Container Instances, lesson 7 | App Service, this lesson | Container Apps, lesson 8 | AKS, lesson 11 |
| --- | --- | --- | --- | --- |
| what you rent | one group, by the second | a plan's instances, for as long as they exist | replicas, by the second, or dedicated nodes | node VMs, plus the control plane's tier |
| idle | a stopped group costs nothing | the plan's instances, all night | nothing, with a minimum of zero | the nodes still run |
| a new version | a restart in place | a swap between slots, warmed first | a new revision, traffic by weight | what the cluster runs: a rolling update by default |
| several services | one group | one app per service, on shared plans | apps in one environment, on one network | anything Kubernetes can describe |
| what the team operates | almost nothing | the plan's size and count | the environment and its scale rules | the cluster, its upgrades and its add-ons |

**Read the second row first.** For a service that answers customers all day, the idle row costs
little whichever column it is; for one that is quiet half the day, it decides most of the bill.
Lesson 21 puts the shop's real request profile against all four with arithmetic, and that is the
place to decide with numbers. Here the decision is about shape.

## For the shop

The order API fits App Service well. Its customers arrive through the day, it is one web
application on one port, and what the team wanted in lesson 7, a new version with no break and a
way back, is a swap and a second swap. A `P1v3` plan of two instances, zone redundant, carries it,
the staging slot costs nothing beyond the capacity it takes, and the developers test at the slot's
address before each release. The admin site can share the plan while it stays small.

The nightly sales report and the finance export are not App Service work. A plan billed all day
for a job that runs ten minutes a night is the wrong shape; they stay the container groups of
lesson 7, or become Container Apps jobs. And the day the shop splits into several services that
call each other, scale on queue length, and want to go quiet at night, it has grown into what lesson
8 describes. The image moves with it unchanged: `shop:1.1` is the same image on a laptop, on a
slot, in a revision and in a pod.
