---
title: Making the accident hard to have
version: 1
---

Restoring is a skill; not needing it is a design. The shop's state account has five protections, each
against a different way of losing the file, and each is a setting rather than a habit.

| protection | what it stops |
|---|---|
| **blob versioning** | an overwrite: the previous content stays as a version |
| **soft delete**, 30 days | a deletion: the blob and its snapshots can be undeleted |
| **a `CanNotDelete` lock** on the account | the account itself being deleted, by anybody, the portal included |
| **key access off**, data role for two identities | anybody who can list keys reading or writing state |
| **its own resource group**, `rg-tfstate` | a `destroy` of the application taking its own record with it |

The third is a **management lock**, a Resource Manager feature distinct from the lease of lesson 6. A lease guards one blob's content for the length of an `apply`; a lock guards a resource from deletion
until somebody with the right role removes the lock. Even an Owner has to remove it first, which is the
point: deleting the state account becomes two deliberate acts instead of one careless one.

The fourth is the one teams skip. **Two identities need write access to the state: the pipeline's, and
one break-glass identity for a person.** Everybody else needs none, and a developer who wants to see what
the state holds runs `terraform show` through the pipeline rather than reading the blob. Fewer writers is
fewer ways to write the wrong file over the right one.

And the habit that sits on top of all five: **a pipeline that runs `apply` takes a snapshot first.** It
costs one command and a few bytes, and it turns the first accident in this lesson into a two-minute
recovery even on an account whose versioning somebody turned off.
