---
title: Networks and logs, and what each one does before you touch it
version: 1
---

**The question to ask of any provider's network and logs is not what can be configured but what is
already true on the first day, before anybody configures anything.** Defaults decide what most
accounts look like, because most settings are never changed. This section compares the defaults, from
each provider's documentation; none of it was run.

## The default network lets something in

All three hand a new account or project a network, or let one be made with defaults in a click, and
the defaults are not the same:

| | firewall model | what is allowed before you write a rule |
|---|---|---|
| AWS | **security groups**, stateful and allow-only, plus stateless network ACLs | a default security group that admits traffic from its own members and allows all outbound; lesson 1 found a default VPC in every region |
| Azure | **network security groups**, stateful, with allow and deny rules ordered by priority | default rules that allow all traffic inside the virtual network, traffic from Azure's load balancer, and all outbound to the internet |
| Google Cloud | **VPC firewall rules**, stateful, allow and deny by priority, applied to instances by tag or service account | in the `default` network, pre-made rules allowing SSH and RDP from anywhere, ICMP, and everything internal |

**Google Cloud's `default` network deserves the warning.** Its documented pre-populated rules include
`default-allow-ssh` and `default-allow-rdp`, which admit ports 22 and 3389 from `0.0.0.0/0`. A virtual
machine launched there with a public address answers SSH from the internet without anybody having
written a rule. Google's own guidance is to delete the `default` network in production projects, and
Organization Policy has a constraint, `compute.skipDefaultNetworkCreation`, that stops new projects
from getting one.

The reach differs too, as the `cloud` course's lesson 3 noted: an AWS VPC and an Azure virtual network
belong to one region, while a Google Cloud VPC network is global, with regional subnets. A firewall
rule on a Google network therefore applies in every region the network spans.

## What is recorded before you ask

| | changes to configuration | reading the data itself | kept for |
|---|---|---|---|
| AWS | **CloudTrail event history**, management events, on by default | S3 and other data events: off until a trail is set to record them, and billed | 90 days in event history; longer only in a trail you create |
| Azure | **Activity Log**, per subscription, on by default | resource logs: off until a diagnostic setting sends them somewhere | 90 days for the Activity Log; longer only in a destination you choose |
| Google Cloud | **Admin Activity audit logs**, always on and impossible to turn off | **Data Access audit logs**: off by default, except for BigQuery | 400 days for Admin Activity, in the `_Required` log bucket |

**The column in the middle is the one that hurts after an incident.** At all three, "who changed the
bucket's permissions" is answered by default, and "who read the patients' file" is not, unless
somebody turned that logging on beforehand and paid for it. Lesson 15 is about doing that on AWS and
protecting what is recorded. Sign-ins are a separate log again on Azure: Microsoft Entra ID keeps its
own sign-in and audit logs, apart from the Activity Log.

## The services that watch

| | detects threats in the logs | scores the configuration |
|---|---|---|
| AWS | GuardDuty | Security Hub, with AWS Config rules |
| Azure | Microsoft Defender for Cloud's workload protections | Microsoft Defender for Cloud's posture management |
| Google Cloud | Security Command Center's threat detection | Security Command Center's posture findings |

Each reads only its own provider. **A company on two providers runs two of them, or a third product
that reads both**, which is lesson 4's record seam with a price on it. Lesson 16 is about the
second column, and writes a small version of it.
