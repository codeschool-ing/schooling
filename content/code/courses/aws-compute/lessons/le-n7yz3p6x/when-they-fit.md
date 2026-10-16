---
title: When they fit, and when to leave
version: 1
---

**A platform service fits when the application is ordinary and the team is small.** Ordinary means
a web application that answers HTTP requests, keeps its state in a database and its files in S3,
and can be started on any machine from the same image or the same zip. Small means that nobody's
job is the platform: three developers who would rather ship the shop's next feature than tune an
auto scaling group. For that pair, the hours a managed platform saves are worth more than the
control it takes.

The mistake in the other direction is to treat these services as a beginner's tool to grow out of
on principle. A team that moves a working Beanstalk application to Kubernetes because it is what
larger companies run has bought a cluster, an upgrade every year (lesson 11) and a platform job
somebody now has to do, and the shop sells exactly what it sold before.

## The choice in October 2026

For an account opened today the field is narrower than this lesson's title suggests, because App
Runner is closed to new customers:

| | it suits | it costs you |
| --- | --- | --- |
| **Elastic Beanstalk** | a web app or a queue worker on EC2, with SSH when you need to look | the platform's lifecycle and a stack you must not edit by hand |
| **ECS Express Mode** | a container that should be a web service with one call | a load balancer and the Fargate prices of lesson 9 |
| **ECS on Fargate, built yourself** | anything the two above do not offer | the task definition, the network and the service of lessons 8 and 9 |
| **App Runner** | existing customers only | memory for every provisioned instance, all month |

Beanstalk's *worker* environment is the one line in that table the earlier sections did not show:
instead of a load balancer, its instances read messages from an SQS queue (lesson 21) and post each
one to your application over HTTP, so a background job runs on the same platform as the site.

**ECS Express Mode is the service AWS points App Runner's customers to**, and the command line of
this course already knows it. Its skeleton lists what one call takes:

```
ana@laptop:~/aws$ aws ecs create-express-gateway-service --generate-cli-skeleton | jq -c keys
["cluster","cpu","cpuArchitecture","executionRoleArn","healthCheckPath","infrastructureRoleArn","memory","networkConfiguration","primaryContainer","scalingTarget","serviceName","tags","taskDefinitionArn","taskRoleArn"]
```

The API documentation describes the call as provisioning the Application Load Balancer, the target
groups, the security groups and the scaling policies for you. That makes it App Runner's idea built
from parts you can see, the same move Beanstalk made for EC2. moto 5.2.3 does not implement it and
answers a 500, so this course goes no further with it than the skeleton; lessons 8 and 9 build by
hand everything it would build.

## When to leave

The signal to leave a platform service is rarely its price. It is the day the application stops
being ordinary, and it tends to arrive as one of these:

- a second and a third service that have to call each other privately, with their own scaling
  and releases. A platform built around one application starts to show its seams;
- a release that needs more than the platform offers: a canary on one customer's traffic, a
  migration that has to run before the new code, a rollback that has to be instant;
- something the instances must run beside the application: an agent, a sidecar, a GPU, a
  process listening on a second port. App Runner offers none of these, and Beanstalk offers them
  through hooks that grow until they are a platform of their own;
- a steady load around the clock, where lesson 23's arithmetic says a reserved or Savings Plan
  price on plain instances or Fargate is cheaper than the convenience;
- somebody editing the generated resources by hand because the options no longer reach what
  they need. That is the stack telling you it is already yours.

## Leaving cheaply

**What makes the exit cheap is decided on the first day, not the last.** An application that
arrives at App Runner as an image in ECR leaves as the same image, into a task definition of
lesson 8. One that arrives at Beanstalk as a zip built by a `Procfile` and three files in
`.ebextensions` leaves with those files to translate, one option at a time. Three habits do most of
it. Keep the state outside the instances, which any group of lesson 4 may replace. Keep the
configuration in environment variables. And build an image even where the platform would build one
for you. With those, either service becomes something you can walk away from in a week. Lesson 24 makes that a decision you write down; lesson 23 puts the
running costs of all of these side by side.
