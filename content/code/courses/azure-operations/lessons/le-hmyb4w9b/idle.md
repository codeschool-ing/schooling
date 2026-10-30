---
title: Idle resources, found by a query
version: 1
---

**An idle resource costs money and serves nothing**, and the three commonest are always the same: a
managed disk left behind when its VM was deleted, a public IP address associated with nothing, and an App
Service plan with no apps on it. Each is billed by the hour, and none appears on anybody's dashboard.

The place to find them in Azure is **Azure Resource Graph**, a service that answers KQL queries about every
resource in the subscriptions you can read, in a table called `Resources`. It is control-plane data, so
the lab cannot query it; what the lab can do is run the same KQL against a table of the same shape. Twelve
of the shop's resources, written by the course, in `inventory.kql`:

```kql
// inventory.kql: the subscription's resources, in the shape of Azure Resource Graph's Resources table
.set-or-replace Resources <|
datatable(name: string, type: string, resourceGroup: string, location: string, sku: string, tags: dynamic, properties: dynamic) [
    "app-shop-api", "microsoft.web/sites", "rg-shop", "brazilsouth", "", dynamic({"team": "shop", "env": "prod"}), dynamic({"serverFarm": "asp-shop-prod"}),
    "asp-shop-prod", "microsoft.web/serverfarms", "rg-shop", "brazilsouth", "P1v3", dynamic({"team": "shop", "env": "prod"}), dynamic({"numberOfSites": 1}),
    "asp-shop-old", "microsoft.web/serverfarms", "rg-shop", "brazilsouth", "P1v3", dynamic({"team": "shop"}), dynamic({"numberOfSites": 0}),
    "vm-shop-batch", "microsoft.compute/virtualmachines", "rg-shop-workers", "brazilsouth", "Standard_D8s_v5", dynamic({"team": "exports", "env": "prod"}), dynamic({"powerState": "running"}),
    "vm-reports", "microsoft.compute/virtualmachines", "rg-reports", "brazilsouth", "Standard_D4s_v5", dynamic({}), dynamic({"powerState": "running"}),
    "vm-reports-os", "microsoft.compute/disks", "rg-reports", "brazilsouth", "Premium_LRS", dynamic({}), dynamic({"diskState": "Attached", "diskSizeGB": 128}),
    "disk-old-1", "microsoft.compute/disks", "rg-test-ana", "brazilsouth", "Premium_LRS", dynamic({}), dynamic({"diskState": "Unattached", "diskSizeGB": 256}),
    "disk-old-2", "microsoft.compute/disks", "rg-test-ana", "brazilsouth", "Standard_LRS", dynamic({}), dynamic({"diskState": "Unattached", "diskSizeGB": 512}),
    "pip-test", "microsoft.network/publicipaddresses", "rg-test-ana", "brazilsouth", "Standard", dynamic({}), dynamic({"ipConfiguration": ""}),
    "pip-nat-shop", "microsoft.network/publicipaddresses", "rg-shop", "brazilsouth", "Standard", dynamic({"team": "shop"}), dynamic({"ipConfiguration": "nat-shop"}),
    "sql-shop", "microsoft.sql/servers", "rg-shop", "brazilsouth", "", dynamic({"team": "shop", "env": "prod"}), dynamic({}),
    "stshopexports", "microsoft.storage/storageaccounts", "rg-shop", "brazilsouth", "Standard_ZRS", dynamic({"team": "shop", "env": "prod"}), dynamic({})
]
```

The query, which would run unchanged against Resource Graph:

```kql
// idle.kql: resources that cost money and serve nothing
Resources
| where (type == "microsoft.compute/disks" and properties.diskState == "Unattached")
     or (type == "microsoft.network/publicipaddresses" and isempty(tostring(properties.ipConfiguration)))
     or (type == "microsoft.web/serverfarms" and toint(properties.numberOfSites) == 0)
| project name, type, resourceGroup, sku, owner = tostring(tags.team)
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < idle.kql
name          type                                 resourceGroup  sku           owner
asp-shop-old  microsoft.web/serverfarms            rg-shop        P1v3          shop
disk-old-1    microsoft.compute/disks              rg-test-ana    Premium_LRS
disk-old-2    microsoft.compute/disks              rg-test-ana    Standard_LRS
pip-test      microsoft.network/publicipaddresses  rg-test-ana    Standard
```

Four idle resources: two unattached disks and an unused public IP, all in `rg-test-ana`, and an App Service
plan with no sites, `asp-shop-old`. The `owner` column is the `team` tag, and it is empty for three of
them, which is lesson 24's subject: an idle resource with no owner is one nobody will ever be asked about.

Against a real subscription, the same question goes through the command line, **not run** here because
Resource Graph needs a signed-in identity:

```sh
az graph query -q "Resources | where type == 'microsoft.compute/disks' and properties.diskState == 'Unattached' | project name, resourceGroup, sku = sku.name"
```

Resource Graph uses lowercase type names and offers `type =~`, the case-insensitive comparison, for when
you are not sure; the generated table stores them lowercase, as Resource Graph does.
