---
title: When no copy is left, import what exists
version: 1
---

**With no copy of the state anywhere, the state is rebuilt from Azure, one resource at a time.** Nothing
was lost in Azure, so every resource can be found again, by its id, and attached to its address in the
configuration. Terraform does this with **`import` blocks**, which say: the resource at this address is
the one with this id.

```hcl
# imports.tf
import {
  to = azurerm_resource_group.shop
  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shop"
}

import {
  to = azurerm_storage_account.shop
  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shop/providers/Microsoft.Storage/storageAccounts/stshopprod7x2k9q"
}
```

The ids are Resource Manager ids, the long path every Azure resource has, and finding them is
`az resource list -g rg-shop --query "[].id"` against the real subscription. With the blocks in place,
`plan` shows each resource as **to be imported**, and also every property where the configuration and
the resource disagree. The first plan after a loss is long for that reason, and each disagreement is a
decision: change the configuration to match what exists, or let the next `apply` change the resource.
For a resource with no configuration written at all, Terraform can draft it:

```sh
terraform plan -generate-config-out=generated.tf
```

The generated file is a draft in the same sense as lesson 4's decompiled Bicep: it describes every
property the resource has, defaults included, and needs reading before it is kept. None of this was run
here, because every step needs the real subscription. The files themselves are ordinary configuration:
the subscription id in them is the placeholder Azure's own documentation uses.

Two warnings from the people who have done this. **Import in small batches**, a resource group's worth
at a time, applying in between, so that a mistake is found among five resources rather than eighty. And
**watch for generated names**: a resource whose name came from `random_string` or `uniqueString` is the
one you are most likely to have duplicated before you noticed the state was gone, and the duplicate has
to be found and deleted by hand.
