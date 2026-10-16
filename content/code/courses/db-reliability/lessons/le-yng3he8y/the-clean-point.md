---
title: The clean point is before the intruder, not before the damage
version: 1
---

A restore to just before the damage brings back what the database held at that moment, **including
everything the intruder had already changed**. To know what that is, you need a record of how the
database looked on a day you trust. Save this as `inventory.sql`:

```schooling-example
{"language": "sql", "file": "inventory.sql", "parts": [{"code": "-- inventory.sql: who may log in and with what power, and every function anyone added\nSELECT 'role', rolname, rolsuper, rolcanlogin, rolreplication\nFROM pg_roles WHERE rolname !~ '^pg_' ORDER BY rolname;", "note": "Every role that is not one of PostgreSQL's own, with the three powers that matter most."}, {"code": "SELECT 'function', n.nspname || '.' || p.proname\nFROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace\nWHERE n.nspname NOT IN ('pg_catalog', 'information_schema')\nORDER BY 2;", "note": "And every function outside the system's schemas, because a function can carry code that runs with its owner's rights."}]}
```

Take the inventory on a good day and keep it, as you would keep the globals file of lesson 2:

```
ana@vm:~$ psql -X -A -t shop -f inventory.sql > inventory-known.txt
ana@vm:~$ cat inventory-known.txt
role|ana|t|t|f
role|postgres|t|t|t
```

Two roles, you and `postgres`, both superusers, and no functions in the shop.

## The foothold

Now, standing in for the dwell time, the lab plays the intruder for one more command: a new
superuser that can log in, created days before anything visible happens. Run it, then let some
ordinary orders arrive:

```
shop=# CREATE ROLE maint_svc LOGIN SUPERUSER PASSWORD 'not-a-real-secret';
CREATE ROLE
```

That role is the whole of the intruder's preparation in this lab. In a real attack it would be one of
several things, and some of them would not be in the database at all.

## The restore, and what came back with it

The alert above gave the time of the damage. Restore to ten seconds before it, two intervals of the
watcher, onto the second server, paused:

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=time "--target=2026-10-15 21:54:12-03" --target-action=pause restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
shop=# SELECT name, city FROM customers ORDER BY id LIMIT 3;
    name    |     city     
------------+--------------
 customer 1 | Porto Alegre
 customer 2 | Belém
 customer 3 | Curitiba
(3 rows)

shop=# SELECT count(*), sum(total_cents) FROM orders;
 count |    sum    
-------+-----------
 50003 | 524990400
(1 row)
```

The names are names again, the totals are totals, and the three orders that arrived after the role
was created are there: **50003 orders**, as the live shop had before the damage. By every measure the
data shows, this is a good recovery. Now compare the restored copy with the inventory from the good
day:

```
ana@vm:~$ psql -X -A -t -p 5433 shop -f inventory.sql > inventory-restored.txt
ana@vm:~$ diff inventory-known.txt inventory-restored.txt
1a2
> role|maint_svc|t|t|f
```

**`maint_svc`, a superuser that can log in, came back with the data.** It was created before the
target, so the restore faithfully restored it, and an application pointed at this copy would hand the
intruder their way back in on the first day.

That is why the clean point is defined by the intruder rather than by the damage, and why the
recovery of a ransomware attack is never just a restore:

- **Restore to before the damage, then audit everything that grants access**: roles, passwords,
  functions, extensions, the configuration files, the `pg_hba.conf` that says who may connect.
  Compare against an inventory from before the intrusion, if one exists.
- **Or restore to before the intrusion**, if its date is known and the loss of everything since is
  acceptable. It rarely is known; dwell times are long.
- **In every case, change every credential**: every role's password, the backup repository's keys,
  the passphrase, the operating system accounts. The intruder may have read any of them.
