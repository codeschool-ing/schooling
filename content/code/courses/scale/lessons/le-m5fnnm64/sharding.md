---
title: Sharding, the data on several servers
version: 1
---

**Sharding divides the rows of the data between several independent databases**, each holding a
share and none holding everything. Each database is a **shard**. Unlike a replica, a shard is not a
copy: a ticket lives on exactly one shard, and the others have never heard of it. Unlike a
partition, the pieces are on different servers, so their writes, their storage and their memory
add up.

That is what makes it the answer to the problem the other two cannot solve. **Writes scale out**:
two shards accept twice the sales, because each sale goes to one of them. The price is that
**something has to know which shard holds which row**, and that something is usually your program.

## The shard key

Every sharded system picks a **shard key**, the value that decides where a row lives. For the box
office, the natural one is the show: all the tickets of one show on one shard. That choice makes
three things true at once:

- **A sale touches one shard.** Selling a ticket for show 42 locks show 42's row and inserts
  show 42's ticket, both on the same server, in one ordinary transaction.
- **A question about one show asks one shard**, and gets a complete answer.
- **A question about many shows asks every shard**, and the program has to combine the answers.
  Section 10 is about that.

A bad shard key is one that most queries do not carry, so every query goes to every shard; or one
with a few values that take most of the traffic, so one shard is busy and the others idle. The
hot show of lesson 1 is exactly that second case: sharding by show puts every sale of the popular
concert on the same shard, and **sharding cannot split a hot key**, because the key is the unit it
divides by.

## Two shards in the lab

Two more PostgreSQL servers, each with an empty `tickets` table, in a Compose file of their own so
that they do not mix with the box office:

```sql
-- shard.sql
CREATE TABLE tickets (
  event_id int NOT NULL,
  seat     int NOT NULL,
  PRIMARY KEY (event_id, seat)
);
```

```yaml
# shards.yaml
name: shards

x-shard: &shard
  image: postgres:16.15
  environment:
    POSTGRES_USER: tickets
    POSTGRES_PASSWORD: tickets
    POSTGRES_DB: tickets
  volumes:
    - ./shard.sql:/docker-entrypoint-initdb.d/shard.sql:ro
  healthcheck:
    test: ["CMD", "pg_isready", "-U", "tickets"]
    interval: 2s
    retries: 15

services:
  shard0: *shard
  shard1: *shard

  router:
    build: .
    profiles: [run]
    volumes:
      - ./shards.py:/srv/shards.py:ro
    environment:
      SHARDS: >-
        postgresql://tickets:tickets@shard0/tickets
        postgresql://tickets:tickets@shard1/tickets
    command: ["python", "shards.py"]
    depends_on:
      shard0:
        condition: service_healthy
      shard1:
        condition: service_healthy
```

`x-shard` is a **YAML anchor**: the block is written once under a name Compose ignores, and
`*shard` repeats it for both services. `router` runs a Python program with the box office's image,
because that image already has `psycopg`; the `profiles` line keeps it from starting with the
shards, so it only runs when asked.

And the router itself:

```schooling-example
{"language": "python", "file": "shards.py", "parts": [{"code": "# shards.py\n\"\"\"Sell tickets on two shards, then ask a question that needs both.\"\"\"\nimport os\n\nimport psycopg\n\nSHARDS = [psycopg.connect(url, autocommit=True) for url in os.environ[\"SHARDS\"].split()]", "note": "One connection per shard, in a fixed order. The order is part of the design: shard 0 must always be the same database, or a ticket is looked for where it was never written."}, {"code": "\n\ndef shard_for(event_id):\n    return SHARDS[event_id % len(SHARDS)]", "note": "**The router**, the whole of it. The show's id is the **shard key**: even shows live on shard 0, odd ones on shard 1. Every part of the program that touches a ticket has to go through this function."}, {"code": "\n\nfor event_id in range(1, 101):\n    with shard_for(event_id).transaction():\n        for seat in range(1, event_id + 1):\n            shard_for(event_id).execute(\n                \"INSERT INTO tickets (event_id, seat) VALUES (%s, %s)\", (event_id, seat))", "note": "Show *n* sells *n* tickets, so the shows are of different sizes on purpose. Each show's tickets are written in one transaction, on one shard, which is the case sharding handles well."}, {"code": "\nfor number, shard in enumerate(SHARDS):\n    count, = shard.execute(\"SELECT count(*) FROM tickets\").fetchone()\n    print(f\"shard {number}: {count} tickets\")\n\nprint(\"show 42:\", shard_for(42).execute(\n    \"SELECT count(*) FROM tickets WHERE event_id = 42\").fetchone()[0], \"tickets, from one shard\")", "note": "How the tickets fell, and a question about one show, which the router sends to one shard."}, {"code": "\ntop = []\nfor shard in SHARDS:\n    top += shard.execute(\n        \"SELECT event_id, count(*) FROM tickets GROUP BY event_id ORDER BY 2 DESC LIMIT 3\").fetchall()\nprint(\"top three, from every shard:\", sorted(top, key=lambda row: -row[1])[:3])", "note": "A question about **every** show cannot be routed: each shard is asked for its own top three and the program merges the six rows. Section 10 is about what this costs."}]}
```

Start the shards, run the router once, and remove everything afterwards with
`docker compose -f shards.yaml down`. Compose's own progress goes to standard error, which
`2>/dev/null` hides, so that only the program's answer is printed:

```
ana@lab:~/tickets$ docker compose -f shards.yaml up -d
 Network shards_default Creating 
 Network shards_default Creating 
 Network shards_default Created 
 Network shards_default Created 
 Container shards-shard0-1 Creating 
 Container shards-shard1-1 Creating 
 Container shards-shard0-1 Created 
 Container shards-shard1-1 Created 
 Container shards-shard1-1 Starting 
 Container shards-shard0-1 Starting 
 Container shards-shard1-1 Started 
 Container shards-shard0-1 Started 
ana@lab:~/tickets$ docker compose -f shards.yaml run --rm router 2>/dev/null
shard 0: 2550 tickets
shard 1: 2500 tickets
show 42: 42 tickets, from one shard
top three, from every shard: [(100, 100), (99, 99), (98, 98)]
```

**Shard 0 holds 2550 tickets and shard 1 holds 2500**: the even shows, 2 + 4 + … + 100, and the odd
ones, 1 + 3 + … + 99. Show 42 was answered by one shard. The top three needed both: each shard
returned its own top three, and the program kept the best three of the six rows.

Look at what changed in the program compared with the box office. **Every query now begins by
choosing a connection**, and every query that cannot choose has to ask them all. That is the
permanent cost of sharding, and it is why it comes last in this lesson.
