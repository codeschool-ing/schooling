---
title: Elastic pools, and many databases on one bill
version: 1
---

**An elastic pool is an amount of compute bought once and shared by many databases.** Each database in
it is still its own database, with its own data and its own connections, but none of them is sized on
its own: the pool has a number of eDTUs, or of vCores, and each database takes what it needs from it
at that moment, between a minimum and a maximum you set for all of them. The pool is billed by the
hour for its size, whatever the databases inside it do.

**This section is taught from Microsoft's documentation, and nothing in it was run against Azure.** The
pool at the end is a declaration checked by Terraform, offline, with what that check cannot see
shown too.

## When sharing wins

**A pool wins when many databases are idle most of the time and busy at different times.** Quitanda's
twelve developers each have a copy of the orders database for the test suite. Each copy sits idle for
most of the day and runs at full speed for a few minutes whenever its owner runs the tests, and the
twelve rarely do that in the same minute. Sized one by one, each needs an S1, 20 DTUs, for those few
minutes. At an illustrative 30.00 USD a month for an S1, twelve cost 360.00.

A Standard pool of 100 eDTUs, with a per-database maximum of 50, holds all twelve: any one of them
can run its tests at more than twice an S1's speed, and two can do it at once at full speed. At an
illustrative 150.00 a month for that pool, the twelve cost 150.00 between them.

**A pool loses when the peaks arrive together.** If the twelve test suites run from one pipeline at
nine every morning, twelve databases each want 50 eDTUs from a pool of 100, and every one of them
runs at a sixth of its speed. The pool's arithmetic is about the overlap of the peaks, not about the
size of the average, and it is measured by watching the databases rather than guessed.

Serverless, from the previous section, answers the same idleness the other way: it shrinks each
database's bill rather than sharing one. A pool suits many databases that are busy at unpredictable
moments and must answer at once; serverless suits few databases that are idle for hours and can wait
a little for the first connection.

## The pool, as a declaration

In the same directory as the previous section's `main.tf`, `~/azure/tf/sql`, save this beside it.
Terraform reads every `.tf` file of a directory as one configuration:

`pool.tf`:

```hcl
resource "azurerm_mssql_elasticpool" "dev" {
  name                = "pool-quitanda-dev"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location
  server_name         = azurerm_mssql_server.orders.name
  max_size_gb         = 100

  sku {
    name     = "StandardPool"
    tier     = "Standard"
    capacity = 100
  }

  per_database_settings {
    min_capacity = 0
    max_capacity = 50
  }
}

resource "azurerm_mssql_database" "dev" {
  for_each        = toset(["ana", "bruno", "carla"])
  name            = "orders-dev-${each.key}"
  server_id       = azurerm_mssql_server.orders.id
  elastic_pool_id = azurerm_mssql_elasticpool.dev.id
}
```

`capacity` is the pool's 100 eDTUs, and `per_database_settings` is the range every database in it
moves within. A database joins a pool by naming it, and then has no size of its own.

```
ana@laptop:~/azure/tf/sql$ terraform validate -no-color
Success! The configuration is valid.

```

**Valid, and so is something Azure would refuse.** A database cannot take more from a pool than the
pool has, and the documentation says a per-database maximum may not exceed the pool's size. The
provider does not check that:

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/max_capacity = 50/max_capacity = 500/' pool.tf && terraform validate -no-color; mv pool.tf.bak pool.tf
Success! The configuration is valid.

```

So a pool with 100 eDTUs and a per-database maximum of 500 passes `validate` and would fail when
Azure was asked to create it. That is the general shape of what an offline check can give: it catches
what is wrong with a value on its own, and nothing that is wrong only next to another value Azure
knows the rules for.
