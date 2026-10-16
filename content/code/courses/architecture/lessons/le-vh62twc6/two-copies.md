---
title: Two copies of the stock
version: 1
---

The lab is two PostgreSQL servers: a **primary** that takes every write, and a **standby** that keeps a
copy by streaming the primary's write-ahead log (WAL), the record of every change, and replaying it. The
standby can answer reads; it refuses writes. This is the most common way to keep a second copy of a
relational database, and lesson 10 builds on it.

The lesson works in `~/lab/cap`:

```sh
mkdir -p ~/lab/cap && cd ~/lab/cap
```

`replication.sh`, which the primary runs once when it creates its data directory:

```schooling-example
{"language": "sh", "file": "replication.sh", "parts": [{"code": "#!/bin/bash\nset -e\npsql -v ON_ERROR_STOP=1 -U \"$POSTGRES_USER\" -c \"CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator'\"\necho \"host replication replicator all scram-sha-256\" >> \"$PGDATA/pg_hba.conf\"", "note": "Runs once, when the primary's data directory is first created: a role allowed to stream the write-ahead log, and a line in `pg_hba.conf` that lets it connect for replication from the lab's network."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  primary:\n    image: postgres:17\n    environment:\n      POSTGRES_PASSWORD: quitanda\n    volumes:\n      - ./replication.sh:/docker-entrypoint-initdb.d/replication.sh:ro\n      - primary:/var/lib/postgresql/data", "note": "Two PostgreSQL 17 servers. The primary takes the writes and runs `replication.sh` on its first start."}, {"code": "  standby:\n    image: postgres:17\n    user: postgres\n    environment:\n      PGPASSWORD: replicator\n    command: >\n      bash -c \"until pg_basebackup -h primary -U replicator -D /var/lib/postgresql/data -R -X stream;\n               do sleep 1; done; chmod 700 /var/lib/postgresql/data; exec postgres\"\n    volumes:\n      - standby:/var/lib/postgresql/data\n    depends_on:\n      - primary\nvolumes:\n  primary:\n  standby:", "note": "The standby starts empty, copies the primary with `pg_basebackup`, and `-R` writes the settings that make it follow the primary from then on, streaming every change. It accepts reads and refuses writes."}]}
```

Start both, give them a few seconds, and ask the primary who is copying it:

```
ana@vm:~/lab/cap$ docker compose up -d
 Network cap_default Creating 
 Network cap_default Creating 
 Volume cap_standby Creating 
 Volume cap_standby Creating 
 Volume cap_primary Creating 
 Volume cap_primary Creating 
 Volume cap_standby Created 
 Volume cap_standby Created 
 Volume cap_primary Created 
 Volume cap_primary Created 
 Network cap_default Created 
 Network cap_default Created 
 Container cap-primary-1 Creating 
 Container cap-primary-1 Created 
 Container cap-standby-1 Creating 
 Container cap-standby-1 Created 
 Container cap-primary-1 Starting 
 Container cap-primary-1 Started 
 Container cap-standby-1 Starting 
 Container cap-standby-1 Started 
ana@vm:~/lab/cap$ docker compose exec primary psql -U postgres -c "SELECT client_addr, state, sync_state FROM pg_stat_replication"
 client_addr |   state   | sync_state 
-------------+-----------+------------
 172.18.0.3  | streaming | async
(1 row)
```

One client, the standby, `streaming`, and `async`: by default PostgreSQL replicates asynchronously,
which the section on availability comes back to. Two shell variables save typing for the rest of the
lesson, one for each server's `psql`:

```sh
P="docker compose exec -T primary psql -U postgres"
S="docker compose exec -T standby psql -U postgres"
```

Create the stock table on the primary and read it from the standby:

```
ana@vm:~/lab/cap$ $P -c "CREATE TABLE stock (sku text PRIMARY KEY, units int); INSERT INTO stock VALUES ('coffee', 12)"
CREATE TABLE
INSERT 0 1
ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    12
(1 row)

ana@vm:~/lab/cap$ $S -c "UPDATE stock SET units = 0 WHERE sku = 'coffee'"
ERROR:  cannot execute UPDATE in a read-only transaction
```

The row written on the primary is on the standby a moment later, and the standby turns away a write:
**one copy decides, the other follows.** Now cut them apart.
