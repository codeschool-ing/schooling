---
title: What each one still leaves to you
version: 1
---

A managed platform is easy to read as a promise that there is nothing left to operate. **What it
does is move the work, and the two services move different amounts of it.** Beanstalk builds the
machines and then asks you, through a set of named options, how to deploy onto them, when to
update them and where their logs go. App Runner answers most of those questions itself and leaves
you a shorter list. Neither list is empty, and both are what a team ends up owning on the day
something goes wrong.

None of the behaviour in this section could be run here: moto refused the application version in
the previous section, so there is nothing to deploy and no instance to update. It is described from
AWS's documentation.

## Beanstalk: the options, in one file

Everything Beanstalk lets you choose is an *option* in a *namespace*, and the usual place to write
them is a file in a directory called `.ebextensions` inside the zip of each version. The file
travels with the code, so `v2` and `v3` can disagree and the environment follows whichever is
deployed:

```schooling-example
{"language": "yaml", "file": ".ebextensions/shop.config", "parts": [{"code": "option_settings:\n  aws:elasticbeanstalk:command:\n    DeploymentPolicy: Immutable\n", "note": "How a new version reaches the instances. `Immutable` builds a complete set of new instances beside the old ones and swaps them in only when they are healthy. The table below compares it with the other policies."}, {"code": "  aws:autoscaling:asg:\n    MinSize: 2\n    MaxSize: 4\n", "note": "The auto scaling group of lesson 4, with Beanstalk's names on it. Two instances at least, so a deployment or a failed instance never leaves the shop with none."}, {"code": "  aws:elasticbeanstalk:cloudwatch:logs:\n    StreamLogs: true\n    RetentionInDays: 14\n", "note": "Sends the instances' logs to CloudWatch Logs and keeps them two weeks. Without it the logs live on the instances, and an instance the group replaced takes its logs with it."}, {"code": "  aws:elasticbeanstalk:managedactions:\n    ManagedActionsEnabled: true\n    PreferredStartTime: \"Sun:05:00\"\n  aws:elasticbeanstalk:managedactions:platformupdate:\n    UpdateLevel: minor\n", "note": "Managed platform updates: once a week, in a window that starts at the time given **in UTC**, which is 02:00 on Sunday in São Paulo. `minor` takes minor and patch versions of the platform; a major version is never applied for you."}]}
```

**This file was not run.** moto accepts option settings and keeps none of them, so it could prove
nothing about what they do.

## Deploying: five policies and a swap

`DeploymentPolicy` is the choice that decides what students and customers notice during a release.
AWS documents five values, and they trade the same three things: time, spare instances, and how
much of the old version is left to fall back on.

| policy | during the deployment | to go back |
| --- | --- | --- |
| `AllAtOnce` | every instance at once; the site is down while it happens | deploy the old version again |
| `Rolling` | one batch at a time; capacity drops by a batch | deploy the old version again |
| `RollingWithAdditionalBatch` | an extra batch is launched first, so capacity never drops | deploy the old version again |
| `Immutable` | a full set of new instances beside the old | terminate the new ones |
| `TrafficSplitting` | new instances take a percentage of requests for a set time | stop sending them traffic |

**The last two are the only ones where going back does not mean deploying again**, and that is why
they are the ones to choose for an environment people depend on. The price is time and, for a few
minutes, twice the instances. With `MinSize: 2` on `t4g.medium`, an immutable deployment runs four
instances while it settles, at 4 × 0.0536 = 0.2144 USD an hour instead of 0.1072.

The sixth way is not a policy but a habit: build a second environment with the new version, test
it at its own address, and swap the two environments' addresses with `swap-environment-cnames`.
That is blue/green, and `aws-operations` lesson 3 treats it properly, with canaries, for every kind
of compute.

## Beanstalk: what is still yours

- The platform's lifecycle. Managed updates take minor and patch versions, never a new
  branch. moto's list still carries a Python 3.8 branch on Amazon Linux 2, and Python 3.8 itself
  reached its end of life in October 2024; moving an environment off a branch like that is a change
  you make, test and deploy.
- What you did by hand. Beanstalk replaces instances whenever it deploys immutably, scales or
  heals. A package installed over SSH is gone the next time. Anything an instance needs goes in
  `.ebextensions` or in the `.platform` hooks beside it.
- The resources. The stack is yours and editing it by hand is the classic mistake: change the
  load balancer in the EC2 console and the next configuration change from Beanstalk can put it
  back, or fail half-way because the stack no longer matches.

## App Runner: a shorter list, and a different one

App Runner has no deployment policy to choose. It deploys on its own: the documentation describes
it starting new instances with the new image and doubling the provisioned instances for the
duration, so the old code and the new one serve side by side until the switch. Its logs go to
CloudWatch Logs without being asked. What is left to you is:

- the image, or the code and the runtime it builds with;
- the instance size and the three scaling numbers of section 02;
- the health check, the custom domain and the VPC connector;
- the runtime's end of life, for a service built from source. App Runner's release notes of
  28 August 2025 announced the end of support for specific runtime versions in December 2025. A
  service built on one of them is now on a runtime AWS no longer supports, and moving it is a change
  your team plans, tests and deploys like any other.

**What App Runner hides from you, it also puts out of your reach.** There is no instance to log into,
no daemon running beside the application and no choice of how traffic moves during a release. For
a web application that is the bargain it offers. For anything that needs one of those, it is the
reason to stay on Beanstalk, or to go to ECS from lesson 8.
