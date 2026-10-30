---
title: Blueprints, and what replaced them
version: 1
---

**Azure Blueprints was Microsoft's first answer to "a subscription that starts out right", and it is
being retired.** A blueprint packaged a set of artifacts, policy assignments, role assignments,
resource groups and templates, into one definition with versions, and an *assignment* of it stamped
the whole set onto a subscription and could lock what it created. It never left preview.

Microsoft's retirement page, dated June 2026, gives the timeline. The original date was July 2026;
it was extended and made gradual:

| date | what stops |
|---|---|
| 31 July 2026 | creating new blueprint definitions and versions |
| 31 October 2026 | changing existing definitions, and creating new assignments |
| 31 December 2026 | changing existing assignments |
| 31 January 2027 | the service itself: the API, the commands and the portal pages go, definitions not exported are deleted, and blueprint locks stop working |

**This course was written on 30 October 2026**, the day before new assignments stop. The resources a
blueprint created stay where they are when it goes, unlocked. Anything in a course, an old article
or an inherited script that says to build a landing zone with Blueprints is describing a service that,
by the time you read this, accepts nothing new.

## Two features where there was one

Blueprints did two jobs, and Microsoft's replacement splits them:

- **storing and versioning the definition** goes to **template specs**, or simply to a Git
  repository. A template spec is a Bicep or ARM template stored in Azure as a resource of its own,
  with versions, so that a team can deploy *version 1.2 of the platform's network* by its id without
  having the file, and access to it is controlled by roles like any other resource;
- **assigning, managing the life cycle and locking** goes to **deployment stacks**.

## Deployment stacks

**A deployment stack is a deployment that remembers what it created.** An ordinary deployment sends
a template and forgets it: remove a resource from the file and deploy again, and the resource stays
in Azure, now described by nothing. A stack keeps the list of resources it manages, and two settings
decide what that list is for:

| setting | values | decides |
|---|---|---|
| `--action-on-unmanage` | `detachAll`, `deleteResources`, `deleteAll` | what happens to a resource that leaves the template, or to all of them when the stack is deleted: left in place, deleted, or deleted together with the resource groups the stack manages |
| `--deny-settings-mode` | `none`, `denyDelete`, `denyWriteAndDelete` | whether the managed resources are protected by a **deny assignment**, which refuses deleting them, or changing them, to everybody but up to five principals you name |

The second is Blueprints' lock, done properly. A deny assignment overrides role assignments, which
lesson 9 explains: an Owner who is not on the stack's short list of excluded principals still cannot delete what
`denyDelete` protects.

Stacks exist at three scopes, **a resource group, a subscription and a management group**, and not
at the tenant. So the tree of the previous section, made of tenant-level resources, is deployed the
ordinary way, and a stack at the management group manages what goes on it, such as lesson 4's policy
assignments. The command line knows every option without an account, as `az stack mg create --help`
shows; doing it does not:

```
ana@laptop:~/azure/alz$ az stack mg create --name shop-guardrails --management-group-id shop --location brazilsouth --template-file ../policy/policy.bicep --action-on-unmanage detachAll --deny-settings-mode denyDelete
ERROR: Please run 'az login' to setup account.
```

And a template spec of the tree, so that the platform team publishes it once, by version:

```
ana@laptop:~/azure/alz$ az ts create --name ts-shop-alz --version 1.0 --resource-group rg-shop-platform --location brazilsouth --template-file alz.bicep
ERROR: Please run 'az login' to setup account.
```

**Neither was run**, for the usual reason. `detachAll` is the cautious choice for a first stack: a
mistake in the template leaves resources unmanaged rather than deleted, and the stack can be made
stricter once it has been trusted for a while.
