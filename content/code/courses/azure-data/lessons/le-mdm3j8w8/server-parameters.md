---
title: Server parameters, and the ones that need a restart
version: 1
---

**On a server you run, PostgreSQL's settings live in `postgresql.conf`; on a flexible server they are
server parameters, set through Azure.** The names and values are PostgreSQL's own. What Azure adds is
the door: you change a parameter with the command line, the portal or a declaration, and Azure decides
which parameters you may touch and within what range.

The engine already says which settings take effect at once and which need a restart. In the container
from the previous section:

```
ana@laptop:~/azure$ pg -c "SELECT name, setting, unit, context FROM pg_settings WHERE name IN ('max_connections', 'shared_buffers', 'shared_preload_libraries', 'work_mem', 'log_min_duration_statement') ORDER BY context, name"
            name            | setting | unit |  context   
----------------------------+---------+------+------------
 max_connections            | 100     |      | postmaster
 shared_buffers             | 16384   | 8kB  | postmaster
 shared_preload_libraries   |         |      | postmaster
 log_min_duration_statement | -1      | ms   | superuser
 work_mem                   | 4096    | kB   | user
(5 rows)

```

**`context` is the column that matters.** `user` means any session may change it for itself, as
`work_mem` is. `superuser` means an administrator may change it while the server runs.
**`postmaster` means it is read once, when the server starts**: `max_connections`, `shared_buffers`
and `shared_preload_libraries` cannot change without a restart. Azure's documentation calls these
static parameters, and changing one on a flexible server restarts it, which is a short outage you
schedule rather than a setting you flip.

## One that needs a restart, done the hard way

**`pg_stat_statements` is the extension that answers "which queries cost the most"**, the first
question after an alarm about a slow database, and it needs to be loaded when the server starts:

```
ana@laptop:~/azure$ pg -c "CREATE EXTENSION pg_stat_statements"
CREATE EXTENSION
ana@laptop:~/azure$ pg -c "SELECT count(*) FROM pg_stat_statements"
ERROR:  pg_stat_statements must be loaded via "shared_preload_libraries"
```

**The extension installed, and the view refused to answer** until the library is in
`shared_preload_libraries`. On your own server you say so with `ALTER SYSTEM`, which writes the
setting to a file PostgreSQL reads at start, and then you restart:

```
ana@laptop:~/azure$ pg -c "ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements'"
ALTER SYSTEM
ana@laptop:~/azure$ pg -c "SELECT pg_reload_conf()"
 pg_reload_conf 
----------------
 t
(1 row)

ana@laptop:~/azure$ pg -c "SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'shared_preload_libraries'"
           name           | setting | pending_restart 
--------------------------+---------+-----------------
 shared_preload_libraries |         | t
(1 row)

```

**`pending_restart` is the engine saying so**: the value is written, `pg_reload_conf()` has re-read it,
and it will not apply until the server starts again.

```
ana@laptop:~/azure$ docker compose restart postgres 2>&1 | tail -1
 Container azure-postgres-1 Started 
ana@laptop:~/azure$ pg -c "SHOW shared_preload_libraries"
 shared_preload_libraries 
--------------------------
 pg_stat_statements
(1 row)

ana@laptop:~/azure$ for i in 1 2 3; do pg -c "SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = 17" > /dev/null; done
ana@laptop:~/azure$ pg -c "SELECT calls, rows, query FROM pg_stat_statements ORDER BY calls DESC LIMIT 3"
 calls | rows |                                query                                 
-------+------+----------------------------------------------------------------------
     3 |    3 | SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = $1
     1 |    0 | SHOW shared_preload_libraries
(2 rows)

```

**The restart took the library, and the view now answers.** The support query ran three times with
the same customer and is one line, three calls, because the view counts statements by their
normalised text, with `$1` where the 17 was. Every statement from now on is counted that way, with its
calls, rows and time, and `ORDER BY total_exec_time DESC` is the list a person reads first when the
database is slow.

## The same parameter, on Azure

**On a flexible server, `ALTER SYSTEM` is not available to you**: the administrator is not a superuser,
as the previous section said. The documented door is the command line, which talks to Azure Resource
Manager rather than to the engine, and so, like every control-plane command in this course, stops at
the login:

```
ana@laptop:~/azure$ az postgres flexible-server parameter set --resource-group rg-quitanda-data-prd --server-name psql-quitanda-orders-prd --name shared_preload_libraries --value pg_stat_statements 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

**That command would set the parameter, and because it is static, Azure would then need the server
restarted** before it took effect. And there is a second gate for any extension: a server parameter
called `azure.extensions` lists the extensions the administrator may create, and an extension not on
that list is refused by `CREATE EXTENSION`, whatever the role. Neither was run here; both are in the
documentation.

As a declaration, the parameter is a resource of its own. Save this beside the previous section's
`main.tf`, in `~/azure/tf/flex`:

`params.tf`:

```hcl
resource "azurerm_postgresql_flexible_server_configuration" "preload" {
  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.orders.id
  value     = "pg_stat_statements"
}
```

```
ana@laptop:~/azure/tf/flex$ terraform validate -no-color
Success! The configuration is valid.

```

**Valid, and silent about the restart.** The declaration says what the parameter should be. Whether applying it restarts a production
server in the middle of the day is a fact `validate` does not know, and it is the reason a change to a static parameter goes through the same review as any outage.
