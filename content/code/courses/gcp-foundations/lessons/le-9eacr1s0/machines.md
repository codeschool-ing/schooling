---
title: Service accounts, and the ones Google makes for itself
version: 1
---

**A program that calls a Google API needs an identity of its own, and in Google Cloud that identity is
a service account.** It is a principal like a person, written `serviceAccount:...`, and it is also a
resource, living in a project, with its own IAM policy saying who may use it. That double nature is the
whole of lesson 8; here, the names.

| written as | what it is |
|---|---|
| `serviceAccount:reports@planner-dev.iam.gserviceaccount.com` | an account you create, in project `planner-dev` |
| `serviceAccount:415104041262-compute@developer.gserviceaccount.com` | the **default Compute Engine account**, created with the API |
| `serviceAccount:service-415104041262@gcp-sa-pubsub.iam.gserviceaccount.com` | a **service agent**: Pub/Sub's own identity, acting inside your project |

## The ones you create

A service account you create is named `NAME@PROJECT_ID.iam.gserviceaccount.com`, and the name says
what it is for: `reports`, `deployer`, `backup-job`. **One account per workload** is the rule that makes
everything else work: if the reports job and the website share one, a role the reports job needs is a
role the website holds, and a leak of either is a leak of both.

A service account has **no password**. Something proves it is the account in one of three ways, which
lessons 8 and 9 take in turn: Google lends it to a machine or a function it is attached to, a person
with the right role impersonates it for a while, or a downloaded key file is presented. The third is
the one this course keeps calling the last resort.

## The ones Google creates

Two kinds appear in a project without anybody asking, and both surprise people reading a policy for the
first time.

- **Default service accounts.** Enabling Compute Engine creates
  `PROJECT_NUMBER-compute@developer.gserviceaccount.com`, and every virtual machine created without
  naming another account runs as it. In organisations older than the secure-by-default policies of
  lesson 4, it was granted **Editor** on the project automatically, which made every machine an editor of
  everything. The cure is the same in both cases: create an account per workload and name it.
- **Service agents.** When Pub/Sub delivers a message to an endpoint, or Cloud Build writes an image,
  the service acts in your project as an identity of its own, named
  `service-PROJECT_NUMBER@gcp-sa-SERVICE.iam.gserviceaccount.com`. Google grants it the role it needs,
  **Service Agent** roles such as `roles/pubsub.serviceAgent`, when the API is enabled. Removing one
  breaks the service in ways that look like a bug in it; leave them alone unless the documentation of
  that service says otherwise.

Both carry the **project number**, not the id, which is lesson 2's point about who each identifier is
for: these are names Google made, so they use Google's number.

## Deleted principals

A principal that is deleted stays in the policies that named it, rewritten as
`deleted:serviceAccount:reports@planner-dev.iam.gserviceaccount.com?uid=104729...`. The `uid` is there
so that a new account created later with the same name **does not inherit the old one's roles**, which
would otherwise be the way an old grant came back to life. A policy with `deleted:` entries is one that
nobody has tidied, and tidying it is safe.
