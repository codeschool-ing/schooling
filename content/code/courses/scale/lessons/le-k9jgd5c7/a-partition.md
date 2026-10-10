---
title: A partition, caused on purpose
version: 1
---

To watch the choice of section 02 happen, the replica has to be cut off from the primary **while
clients can still reach both**. One network cannot do that: the replica would reach the primary by
the same route as everybody else. So this lesson's `compose.yaml` gives replication a network of its
own. Here is the whole file:

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
    networks:
      default:
      replication:
        aliases: [primary]
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
        until pg_basebackup -h primary -U replicator -D "$$PGDATA" -R -X stream; do sleep 1; done
        exec postgres -c recovery_min_apply_delay="$$DELAY"
    networks:
      - default
      - replication
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

networks:
  replication:
```

Three changes from lesson 2:

- a second network, **`replication`**, declared at the end;
- **`db`** joins it under a second name, `primary`, which exists only on that network;
- **`replica`** joins both, and copies and follows `primary` rather than `db`.

So the replica talks to the primary only over `replication`, and to the box office over `default`.
Taking the replica off `replication` is a partition between the two databases that leaves every
client's path intact. Restart the stack with the new file before going on:
`docker compose down`, then `docker compose up -d`.

## With a synchronous replica

The replica is made synchronous as in the last section, then cut off. A sale, with curl told to
give up after five seconds; the show's page; and two questions to the primary:

```
ana@lab:~/tickets$ docker network disconnect tickets_replication tickets-replica-1
ana@lab:~/tickets$ curl -s -m 5 -X POST localhost:8080/events/1/tickets; echo "curl exit: $?"
curl exit: 28
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "60eeb0566861"}
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT wait_event, query FROM pg_stat_activity WHERE wait_event = 'SyncRep'"
 wait_event | query  
------------+--------
 SyncRep    | COMMIT
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT sold FROM events WHERE id = 1'
 sold 
------
    0
(1 row)

ana@lab:~/tickets$ docker network connect tickets_replication tickets-replica-1
ana@lab:~/tickets$ sleep 10
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT sold FROM events WHERE id = 1'
 sold 
------
    1
(1 row)

ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 999999, "host": "60eeb0566861"}
```

**The sale did not answer.** curl gave up after five seconds with exit code 28, its code for a
timeout. The primary had the sale on its own disk and was waiting, `SyncRep`, for a replica that
could not hear it. Until it hears, it will not say the sale happened, **not even to itself**: a
query on the primary still sees `sold = 0`. The show's page, read from the replica, says what it
said before, which in this case is also the truth.

That is the consistent choice: **no client can see a sale that is not on both machines**, and the
price is that no sale can finish while the two cannot talk. The box office became unavailable for
writes, by design.

Then the network comes back. Ten seconds later, `sold` is 1 and the page says 999 999: the waiting
commit was delivered to the replica and completed.

**Look at what the buyer experienced.** Their request timed out, which reads as a failure, and the
ticket was sold anyway, a few seconds later. A timeout says nothing about what happened on the
other side; it only says the answer did not arrive in time. A buyer who tries again buys a second
ticket. Lesson 10 is about making a retry safe in exactly this situation.

## With an asynchronous replica

The same partition, with the replica as lesson 2 left it:

```
ana@lab:~/tickets$ docker network disconnect tickets_replication tickets-replica-1
ana@lab:~/tickets$ curl -s -m 5 -X POST localhost:8080/events/1/tickets; echo
{"event": 1, "seat": 1, "code": "cb5ad8d5b5fd9bea"}
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "8b97446b89dc"}
ana@lab:~/tickets$ sleep 5
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "8b97446b89dc"}
ana@lab:~/tickets$ docker network connect tickets_replication tickets-replica-1
ana@lab:~/tickets$ sleep 10
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 999999, "host": "8b97446b89dc"}
```

**The sale succeeds at once.** The primary does not wait for anybody. The page, read from the
replica, says a million seats are left, and five seconds later it still does: the replica is not
receiving anything, so it keeps answering with what it last knew, for as long as the partition
lasts. When the network returns, the replica catches up and the page is right again.

That is the available choice: **every request got an answer, and some of the answers were stale**.
For a show's page that is a fine trade. For "how many seats are left" when there are three, it is
how two buyers get the same seat, unless the sale itself checks on the primary, which this one
does.
