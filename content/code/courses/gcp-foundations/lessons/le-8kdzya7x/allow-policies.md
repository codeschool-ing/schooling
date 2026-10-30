---
title: An allow policy, read from top to bottom
version: 1
---

**Every resource that accepts grants carries one allow policy, and the policy is a list of bindings.**
A binding joins one role to the principals that hold it, and may carry a condition. That is the whole
data structure, and reading one is the first IAM skill worth having. This is what a project's policy
looks like in Google's documented format, written for this course rather than read from a project:

```json
{
  "version": 3,
  "etag": "BwYdKxXQ0aU=",
  "bindings": [
    {
      "role": "roles/pubsub.publisher",
      "members": [
        "serviceAccount:orders@planner-dev.iam.gserviceaccount.com"
      ]
    },
    {
      "role": "roles/viewer",
      "members": [
        "group:planner-devs@example.com",
        "user:ana@example.com"
      ]
    },
    {
      "role": "roles/pubsub.editor",
      "members": [
        "group:planner-oncall@example.com"
      ],
      "condition": {
        "title": "during the incident",
        "expression": "request.time < timestamp('2026-11-01T00:00:00Z')"
      }
    }
  ]
}
```

| field | what it says |
|---|---|
| `bindings` | one entry per role; a role appears once, with every principal that holds it |
| `members` | the principals of lesson 5, each with its prefix |
| `condition` | when the binding applies: here, the on-call group holds Editor on Pub/Sub until 1 November |
| `version` | `3` when any binding has a condition; a client that sends version 1 drops the conditions silently |
| `etag` | the version of the policy this copy was read at, which the next paragraph is about |

## Read, change, write, and the etag

**A policy is changed by replacing it whole.** There is no API call that adds one member; a client reads
the policy, adds the member to its copy, and writes the copy back. `gcloud ... add-iam-policy-binding`
does exactly that in one command, and the lab shows the first half of it. The emulator answers Pub/Sub
but not IAM, and it says so:

```
ana@laptop:~/gcp$ gcloud pubsub topics create orders
Created topic [projects/planner-dev/topics/orders].
ana@laptop:~/gcp$ gcloud pubsub topics get-iam-policy orders
ERROR: (gcloud.pubsub.topics.get-iam-policy) HttpError accessing <http://localhost:8085/v1/projects/planner-dev/topics/orders:getIamPolicy?alt=json>: response: <{'content-type': 'application/json', 'content-length': '47', 'status': 501}>, content <{"error":{"code":501,"status":"UNIMPLEMENTED"}}>
This may be due to network connectivity issues. Please check your network settings, and the status of the service you are trying to reach.
ana@laptop:~/gcp$ gcloud pubsub topics add-iam-policy-binding orders --member=group:planner-devs@example.com --role=roles/pubsub.publisher
ERROR: (gcloud.pubsub.topics.add-iam-policy-binding) HttpError accessing <http://localhost:8085/v1/projects/planner-dev/topics/orders:getIamPolicy?alt=json>: response: <{'content-type': 'application/json', 'content-length': '47', 'status': 501}>, content <{"error":{"code":501,"status":"UNIMPLEMENTED"}}>
This may be due to network connectivity issues. Please check your network settings, and the status of the service you are trying to reach.
```

**Both commands failed on `getIamPolicy`**, the read, with `501 UNIMPLEMENTED`: the emulator's own word
for a method it does not have. The second command shows the order of operations, because it is a write
that began by reading. The sentence about network connectivity is the CLI guessing; the cause is the one
the emulator's banner gave in lesson 1, `IAM integration is disabled`.

The `etag` is what makes read-modify-write safe. Two people read the policy at the same `etag`, each adds
a member, each writes back. Without the etag, the second write would replace the first one's change
without anybody noticing. With it, **Google refuses a write whose etag is no longer current**, and the
second person's client reads again and retries. A script that hand-builds a policy and leaves the etag
out loses that protection, and can remove the grants somebody else added a second earlier.

## Conditions

A binding's condition is written in **CEL**, the Common Expression Language, and can test the request's
time, the resource's name and type, and the Resource Manager tags of lesson 3. Two uses come up in every
estate: a **temporary grant**, like the on-call one above, which ends on its own without anybody
remembering to remove it; and a **grant on part of a project**, such as Pub/Sub editor only on topics whose
name starts with `projects/planner-dev/topics/reports-`. A grant that expires is the cheapest way to give
somebody access for an incident and be sure it ends.

Nothing in this section came from Google: the policy above is a file in Google's format, and the lab's
only IAM answer is the emulator's refusal.
