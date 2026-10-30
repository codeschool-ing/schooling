---
title: Deployment stacks: the resources a file owns
version: 1
---

**A plain ARM deployment forgets what it created.** It is an event: the next deployment of the same file
compares the template with what exists, but nothing remembers that a resource came from this file and
was later removed from it. That is the Ignore of the previous section, and it is how a resource group
fills with things nobody can account for.

**A deployment stack is a resource that remembers.** It deploys a template like any deployment, and then
keeps the list of resources it manages. Deploy it again with a resource removed from the file, and the
stack knows that resource is now **unmanaged**, and does what you told it to. The command was **not
run**, because a stack is itself a resource in a subscription:

```sh
az stack group create --name shop --resource-group rg-shop \
  --template-file main.bicep --parameters main.prod.bicepparam \
  --action-on-unmanage deleteResources \
  --deny-settings-mode denyDelete
```

**`--action-on-unmanage`** says what happens to a resource that leaves the file: `detachAll` leaves it in
Azure and stops managing it, which is the safe default and the same as a plain deployment's behaviour;
`deleteResources` deletes it; `deleteAll` deletes resource groups as well. The shop uses
`deleteResources` for the application's resource group, where everything is meant to come from the
file, and never for the one holding the Terraform state account.

**`--deny-settings-mode`** protects the managed resources from change outside the stack. `denyDelete`
refuses deleting them by any other route, the portal included; `denyWriteAndDelete` refuses changing them
too. A list of excluded principals, such as the pipeline's identity, keeps the stack's own deployments
working. This is the guard against the drift what-if reports: the change by hand is refused at the door
rather than found later.

Stacks overlap with Terraform's state, which lessons 6 and 7 are about, and the comparison is worth
making. Both keep a list of what a configuration owns. Terraform keeps it in a file that you store and
protect; a stack keeps it in Azure, as a resource. Neither is wrong, and a team picks one of them per
resource group rather than both.
