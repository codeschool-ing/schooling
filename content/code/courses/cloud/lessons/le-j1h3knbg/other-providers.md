---
title: The same ideas at Google Cloud and Azure
version: 1
---

Every idea in this lesson exists at the other large providers: a principal, an action on a resource,
default deny, temporary credentials for machines. What changes is the vocabulary, and one word
changes meaning in a way that catches people who move between them.

**At AWS a role is an identity. At Google Cloud and at Azure a role is a bundle of permissions.** An
AWS role is something you *become*; a Google Cloud or Azure role is something you are *given*, on a
particular resource. Reading "give the service the Storage Object Viewer role" with the AWS meaning in mind
sends you looking for a trust policy that does not exist.

| the idea | AWS | Google Cloud | Azure |
|---|---|---|---|
| a person | an IAM user, or a user in IAM Identity Center | a Google account, managed in Cloud Identity or Workspace | a user in Microsoft Entra ID |
| a set of people | an IAM group | a Google group | an Entra ID group |
| one permission | an action, `s3:GetObject` | a permission, `storage.objects.get` | an action, `Microsoft.Storage/storageAccounts/read` |
| a bundle of permissions | a policy | a role, `roles/storage.objectViewer` | a role definition, *Storage Blob Data Reader* |
| giving it to somebody | attaching the policy to a user, group or role | a binding in the resource's allow policy | a role assignment at a scope |
| an identity for a program | a role, assumed by the VM or function | a service account | a managed identity |

## Google Cloud

Google Cloud keeps its resources in a hierarchy: an **organisation** at the top, folders inside it,
projects inside those, and resources such as buckets and virtual machines inside projects. Each
level has an allow policy, a list of bindings, each binding saying "these principals have this role
here". A binding is inherited downwards: a role granted on a folder applies to every project and
resource in it. That makes the question "who can read this bucket" an answer collected from the
bucket, its project, its folders and the organisation, and a grant made high up for convenience is
a grant on everything below it.

Roles come in three kinds. The **basic roles**, Owner, Editor and Viewer, are broad and predate the
rest; Editor on a project can change nearly everything in it. Predefined roles are narrow ones per
service, like `roles/storage.objectViewer`. Custom roles are your own bundle.

A **service account** is the identity for a program. A virtual machine runs as one, and gets its
temporary credentials from a metadata server inside the machine, the same idea as AWS's.

## Azure

Azure keeps identities in **Microsoft Entra ID**, the directory that also runs sign-in to Microsoft's
other services: users, groups, and service principals for applications. Permissions on resources are
Azure RBAC, role-based access control, and a grant is a **role assignment** of three parts: a
principal, a role definition, and a scope. The scope is a level of Azure's own hierarchy —
management group, subscription, resource group, or a single resource — and, as at Google Cloud, an
assignment is inherited by everything below its scope. Owner, Contributor and Reader are the broad
built-in roles; narrower ones exist per service.

A **managed identity** is the identity for a program: Azure creates it for a virtual machine or a
function, gives it credentials that the platform rotates, and deletes it with the resource if it was
created for that resource alone.

## What stays the same

Default deny holds at all three: with no grant, the answer is no. Both Google Cloud and Azure have
deny rules as well, deny policies and deny assignments, but everyday work there is done almost
entirely with grants. The question to ask of any grant is the one this lesson asks of an AWS policy:
which principal, which actions, on what, and how far down it reaches. The vendor courses,
`aws-foundations`, `gcp-foundations` and `azure-foundations`, take each of these into its own console
and command line.
