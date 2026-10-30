---
title: The built-in PgBouncer, and MySQL beside it
version: 1
---

**PostgreSQL gives every connection a process of its own**, and that is expensive in memory and in the
time it takes to open one. An application that opens a connection per request, or a fleet of small
functions that each open their own, reaches `max_connections` long before it reaches the limit of the
processor. The fix is a connection pooler between the application and the engine, and the most used
one for PostgreSQL is PgBouncer.

**This section is taught from Microsoft's documentation, and nothing in it was run against Azure.** The
lab has no PgBouncer, and the course does not install one.

## PgBouncer, built in

**A flexible server can run PgBouncer on the same machine as the engine**, switched on by a server
parameter, `pgbouncer.enabled`, and reached on port 6432 instead of 5432. The application changes
nothing but the port. Many client connections share a few server connections, so a thousand
short-lived clients can be served by the hundred connections the container listed as
`max_connections`. It is not offered on Burstable, the second Burstable limit of this lesson.
It pools in transaction mode by default, which means a client that relies on a session setting, a
temporary table or a prepared statement across transactions has to be checked first.

## MySQL, the same shape

**Azure Database for MySQL flexible server is the same service for the other engine**: a version you
choose, compute tiers from burstable to large, provisioned storage that grows and does not shrink, high
availability zone-redundant or in the same zone, read replicas, point-in-time restore, stop and start.
What differs is the engine and its ecosystem, and the names Azure gives some tiers. There is no
built-in pooler for MySQL, whose connections are threads rather than processes and so cost less.

Quitanda keeps its product catalogue, written by a vendor's application that only speaks MySQL, on a
small one. Save this beside `main.tf` in `~/azure/tf/flex`:

`mysql.tf`:

```hcl
resource "azurerm_mysql_flexible_server" "catalogue" {
  name                   = "mysql-quitanda-catalogue-prd"
  resource_group_name    = azurerm_resource_group.data.name
  location               = azurerm_resource_group.data.location
  version                = "8.0.21"
  sku_name               = "B_Standard_B1ms"
  backup_retention_days  = 7
  administrator_login    = "quitanda"
  administrator_password = var.db_admin_password
}
```

```
ana@laptop:~/azure/tf/flex$ terraform validate -no-color
Success! The configuration is valid.

```

`B_Standard_B1ms` is the same Burstable size the PostgreSQL server could have used, and `8.0.21` is
how the API spells the 8.0 line of MySQL. A catalogue read by the shop all day and written by one
vendor job at night is the workload Burstable is for: mostly idle, sometimes busy, and fine with
neither high availability nor a pooler.

## Choosing between the four

| | Azure SQL Database | SQL Managed Instance | PostgreSQL flexible | MySQL flexible |
|---|---|---|---|---|
| engine | SQL Server, always current | SQL Server, always current | PostgreSQL, the version you pick | MySQL, the version you pick |
| what you rent | a database | an instance | a server | a server |
| licence | in the price, or the Hybrid Benefit | in the price, or the Hybrid Benefit | none | none |
| the floor | a few DTUs | several vCores | a Burstable machine | a Burstable machine |

**The engine decides first, and the price follows.** An application written for PostgreSQL goes to
PostgreSQL flexible server whatever the others cost; a new application with no engine yet is where the
choice is free, and where the absence of a licence in the price is the open-source engines' strongest
argument. Lesson 26 comes back to the choice with every store of the course on the table.
