---
title: A database in seconds
version: 2
---

**One `docker run` gives you a configured PostgreSQL with your schema and your sample data in it,
reachable from your own machine.** Four options do it, and one detail of the image's start-up decides
whether the first thing that connects to it works.

Ana wants the catalogue's table, with two books in it, every time she starts a fresh database. She
writes the setup as an SQL file, `initdb/01-schema.sql`, in a directory of its own:

```sql
CREATE TABLE books (
    id     serial PRIMARY KEY,
    title  text NOT NULL,
    author text NOT NULL
);
INSERT INTO books (title, author) VALUES
    ('The Left Hand of Darkness', 'Ursula K. Le Guin'),
    ('Dom Casmurro', 'Machado de Assis');
```

Then she starts the database:

```
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only -e POSTGRES_DB=shelf -v "$PWD/initdb":/docker-entrypoint-initdb.d:ro -v pgdata:/var/lib/postgresql/data -p 127.0.0.1:5432:5432 postgres:17
56f7a063833db11ab3c0ee2aef5277c1740218706ff97754fc614959c38c0022
```

Each option has one job:

- **`POSTGRES_PASSWORD`** sets the password of the `postgres` user. The image refuses to start
  without one.
- **`POSTGRES_DB=shelf`** creates a database called `shelf` besides the default one.
- **`-v "$PWD/initdb":/docker-entrypoint-initdb.d:ro`** bind-mounts the setup directory where the
  entrypoint looks for scripts. On first start it runs every `.sql` and `.sh` file there, in name
  order, which is why the file is called `01-…`.
- **`-v pgdata:…`** keeps the data in a named volume, lesson 8's habit.
- **`-p 127.0.0.1:5432:5432`** makes port 5432 of the container reachable on port 5432 of Ana's
  machine, and only from the machine itself. Lesson 17 is about that option.

## Ready, and not ready

Ana waits until PostgreSQL answers inside the container, then connects from her own machine with
`psql`, the PostgreSQL client lesson 5 installed on the host:

```
ana@vm:~$ time until docker exec db pg_isready -U postgres -q; do sleep 0.2; done

real	0m1.063s
user	0m0.083s
sys	0m0.049s
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT title, author FROM books"
psql: error: connection to server at "127.0.0.1", port 5432 failed: server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
```

**`pg_isready` said yes after about a second, and the connection failed anyway.** The reason is
the entrypoint. On first start, it runs a temporary server to execute the setup scripts, and that
server listens only on a Unix socket inside the container, so that nothing outside can reach a half
built database. `pg_isready` with no host checks that socket, found the temporary server, and
reported it ready. Then the entrypoint stopped it to start the real one, and Ana's `psql`, arriving
through the published port, met nothing.

Asking the question over TCP, the way the outside world will connect, gives the honest answer:

```
ana@vm:~$ time until docker exec db pg_isready -h 127.0.0.1 -U postgres -q; do sleep 0.2; done

real	0m0.423s
user	0m0.044s
sys	0m0.037s
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT title, author FROM books"
           title           |      author       
---------------------------+-------------------
 The Left Hand of Darkness | Ursula K. Le Guin
 Dom Casmurro              | Machado de Assis
(2 rows)
```

The container's log tells the whole sequence:

```
ana@vm:~$ docker logs db 2>&1 | grep -E "initdb.d/|init process complete|ready to accept connections"
2026-10-06 16:46:43.894 UTC [67] LOG:  database system is ready to accept connections
/usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/01-schema.sql
PostgreSQL init process complete; ready for start up.
2026-10-06 16:46:44.274 UTC [1] LOG:  database system is ready to accept connections
```

**Two "ready to accept connections" lines**, from two different servers: the temporary one, PID 67,
and the real one, PID 1, after the script ran and the init process completed. A readiness check that
tests something other than what the clients will use answers a different question; lesson 19 builds
a health check for Compose that asks the right one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline of the postgres image&#x27;s first start, left to right. The entrypoint creates the data files, starts a temporary server that listens only on a Unix socket inside the container, runs the scripts in docker-entrypoint-initdb.d, stops the temporary server, and starts the real server, which listens on TCP port 5432. A pg_isready on the socket says ready during the temporary phase; a client through the published port can only connect in the last phase.\"><defs><marker id=\"l9init-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">create data files</text><rect x=\"150\" y=\"60\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">temporary server · socket only</text><rect x=\"410\" y=\"60\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stop it</text><rect x=\"540\" y=\"60\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">real server · TCP 5432</text><rect x=\"170\" y=\"114\" width=\"210\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs 01-schema.sql</text><path d=\"M20 30 L700 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9init-ah-wire)\"></path><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><text x=\"275\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">pg_isready on the socket: ready</text><text x=\"275\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">psql through -p: connection closed</text><text x=\"620\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">pg_isready -h 127.0.0.1: ready</text><text x=\"620\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">psql through -p: works</text><text x=\"275\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">log line: ready to accept connections, PID 67</text><text x=\"620\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and again, PID 1</text></svg>", "caption": "On first start the image runs PostgreSQL twice. A check that asks the socket says ready during the first run; only a check over TCP waits for the second."}
```

## First start only

The setup scripts and the environment variables that create things run **once, when the data
directory is empty**. Ana removes the container and starts a new one against the same volume, this
time passing a different password:

```
ana@vm:~$ docker rm -f db
db
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=other -e POSTGRES_DB=shelf -v "$PWD/initdb":/docker-entrypoint-initdb.d:ro -v pgdata:/var/lib/postgresql/data -p 127.0.0.1:5432:5432 postgres:17
c1eff2b88f1f07916377771cbbd7c588bf01d2d9b6cbdde077c0e7072c634c6f
ana@vm:~$ docker logs db 2>&1 | grep -E "Skipping|ready to accept"
PostgreSQL Database directory appears to contain a database; Skipping initialization
2026-10-06 16:46:45.083 UTC [1] LOG:  database system is ready to accept connections
ana@vm:~$ PGPASSWORD=other psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT count(*) FROM books"
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "postgres"
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -U postgres -d shelf -c "SELECT count(*) FROM books"
 count 
-------
     2
(1 row)
```

The entrypoint found a database in the volume and skipped initialisation entirely: no scripts, and
no new password. **The password that works is still the first one**, stored inside the database, and
`POSTGRES_PASSWORD=other` was ignored. The books are there because the volume kept them, not because
the script ran again. To change a password later, change it in the database with SQL; to start over
from the scripts, remove the volume.
