---
title: A process for every connection
version: 1
---

Every connection to PostgreSQL is served by a **process of its own** on the server, started when the
client connects and gone when it leaves. That is simple and robust, and it is expensive in the two
places a busy application finds first: starting a process takes milliseconds, and each one holds its
own memory, so the server caps how many there may be with `max_connections`, 100 by default.

An application with a few web servers, each opening twenty connections, gets there quickly. So does
an application during a failover, when every client reconnects at once. Ask for more:

```
ana@vm:~$ psql -XAt shop -c "SHOW max_connections"
100
ana@vm:~$ createdb bench && pgbench -q -i -s 10 bench > /dev/null 2>&1
ana@vm:~$ pgbench -c 120 -T 5 -n bench 2>&1 | tail -n 3
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
pgbench: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
pgbench: error: could not create connection for client 100
```

The 101st client, `client 100` counting from zero, was refused with **`sorry, too many clients
already`**, and `pgbench` gave up. For an application this is an error on a page, at the moment of
most load.

Raising `max_connections` moves the wall without removing it: a thousand processes each wanting
memory and CPU time on a machine with four cores spend more time competing than working. What the
application needs is many **clients**; what the server does well is few **connections** kept busy.
A **connection pooler** sits between the two.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"On the left, 120 clients drawn as a column of small boxes. They all connect to PgBouncer in the middle, on port 6433, which holds a queue of waiting clients. From PgBouncer, 20 connections go to PostgreSQL on the right, on port 5432, where each connection is one server process. In transaction mode a client holds one of the 20 only for the length of a transaction.\"><rect x=\"20\" y=\"20\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 28 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"44\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 52 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"68\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 76 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"92\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 100 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"116\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 124 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"140\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 148 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"164\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 172 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"188\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 196 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"55\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">120 clients</text><rect x=\"260\" y=\"70\" width=\"160\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">PgBouncer</text><text x=\"340\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:6433</text><rect x=\"280\" y=\"124\" width=\"120\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"340\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">queue</text><rect x=\"560\" y=\"50\" width=\"140\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PostgreSQL</text><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:5432</text><text x=\"630\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one process each</text><path d=\"M422 100 L558 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M422 112 L558 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M422 124 L558 124\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"490\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">20 server connections</text><text x=\"490\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">held for one transaction</text></svg>", "caption": "A pool in transaction mode: many clients, a queue, and a few server connections that each client borrows for one transaction at a time."}
```
