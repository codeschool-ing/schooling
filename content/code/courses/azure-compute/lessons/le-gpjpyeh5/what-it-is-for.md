---
title: "What it is for, and what it leaves out"
version: 1
---

Container Instances is easy to read as a small, cheap way to put a web service on Azure, and the
first deployment encourages it: one command, a public name, the shop answering in under a minute.
**What it runs is one group, kept to its restart policy, and nothing more.** It keeps no count of
copies, starts no second one when the first is busy, rolls out no new version without stopping
the old, and puts no address in front of several groups. Microsoft's own documentation puts it as
"some of the basic scheduling capabilities of orchestration platforms", without the services those
platforms are chosen for. This section is about where that is exactly right, and where it is a
gap you would have to fill yourself. It is read from Microsoft's documentation; nothing in it
needs a subscription to understand.

## What it does well

**Jobs that run and finish.** Microsoft's own first example of the restart policies is the
run-once task: a build, a test run, an image rendered. The shop has two of its own. The nightly
sales report reads the day's orders, writes a file and exits, and the monthly finance export does
the same once a month. Each is a group with `OnFailure`, started on a schedule by something that
can call Azure, such as the Logic App of lesson 19, and billed for the minutes it runs. Nothing is
kept running between nights, so there is nothing to pay for between them.

The report's file has to outlive the group, and the group's own disk does not. That is the Azure
Files share of lesson 3, mounted as a volume. The parts of the report's group that differ from
the shop's:

```yaml
properties:
  osType: Linux
  restartPolicy: OnFailure
  containers:
  - name: report
    properties:
      image: shopregistry.azurecr.io/report:1.0
      resources:
        requests:
          cpu: 1
          memoryInGB: 1
      volumeMounts:
      - name: reports
        mountPath: /reports
  volumes:
  - name: reports
    azureFile:
      shareName: reports
      storageAccountName: shopreportssp
      storageAccountKey: <the storage account's key>
```

No `ipAddress`: a job that nobody calls needs no address. Two things in this file are costs.
**The storage account's key sits in the definition**, which is the reason Microsoft gives for
preferring a template when other resources come with the group: in Bicep the key can be read
from the account at deployment and never written anywhere. And **an Azure Files mount requires
the container to run as root**, by Microsoft's documentation. The shop's image runs as `nobody`,
as `id` showed in section 03, so the report's image is built differently on purpose, and
that is a trade somebody should make knowingly rather than discover.

**Bursts.** A group starts in seconds and is billed by the second, so work that arrives in a heap
and then stops costs the minutes it took. Microsoft is plain about the other side: for long-running,
steady work, containers on a cluster of virtual machines are usually cheaper than the same
containers in Container Instances.

**Build agents.** A continuous-integration job is a container that runs a build and exits, which is
the job case again, and Microsoft's documentation names builds and tests among its own examples.
The three developers' pull requests can each get a group that runs the tests and stops.

**Pods for AKS.** *Virtual nodes* register Container Instances with an AKS cluster as a node of
unlimited capacity. A pod scheduled there runs as a container group, without waiting for the
cluster to add a virtual machine, and is paid for by the second. Lesson 11 builds the AKS side.
Here Container Instances is not the orchestrator. Kubernetes is, and Container Instances is the
capacity it borrows.

## What it leaves out

| you need | a container group gives you | where it is done instead |
|---|---|---|
| more copies when the shop is busy | one group; more groups are yours to create | Container Apps, lesson 8; AKS, lesson 11 |
| a new version with no break in service | an update restarts every container in place | Container Apps revisions, lesson 8; App Service slots, lesson 18 |
| one address in front of several copies | none of its own | a load balancer or an Application Gateway, `azure-foundations` lesson 22 |
| a public IP address that never changes | an address that can change on restart | a DNS label, or an Application Gateway in front |
| the log of last week | 4 MB while running, 16 KB or 1,000 lines once stopped | Log Analytics, `azure-operations` lessons 8 to 13 |
| an `arm64` image | x64 only | the same program, built for `amd64` |

**The update row is the one the shop would feel.** Deploying `shop:1.1` to a running group restarts
its containers in place, and while they restart nobody is answering. With one group there is no
second copy to carry the customers, and no traffic to move gradually. A load balancer can spread
traffic across several groups in a virtual network, and Microsoft documents doing exactly that
with a Standard Load Balancer. Then, though, you are the one creating the groups, counting them,
updating them one at a time and checking each is healthy: the work of an orchestrator, done by
hand.

There is also a short list of things Container Instances will not do at all: no privileged containers,
by Microsoft's FAQ, and a list of ports reserved for the service, 22 and 3389 among them, that a
group should not use. 8080 is not on it.

## NGroups, and the gap closing

Microsoft has started filling the gap from inside the service. **NGroups**, in preview when this
course read the documentation on 30 October 2026, keeps a declared number of container groups
made from one template, a *container group profile*, and adds rolling upgrades, spreading across
availability zones and load balancing. It is the closest Container Instances comes to a service
that runs copies of the shop. Being a preview, it carries no promise that it will reach general
availability in this form, and this course does not lean on it.

## Choosing, for the shop

Put the shop's four workloads against the two lists. **The order API is not a Container
Instances workload**: it serves customers all day, must stay up through a deployment, and will one
day need a second copy. Lesson 8 runs it on Container Apps, which has all three. The nightly report
and the finance export are jobs, and a group with `OnFailure` and a file share is the simplest
thing on Azure that runs them. The developers' test runs are jobs too.

The order API's image is the part that carries on. The `shop:1.0` you built here runs unchanged in
lesson 8, lesson 11 and lesson 18, and lesson 21 puts the four services side by side with
arithmetic. Container Instances is the one with the least between you and the container, which is
its advantage for a job and its weakness for a service.
