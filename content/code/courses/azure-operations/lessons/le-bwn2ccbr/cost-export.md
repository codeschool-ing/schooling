---
title: The cost export, as a table
version: 1
---

**Cost Management can export the bill, every day, as files in a storage account**, one row per resource
per meter per day, with the resource's tags in a column. That export is what turns the bill into data: a
team can load it into a workspace or a warehouse and query it like any other table. Creating the export
needs a billing scope and a storage account, so **it was not done here**; what the course does instead is
generate sixty days in a simplified shape of it, at round illustrative daily costs, in `cost.kql`:

```kql
// cost.kql: sixty days of the subscription's daily cost per resource, in the shape of a cost export
.set-or-replace CostDaily <|
let resources = datatable(ResourceName: string, ResourceGroup: string, MeterCategory: string, Daily: real, Tags: dynamic) [
    "asp-shop-prod", "rg-shop", "Azure App Service", 12.0, dynamic({"team": "shop", "env": "prod"}),
    "sql-shop", "rg-shop", "SQL Database", 15.0, dynamic({"team": "shop", "env": "prod"}),
    "log-shop", "rg-shop", "Log Analytics", 4.0, dynamic({"team": "shop", "env": "prod"}),
    "fd-shop", "rg-shop", "Azure Front Door", 11.0, dynamic({"team": "shop", "env": "prod"}),
    "kv-shop-prod", "rg-shop", "Key Vault", 0.3, dynamic({"team": "shop", "env": "prod"}),
    "stshopexports", "rg-shop", "Storage", 1.1, dynamic({"team": "shop", "env": "prod"}),
    "asp-shop-old", "rg-shop", "Azure App Service", 6.0, dynamic({"team": "shop"}),
    "vm-shop-batch", "rg-shop-workers", "Virtual Machines", 9.6, dynamic({"team": "exports", "env": "prod"}),
    "vmss-shop-workers", "rg-shop-workers", "Virtual Machines", 16.5, dynamic({"team": "exports", "env": "prod"}),
    "vm-reports", "rg-reports", "Virtual Machines", 4.8, dynamic({}),
    "disk-old-1", "rg-test-ana", "Storage", 1.3, dynamic({}),
    "disk-old-2", "rg-test-ana", "Storage", 0.7, dynamic({}),
    "pip-test", "rg-test-ana", "Virtual Network", 0.12, dynamic({}),
    "sttfstate", "rg-tfstate", "Storage", 0.05, dynamic({"team": "platform"})
];
range Date from datetime(2026-08-20) to datetime(2026-10-18) step 1d
| extend k = 1
| join kind=inner (resources | extend k = 1) on k
| extend spike = iff(ResourceName == "log-shop" and Date >= datetime(2026-10-09), 3.2, 1.0)
| extend Cost = round(Daily * spike * (0.97 + abs(hash(strcat(ResourceName, Date), 7)) / 100.0), 2)
| project Date, ResourceName, ResourceGroup, MeterCategory, Cost, Tags
```

Fourteen resources: the shop's, the export workers', the reporting VM and the leftovers of `rg-test-ana`
that lesson 23 found. From 9 October the Log Analytics workspace costs a little over three times as much,
for a reason lesson 25 investigates. A real export has many more columns, among them the meter, the unit
price, the quantity and the billing currency; the course keeps the ones it uses.

Load it, and group the last thirty days by the `team` tag:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'CostDaily | where Date >= datetime(2026-09-19) | summarize cost = round(sum(Cost), 2) by team = tostring(Tags.team) | order by cost desc'
team      cost
shop      1565.4
exports   782.08
          207.92
platform  1.5
```

`tostring(Tags.team)` reads the tag out of the dynamic column; a resource with no `team` tag gives an empty
string, which is the row with no name. **That row is about eight per cent of the month**, 208 USD, far more
than the platform team's and about a quarter of what the export team spends. The next section asks what is in it.
