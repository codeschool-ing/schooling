---
title: A replica that follows the primary
version: 1
---

**A replica is a second database server that keeps itself a copy of the first**, applying every
change shortly after it happens. The first is called the **primary**: it is the only one that
accepts writes. The replicas accept reads, and if the primary is lost, one of them can take its
place.

PostgreSQL's replication rests on something it already does for its own safety. Before a change
is written to a table's files, it is written to the **write-ahead log**, the WAL: a record of
every change, in order, so that a crash in the middle of a write can be repaired on restart. A
replica connects to the primary and asks for that log as it is written, then applies it to its own
files. This is **streaming replication**, and the replica ends up byte for byte the same as the
primary, a little later.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Streaming replication in order. On the primary, a transaction's change is written first to the write-ahead log, then the primary tells the client it committed, then the change reaches the table files. The log is streamed to the replica, which writes it to its own log and applies it to its own table files, a little later.\"><rect x=\"20\" y=\"30\" width=\"330\" height=\"170\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">primary</text><rect x=\"370\" y=\"30\" width=\"330\" height=\"170\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">replica</text><rect x=\"40\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">INSERT …</text><text x=\"105\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 · change</text><path d=\"M170 90 L210 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M210 90 L203.7 93.0 L203.7 87.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"210\" y=\"70\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WAL</text><text x=\"270\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 · logged</text><path d=\"M270 110 L270 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M270 140 L267.0 133.7 L273.0 133.7 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"210\" y=\"140\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">table files</text><text x=\"270\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 · later</text><path d=\"M210 90 L120 150\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M120 150 L123.6 144.0 L126.9 149.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"78\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 · COMMIT to</text><text x=\"78\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the client</text><path d=\"M330 90 L390 90\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M390 90 L383.7 93.0 L383.7 87.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">stream</text><rect x=\"390\" y=\"70\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WAL</text><text x=\"450\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5 · received</text><path d=\"M510 90 L550 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M550 90 L543.7 93.0 L543.7 87.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"550\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"615\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">table files</text><text x=\"615\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 · applied</text><text x=\"535\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reads here see the world</text><text x=\"535\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">as of step 6</text></svg>", "caption": "The replica applies the primary's log after the client has been told the transaction committed. The gap is the lag."}
```

## Two new files

The primary needs a user that is allowed to ask for the log, and a line in its access rules that
lets that user connect for replication. Both go in a script that the PostgreSQL image runs once,
when the database is created, next to `schema.sql`:

```sh
# replication.sh
set -e
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator'"
echo "host replication replicator all scram-sha-256" >> "$PGDATA/pg_hba.conf"
```

And `compose.yaml` gets a fourth service. Here is the whole file as it stands from this lesson on:

```yaml
# compose.yaml
services:
  db:
    image: postgres:16.15
    environment:
      POSTGRES_USER: tickets
      POSTGRES_PASSWORD: tickets
      POSTGRES_DB: tickets
    volumes:
      - ./schema.sql:/docker-entrypoint-initdb.d/1-schema.sql:ro
      - ./replication.sh:/docker-entrypoint-initdb.d/2-replication.sh:ro
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15

  replica:
    image: postgres:16.15
    user: postgres
    environment:
      PGPASSWORD: replicator
      PGDATA: /var/lib/postgresql/replica
      DELAY: ${DELAY:-0}
    command:
      - bash
      - -c
      - |
        until pg_basebackup -h db -U replicator -D "$$PGDATA" -R -X stream; do sleep 1; done
        exec postgres -c recovery_min_apply_delay="$$DELAY"
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15
    depends_on:
      db:
        condition: service_healthy

  app:
    build: .
    environment:
      DATABASE_URL: postgresql://tickets:tickets@db/tickets
      REPLICA_URL: postgresql://tickets:tickets@replica/tickets
    cpus: 1
    depends_on:
      db:
        condition: service_healthy
      replica:
        condition: service_healthy

  lb:
    image: nginx:1.27.5
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "127.0.0.1:8080:80"
    depends_on:
      - app
```

Three things changed:

- **`db`** runs the two files in `/docker-entrypoint-initdb.d` in name order, so `1-schema.sql`
  creates the tables before `2-replication.sh` creates the user.
- **`replica`** is the same image started in a different way. Its command first runs
  `pg_basebackup`, which copies the primary's whole data directory over a replication connection,
  retrying until the primary is ready; `-R` writes the settings that tell the copy to keep following
  the primary afterwards, and `-X stream` copies the log written during the copy too. Then it
  starts PostgreSQL on that directory. `DELAY` is for section 05 and is zero until then. The `$$`
  is how Compose writes a `$` that the shell inside the container should see.
- **`app`** waits for both databases and is given a second address, `REPLICA_URL`, which the next
  section uses.

## Starting it

The image is rebuilt quietly first, then everything starts:

```
ana@lab:~/tickets$ docker compose build -q
 Image tickets-app Building 
 Image tickets-app Built 
ana@lab:~/tickets$ docker compose up -d
 Network tickets_default Creating 
 Network tickets_default Creating 
 Network tickets_default Created 
 Network tickets_default Created 
 Container tickets-db-1 Creating 
 Container tickets-db-1 Created 
 Container tickets-replica-1 Creating 
 Container tickets-replica-1 Created 
 Container tickets-app-1 Creating 
 Container tickets-app-1 Created 
 Container tickets-lb-1 Creating 
 Container tickets-lb-1 Created 
 Container tickets-db-1 Starting 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
 Container tickets-lb-1 Starting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker compose ps --format "table {{.Service}}\t{{.Status}}"
SERVICE   STATUS
app       Up Less than a second
db        Up 5 seconds (healthy)
lb        Up Less than a second
replica   Up 3 seconds (healthy)
```

Four containers. The replica waited for the primary to be healthy, copied it, and became healthy
itself.

## Asking the primary

The primary keeps a row per replica that is following it, in `pg_stat_replication`:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT client_addr, state, sync_state, replay_lag FROM pg_stat_replication'
 client_addr |   state   | sync_state |   replay_lag    
-------------+-----------+------------+-----------------
 172.18.0.3  | streaming | async      | 00:00:00.000128
(1 row)
```

One replica, at the replica container's address, `streaming`: it is receiving the log as it is
written. `async` means the primary does not wait for the replica before telling a client a
transaction is committed; lesson 3 is entirely about that word. `replay_lag` is how far behind the
replica's applied changes are, here an eighth of a millisecond, because nothing is happening.

## A replica refuses to write

```
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -c 'SELECT pg_is_in_recovery()'
 pg_is_in_recovery 
-------------------
 t
(1 row)

ana@lab:~/tickets$ docker compose exec replica psql -U tickets -c "UPDATE events SET name = 'Show One' WHERE id = 1"
ERROR:  cannot execute UPDATE in a read-only transaction
```

`pg_is_in_recovery()` is true on a replica: technically it is a server permanently recovering from
the primary's log. And any write is refused with an error, before it touches anything. **Two
servers that both accepted writes for the same rows would have to agree on the result**, which is
a much harder problem; a replica avoids it by never writing.
