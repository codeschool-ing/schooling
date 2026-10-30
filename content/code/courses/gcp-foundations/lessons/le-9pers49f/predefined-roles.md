---
title: Predefined roles, one service at a time
version: 1
---

**A predefined role is a set of permissions Google defines for one service and one kind of job, and
keeps up to date.** Pub/Sub has a handful, and they show the pattern every service follows:

| role | what its holder does |
|---|---|
| `roles/pubsub.viewer` | lists and reads topics and subscriptions |
| `roles/pubsub.publisher` | publishes messages to topics, and nothing else |
| `roles/pubsub.subscriber` | consumes messages from subscriptions |
| `roles/pubsub.editor` | creates, changes and deletes topics and subscriptions |
| `roles/pubsub.admin` | all of the above, plus managing who may use them |

The pattern is **viewer, a few working roles, editor, admin**, and almost every service in Google Cloud
has the same ladder with its own name in the middle: `roles/compute.instanceAdmin.v1`,
`roles/storage.objectViewer`, `roles/cloudsql.client`. The working roles in the middle are the ones a
workload needs. The planner's order service publishes to `orders` and holds `roles/pubsub.publisher`; the
worker that processes orders consumes them and holds `roles/pubsub.subscriber`; neither can create or
delete a topic, which is the job of the Terraform that defines them.

## Granting on the smallest resource that works

A role can be granted on the organisation, a folder, a project, or, for many services, on a single
resource. `roles/pubsub.publisher` granted on the project lets its holder publish to every topic in it;
granted on the topic `orders`, to `orders` alone. **The smaller the resource, the smaller the mistake**,
and the right resource is the smallest one the job needs:

- on a **resource**, when the job touches one thing: a service that publishes to one topic;
- on a **project**, when the job spans what the project holds: a deployer that updates every service;
- on a **folder**, when the job spans projects: a security team that reads every project in production.

A grant high in the tree reaches everything below it, lesson 2's point, which is exactly why a grant on
the organisation is the one to look at twice.

## Finding the role for a permission

The question that comes up every week is the reverse one: a request was refused for lacking
`pubsub.topics.publish`, so which role has it? Google publishes the full list of roles and their
permissions in its documentation, and `gcloud iam roles describe roles/pubsub.publisher` prints the
permissions of one role. That command asks the IAM API, which the lab cannot answer, so **it was not run
here**; the table above is from Google's documentation of Pub/Sub's access control.

Two things in that documentation are worth knowing before reading it. Some roles have a **launch
stage**, `BETA` or `ALPHA`, and can change without notice; production grants should use roles marked
`GA`. And a role's permissions change over time as Google adds features, **always by addition**: a
predefined role granted today may allow something tomorrow it did not allow when it was granted. That is
the trade the last section of this lesson is about.
