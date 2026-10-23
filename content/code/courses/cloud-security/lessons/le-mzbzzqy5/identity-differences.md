---
title: Identity, where the three disagree
version: 1
---

**The `cloud` course's lesson 7 gave the vocabulary: an AWS role is something you become, a Google
Cloud or Azure role is something you are given. This section is about four places where the three
behave differently in ways that decide whether a grant is safe**, each one a mistake people carry
from one provider to the next.

## 1. Who "everybody" is

Each provider has a way to name every caller at once, and each has a second one that sounds narrower
than it is:

| | everybody, signed in or not | a trap that sounds narrower |
|---|---|---|
| AWS | `"Principal": "*"` in a resource policy | the S3 ACL group *Authenticated Users*, meaning any AWS account in the world, not yours |
| Google Cloud | `allUsers` | `allAuthenticatedUsers`, meaning anybody signed in to any Google account, not your organisation |
| Azure | anonymous access to a blob container | a shared access signature (SAS) link, which works for whoever holds it (lesson 10) |

**"Authenticated" never means "ours".** Both AWS and Google document it plainly, and it has still
exposed storage more than once: somebody wanted "only logged-in users" and granted
every account on the planet. Lesson 9 is the storage side of this.

## 2. Whether a deny exists, and who writes it

**AWS evaluates explicit denies in any policy that applies**, and an explicit deny beats every allow;
lesson 6 uses that to put a guardrail on a person. **Azure RBAC is additive**: a principal's
permissions are the union of its role assignments. Azure has *deny assignments*, but customers do not
write them freely; Azure creates them for features such as managed applications. The everyday way to
forbid something on Azure is an Azure Policy with a `Deny` effect on the configuration, not a deny on
the person. **Google Cloud has IAM deny policies**, attached to the organisation, a folder or a
project, and evaluated before the allow policies; most organisations still work almost entirely in
allows.

So "add a deny for this user" is one line on AWS, a different mechanism on Google Cloud, and usually a
redesign on Azure.

## 3. Two planes of administration on Azure

Azure has **two separate role systems**. Microsoft Entra roles, such as *Global Administrator*,
govern the directory: users, groups, applications. Azure RBAC roles, such as *Owner*, govern
subscriptions and the resources in them. They are assigned in different places and listed in
different places, and an audit of one does not see the other.

They meet at one documented switch: a Global Administrator can turn on **elevate access**, which gives
them *User Access Administrator* at the root of every subscription in the tenant, and from there
they can grant themselves anything. Microsoft documents it as the way to regain control of a tenant's
subscriptions, and recommends removing the elevated access as soon as it is no longer needed. **The
directory's top role is therefore an Azure owner in waiting**, and a review that counted only RBAC
owners has missed it.

## 4. Keys for programs

All three give a program an identity without a stored secret: an AWS role assumed by the machine or
function, a Google Cloud service account attached to the workload, an Azure managed identity. All
three also still allow the old way:

| | the identity without a secret | the long-lived secret it can still have |
|---|---|---|
| AWS | a role | an IAM user's access key |
| Google Cloud | a service account attached to the workload | a **service account key**, a JSON file holding a private key |
| Azure | a managed identity | a client secret or certificate on an app registration |

Google's documentation treats service account keys as a security risk and offers an Organization
Policy constraint, `iam.disableServiceAccountKeyCreation`, that refuses their creation across a
folder or the whole organisation. That is the shape of the defence everywhere: **make the
secretless path the default, and make the long-lived secret something a guardrail refuses**. Lesson 4
showed the AWS key across a seam; lesson 7 deals with the keys that remain.
