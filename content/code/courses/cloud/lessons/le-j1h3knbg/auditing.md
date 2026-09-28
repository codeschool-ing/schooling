---
title: Who did what, and who still can
version: 1
---

Policies decide what may happen. They say nothing about what did happen, and two questions come up
sooner or later in every account: who deleted this, and who could still do it again? The first is
answered by a log, the second by a review, and both need to exist before the day they are asked.

## The log of every call

Each provider records the calls made to its API. At AWS it is **CloudTrail**; at Google Cloud,
Cloud Audit Logs; at Azure, the Activity Log, with Entra ID keeping its own record of sign-ins. The
entries have the shape this lesson started with, because they record the request:

- who: the principal, and for a role, the session that assumed it, so a call made through a shared
  role can still be traced to the person or machine that assumed it;
- what: the action, such as `DeleteObject` or `TerminateInstances`;
- on what: the resource;
- when, and from which address;
- the result, **including refusals**. A run of `AccessDenied` from one identity is how a stolen key
  trying its luck looks from the inside.

What gets recorded without anybody asking is narrower than people assume. All three keep the calls
that *change* things, such as creating, deleting or granting, and keep them for a limited time: AWS
and Azure both keep ninety days of those on their own. Reads of the data itself, such as each
`GetObject` on a bucket, are a separate kind of event that AWS does not record unless it is
configured to, and Google Cloud's data-access logs are off by default for most services. Anything
longer than the default retention, or any record of who read what, is a decision somebody makes and
pays for.

**The log has to live somewhere the people it audits cannot delete.** An administrator who can remove
the log can remove the record of what they did with it. The usual arrangement is to send the log to
storage in a separate account that only a small security group can reach, with a retention setting
that forbids deleting entries before a date, which S3 offers as Object Lock. Then the most powerful
identity in the audited account can still stop new entries being written, and stopping them is
itself one of the entries already kept.

## The review

The log answers questions about the past. The review is how the present stays honest. On a
calendar, every quarter is a common rhythm, somebody goes through the identities and asks, for each:

1. Does this person or program still need to exist? Leavers and retired services first.
2. Which groups and roles does it have, and does the job still need each one?
3. When did it last use each permission? A grant unused since the last review is a candidate for
   removal, and the provider's last-used data is the evidence.
4. Are there long-lived keys, and does each one have a reason and a recent rotation?

**A review is a person deciding, with the owner of the team in the room**, because only they know
whether the grant from the incident eighteen months ago is still needed. Removing access someone uses
causes a refused request and a message the same afternoon; keeping access nobody uses causes nothing
until the day it is abused. That asymmetry is why the default answer, when nobody can say why a
permission exists, is to remove it.

::: track devsecops security
In your track this lesson is the floor. `cloud-security` comes next and builds on it: federation
set up in practice, keys and their rotation, and the escalation paths that nobody revoked. One of
those is `iam:PassRole`, which lets an identity hand a role to a machine it launches and then act
with everything that role can do. Keep the three evaluation rules and the credential chain in hand; that
course assumes both.
:::

::: track *
For this course, this is enough to design who may do what in an account: people federated with a
second factor, machines on roles, policies written from nothing upwards, and a log someone reviews.
`cloud-security` goes deeper if your work needs it, from escalation paths nobody revoked to how keys
are rotated.
:::
