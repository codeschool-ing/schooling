---
title: Where the operating system and the database meet
version: 1
---

The two lists of the first section meet in one place: **the moment a connection is accepted**.
`pg_hba.conf` decides how the server checks who is knocking, and for a connection over the local
socket, Ubuntu's file says `peer`. Peer authentication asks the kernel which operating-system user
opened the socket and lets that user in **as the role with the same name, and only that one**.
After that moment the operating-system user is forgotten; everything inside the session is the
role.

So peer is why `psql` from `ana`'s shell lands as the role `ana`, and why this is refused:

```
ana@db:~$ psql -U bruno shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "bruno"
```

The machine has no `bruno` to be peer with, and should not get one just so a test can log in. Peer
has an option for exactly this case: a **map**, kept in `pg_ident.conf`, that lists which
operating-system users may connect as which roles. With one, `ana` can log in as `bruno` the way
`bruno` himself would, and the test that `SET ROLE` could not perform becomes possible.

Lesson 5 reads `pg_hba.conf` line by line. Here you change one word of one line, and put it back
at the end of the section.

## Changing the files, with a way back

Copy both files first. **`-p` keeps the owner**, and that matters: a plain `sudo cp` makes the copy
belong to `root`, and if that copy is ever moved back, the server, which runs as `postgres`, can no
longer read its own configuration.

```
ana@db:~$ sudo cp -p /etc/postgresql/16/main/pg_hba.conf /etc/postgresql/16/main/pg_hba.conf.orig
ana@db:~$ sudo cp -p /etc/postgresql/16/main/pg_ident.conf /etc/postgresql/16/main/pg_ident.conf.orig
```

Open `pg_hba.conf` with `sudo nano` and find the line for local connections by everybody, the one
that reads `local all all peer`. Add `map=shop` at its end. Then open `pg_ident.conf` the same way
and add these lines at the bottom:

```conf
# pg_ident.conf: the operating-system user ana may connect as ana, bruno or reporting
shop            ana                     ana
shop            ana                     bruno
shop            ana                     reporting
```

The columns are the map's name, the operating-system user and the role. **The first line matters
as much as the others**: once a map is on the line, plain peer matching stops, and without `ana
ana` you would have locked yourself out of your own role. The line above the edited one is for the
operating-system user `postgres` and has no map, so `sudo -u postgres psql` keeps working whatever
you get wrong here, which is why Ubuntu ships it as a separate line.

Before reloading, ask the server what it will read. Both files have a view that parses the file
**as it is on disk now** and reports any line it cannot use in its `error` column:

```
ana@db:~$ sudo grep -n '^local' /etc/postgresql/16/main/pg_hba.conf
118:local   all             postgres                                peer
123:local   all             all                                     peer map=shop
130:local   replication     all                                     peer
shop=# SELECT map_name, sys_name, pg_username, error FROM pg_ident_file_mappings;
 map_name | sys_name | pg_username | error 
----------+----------+-------------+-------
 shop     | ana      | ana         | 
 shop     | ana      | bruno       | 
 shop     | ana      | reporting   | 
(3 rows)

shop=# SELECT line_number, user_name, auth_method, options, error FROM pg_hba_file_rules WHERE type = 'local';
 line_number | user_name  | auth_method |  options   | error 
-------------+------------+-------------+------------+-------
         118 | {postgres} | peer        |            | 
         123 | {all}      | peer        | {map=shop} | 
         130 | {all}      | peer        |            | 
(3 rows)

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

No errors, so the reload was safe. A reload with a broken `pg_hba.conf` keeps the old rules and
says so in the log, and new connections go on being judged by a file you think you replaced.

## Logging in as somebody else

The map allows `ana` to be `reporting`, and the server still refuses:

```
ana@db:~$ psql -U reporting shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "reporting" is not permitted to log in
ana@db:~$ psql -U bruno shop
shop=> SELECT current_user, session_user;
 current_user | session_user 
