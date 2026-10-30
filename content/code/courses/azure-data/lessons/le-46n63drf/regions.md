---
title: Regions, and the declaration that sets the level
version: 1
---

**The level, the regions and whether more than one region takes writes are all set on the account**,
in one declaration, and that declaration is the only place to read them. This section checks one
with Terraform, which reads the file and Azure's provider and asks Azure nothing, as in lesson 1.
Nothing is created, because no emulator answers the control plane.

The file below is the account Quitanda weighed and did not build: the orders in `brazilsouth`, with
a second, read-only copy in `southcentralus`, the region lesson 1 named as Brazil South's pair. Make
a directory for it:

```sh
mkdir -p ~/azure/tf/cosmos && cd ~/azure/tf/cosmos
```

and save this in it:

`main.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_cosmosdb_account" "app" {
  name                = "cosmos-quitanda-app-prd"
  location            = azurerm_resource_group.data.location
  resource_group_name = azurerm_resource_group.data.name
  offer_type          = "Standard"

  consistency_policy {
    consistency_level = "Session"
  }

  multiple_write_locations_enabled = false

  geo_location {
    location          = "brazilsouth"
    failover_priority = 0
    zone_redundant    = true
  }

  geo_location {
    location          = "southcentralus"
    failover_priority = 1
  }
}
```

**`consistency_policy` is the level**, and `geo_location` is a region, one block each. The
region with `failover_priority` 0 is where writes go; the others are copies, in the order they would
take over. `multiple_write_locations_enabled` is the switch between one writing region and all of
them. Check it, then try two values Azure would refuse:

```
ana@laptop:~/azure/tf/cosmos$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/cosmos$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/cosmos$ sed -i 's/"Session"/"BoundedStaleness"\n    max_interval_in_seconds = 1/' main.tf && terraform validate -no-color

Error: expected consistency_policy.0.max_interval_in_seconds to be in the range (5 - 86400), got 1

  with azurerm_cosmosdb_account.app,
  on main.tf line 27, in resource "azurerm_cosmosdb_account" "app":
  27:     max_interval_in_seconds = 1

ana@laptop:~/azure/tf/cosmos$ sed -i 's/"Session"/"Strong"/; s/_enabled = false/_enabled = true/' main.tf && terraform validate -no-color
Success! The configuration is valid.
```

**The first refusal is the provider's**: bounded staleness cannot be bounded at one second, and the
bottom of the range it quotes, 5 seconds, is the documented minimum for an account in one region. It
names the line, as lesson 1's did. **The second success is the dangerous one.** Strong consistency
with writes in two regions is the combination the section before this one said Cosmos DB does not
offer, and `validate` passed it, because the rule is Azure's and lives in no schema. It would fail
when `terraform apply` asked Azure to create the account, which nothing in this course does, so the
answer Azure would give is not shown here. The same is true of bounded staleness at 5 seconds in this
two-region file: the provider accepts it, and the documented minimum for several regions is 300.

**So the declaration is where a reviewer reads the level, and the documentation is where the
reviewer checks it.** What to look for, in order:

- `consistency_level`, and whether anything in the application asks for more than it;
- the number of `geo_location` blocks, because each is a copy of every item and a share of the bill;
- `multiple_write_locations_enabled`, and if it is true, that the level is not strong and somebody
  has chosen the conflict policy;
- for bounded staleness, `max_interval_in_seconds` and `max_staleness_prefix`, against the minimums
  for the number of regions.

Quitanda's own account is this file without the second `geo_location` block: one region, zone
redundant, at session.
