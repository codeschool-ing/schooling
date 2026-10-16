---
title: What the server is actually using
version: 1
---

**The file says what somebody wrote; the server says what it is running with**, and the two
differ more often than anyone would like. A value in a file nobody reloaded, a setting made by
`ALTER SYSTEM` that overrides the file, a parameter given on the command line: the only reliable
answer comes from the server, and it lives in a view called `pg_settings`.

`SHOW` gives one value, formatted for a person. `pg_settings` gives one row per parameter, with
where the value came from and what it takes to change it:

```
ana@db:~$ psql
ana=# SELECT name, setting, unit, source, sourceline, context
ana-#   FROM pg_settings
ana-#  WHERE name IN ('shared_buffers', 'work_mem', 'max_connections',
ana(#                 'log_min_duration_statement', 'data_directory');
            name            |           setting           | unit |       source       | sourceline |  context   
----------------------------+-----------------------------+------+--------------------+------------+------------
 data_directory             | /var/lib/postgresql/16/main |      | override           |            | postmaster
 log_min_duration_statement | -1                          | ms   | default            |            | superuser
 max_connections            | 100                         |      | configuration file |         65 | postmaster
 shared_buffers             | 16384                       | 8kB  | configuration file |        130 | postmaster
 work_mem                   | 4096                        | kB   | default            |            | user
(5 rows)

ana=# SHOW shared_buffers;
 shared_buffers 
----------------
 128MB
(1 row)

ana=# SELECT count(*) FROM pg_settings;
 count 
-------
   364
(1 row)

ana=# SELECT context, count(*) FROM pg_settings GROUP BY context ORDER BY count(*) DESC;
      context      | count 
-------------------+-------
 user              |   142
 sighup            |    95
 postmaster        |    57
 superuser         |    46
 internal          |    18
 superuser-backend |     4
 backend           |     2
(7 rows)

ana=# \q
```

Three columns carry most of what an administrator needs.

## setting and unit

**`setting` is a number in the parameter's own unit**, and `unit` says what that unit is.
`shared_buffers` is `16384` in units of `8kB`, which is 128 MB, the same thing `SHOW` printed in
a friendlier form. `work_mem` is counted in kilobytes and `log_min_duration_statement` in
milliseconds, where `-1` means switched off. A query that compares or adds settings has to
multiply by the unit first; a person reading one value can use `SHOW`.

The 8 kB is not arbitrary. It is the size of one page, the block every table and index is made
of, and lesson 9 sets it beside the filesystem's own blocks.

## source

Where the value came from. `default` means nobody set it and the compiled-in value applies.
`configuration file` means a file did, and for those `sourcefile` and `sourceline` say which file
and which line: `shared_buffers` is line 130 of `postgresql.conf`, the line `sed` printed in the
previous section. `override` means the server set it itself from how it was started. The
`postgres -D …` command line in lesson 3's `ps` output is where `data_directory` really comes
from, and the copy in the file is a note for people.

Later sections meet three more: `database` and `user` for a value attached to a database or a
role, and `session` for one a connection set for itself.

## context

**`context` answers the question you always have next: what does it take to change this?** There
are 364 parameters and seven answers:

| context | how many here | a new value takes effect |
|---|---|---|
| `internal` | 18 | never; fixed when the server was compiled or the cluster created |
| `postmaster` | 57 | at the next **restart** |
| `sighup` | 95 | at the next **reload** of the configuration |
| `superuser-backend`, `backend` | 4 and 2 | for connections opened after a reload |
| `superuser` | 46 | at once, for a session a superuser changes with `SET` |
| `user` | 142 | at once, for a session anybody changes with `SET` |

`shared_buffers` and `max_connections` are `postmaster`: the server sizes its shared memory from
them when it starts and cannot resize it while running. `work_mem` is `user`: any connection may
set its own, and lesson 6 is about why that is both useful and dangerous. The comment
`(change requires restart)` in the file is the same information as `postmaster` here, and the
view is the one that cannot be out of date.

`pg_settings` has more columns than the query asked for. `boot_val` is the compiled default,
`reset_val` is what a session returns to after `RESET`, and `pending_restart` is the subject of
the next section.