--------------+--------------
 bruno        | bruno
(1 row)

shop=> SELECT count(*) FROM customers;
 count 
-------
 50000
(1 row)

shop=> SET ROLE reporting;
ERROR:  permission denied to set role "reporting"
```

Two checks, in two places. **`pg_hba.conf` and the map decided that `ana` may try to be
`reporting`; the role's missing `LOGIN` decided she may not.** Authentication says who you are and
the role's attributes say whether that identity may open a session at all, which is why `NOLOGIN`
holds even against a map that names the role.

As `bruno`, both users are `bruno` now. He reads `customers` through the inherited privilege, and
`SET ROLE reporting` is refused, because this time the session user is `bruno` and his membership
has no `SET` option. That is the test the previous section could not make from `ana`'s session.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 276\" role=\"img\" aria-label=\"Two operating-system users on the left, postgres and ana, and four database roles on the right, postgres, ana, bruno and reporting. Between them is the door, pg_hba.conf with pg_ident.conf. Arrows show who may connect as whom: postgres as postgres and ana as ana, by matching names; with the map called shop, ana also as bruno and as reporting, and the arrow to reporting is dashed because the role has no LOGIN and the connection is refused.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"90\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">operating-system users</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the door</text><text x=\"630\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">database roles</text><rect x=\"285\" y=\"66\" width=\"150\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">pg_hba.conf</text><text x=\"360\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+ pg_ident.conf</text><rect x=\"40\" y=\"96\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">postgres</text><rect x=\"40\" y=\"186\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana</text><rect x=\"580\" y=\"76\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">postgres</text><rect x=\"580\" y=\"126\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana</text><rect x=\"580\" y=\"176\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bruno</text><rect x=\"580\" y=\"226\" width=\"100\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">reporting</text><line x1=\"140\" y1=\"110\" x2=\"578\" y2=\"90\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"140\" y1=\"200\" x2=\"578\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"140\" y1=\"200\" x2=\"578\" y2=\"190\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"140\" y1=\"200\" x2=\"578\" y2=\"240\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#arr)\"></line><text x=\"470\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same name: peer</text><text x=\"470\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refused: no LOGIN</text><text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">map=shop</text></svg>", "caption": "The two lists meet only at the door. Peer joins equal names; a map adds the pairs it lists; the role still decides whether it may log in."}
```

A map is a powerful line to leave in a file. **Every role on the right becomes reachable by the
operating-system user on the left, with no password.** On a machine more than one person logs in
to, a map is a grant of identity and deserves the review a `GRANT` gets.

## Putting it back

Move the copies back, check that the owner is still `postgres`, reload, and confirm that the door
is closed again:

```
ana@db:~$ sudo mv /etc/postgresql/16/main/pg_hba.conf.orig /etc/postgresql/16/main/pg_hba.conf
ana@db:~$ sudo mv /etc/postgresql/16/main/pg_ident.conf.orig /etc/postgresql/16/main/pg_ident.conf
ana@db:~$ sudo ls -l /etc/postgresql/16/main/pg_hba.conf /etc/postgresql/16/main/pg_ident.conf
-rw-r----- 1 postgres postgres 5924 Oct 10 03:18 /etc/postgresql/16/main/pg_hba.conf
-rw-r----- 1 postgres postgres 2640 Oct 10 03:18 /etc/postgresql/16/main/pg_ident.conf
ana@db:~$ psql -c "SELECT pg_reload_conf();"
 pg_reload_conf 
----------------
 t
(1 row)

ana@db:~$ psql -U bruno shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "bruno"
```

And undo the two experiments of the last section, so that `bruno`'s membership is back to the
defaults and `reporting` holds no privilege for lesson 12 to trip over:

```
shop=# REVOKE SELECT ON customers FROM reporting;
REVOKE

shop=# GRANT reporting TO bruno WITH SET TRUE;
GRANT ROLE
```
