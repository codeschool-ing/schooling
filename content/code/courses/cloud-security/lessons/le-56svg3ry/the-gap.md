---
title: Least privilege is a gap you measure
version: 1
---

**Least privilege is not a property a policy has on the day it is written. It is the distance
between what an identity is allowed to do and what it actually does, and that distance grows on its
own unless somebody measures it.** The `cloud` course's lesson 7 wrote the rule: start from the
implicit deny and add only what the job needs. This lesson is about an account where that rule was
not followed, which is most of them.

The wrong picture is that permissions are set once, like a lock on a door. They behave more like a
key ring. A developer needs to read a log group during an incident, so a policy gains
`logs:*`. A contractor needs to give new analysts the reporting policy, so she gets the right to
attach policies to users. Each grant solved a real problem on a real day. **Nobody ever files a
ticket to remove a permission that is not causing an error**, so the ring only gets heavier.

## Granted against used

Two lists describe every identity:

| | where it comes from | how it changes |
|---|---|---|
| **granted** | the policies attached to the user, its groups or the role | grows whenever somebody solves a problem |
| **used** | what the identity's requests actually did, as recorded by the provider | follows the work, and shrinks when the work stops |

Least privilege is the work of making the first list approach the second. The direction matters:
you cannot reason your way to the used list, because nobody remembers which of forty actions a job
calls on the last day of the month. You read it from records.

AWS keeps three kinds of record that help, and each answers a different question:

- **when a key was last used**, per access key, with the service and region of that request. It
  answers "is this key dead?", and this lesson's last two sections use it;
- **when each service was last accessed**, per user, group or role: the IAM console's *Access
  Advisor* tab, or `generate-service-last-accessed-details` on the command line. It answers "which
  of these grants were never exercised?";
- **IAM Access Analyzer**, which reads CloudTrail and can report unused permissions or draft a
  policy from the actions a role really called over a period you choose.

**moto keeps the first and not the other two.** It records the last use of a key, as the
transcripts in this lesson show, while `generate-service-last-accessed-details` answers with an
internal server error and Access Analyzer's unused-access findings do not exist in it. What the
second and third do is taken from AWS's documentation and was not run.

## Not every extra permission is the same size

A user who can read one more bucket than it needs has a gap. A user who can **change permissions**
has no ceiling at all, because the first thing an unwanted holder of that key would do is grant
itself the rest. So a review does not start with the biggest policy; it starts with any identity
that can write to IAM.

The `cloud` course called `iam:*` administrator access under another name. It is not only `iam:*`.
A single narrow-looking action is enough when it is the right one, and two sections on, one does
exactly that in your lab. The section after it lists the actions to look for,
taken from a list AWS itself publishes.
