---
title: From findings to posture
version: 1
---

**Fixing findings one by one keeps a project clean for a week; posture is what keeps it clean.** Every finding in
the last section came from something somebody was allowed to do: make a bucket public, open a firewall, create a
key. The durable fix removes the permission to create the problem, so that the same finding cannot appear again
next month. Nothing in this section ran; it is from Google's documentation and the course's earlier lessons.

## Prevent, then detect

| the finding | detect (Security Command Center) | prevent |
|---|---|---|
| a public bucket | `PUBLIC_BUCKET_ACL` | the organisation policy `storage.publicAccessPrevention`, and `public_access_prevention = "enforced"` as lesson 6 set on the state bucket |
| a service account key | `SERVICE_ACCOUNT_KEY_NOT_ROTATED` | the organisation policy `iam.disableServiceAccountKeyCreation` |
| SSH open to the internet | `OPEN_FIREWALL` | no firewall rule allowing `0.0.0.0/0` on port 22, reviewed in Terraform plans |
| an unsigned image | (none directly) | Binary Authorization, lesson 4 |
| a data copy out of the project | (none directly) | VPC Service Controls, lesson 19 |

Organisation policies (`gcp-foundations` lesson 4) refuse the change at the moment it is made, for everybody,
including an owner. **A finding that a policy has made impossible never needs triage.** Security Command Center's
**security posture** feature packages a set of such policies and detectors as one declared posture per
organisation or folder, and reports drift from it; the shop, with one project, writes the policies in Terraform
instead, where the same review applies to them as to everything else.

## Detection still matters

Prevention covers what can be anticipated. Threat findings cover what cannot: a valid credential used at an odd
hour, a permission granted by somebody who never grants permissions. Those cannot be prevented by configuration,
because the actions are allowed; they can only be noticed. Two habits make sure they are:

- **A notification on new threat findings**, routed to the on-call channel of lesson 14: Security Command Center can
  publish new findings to a Pub/Sub topic, and a threat finding is exactly the kind of signal that needs a person
  now.
- **A weekly review of the open list**, in the order of the last section, with the mute rules re-read. A list nobody
  reads grows until somebody stops trusting it, which is lesson 14's fatigue, for findings.
