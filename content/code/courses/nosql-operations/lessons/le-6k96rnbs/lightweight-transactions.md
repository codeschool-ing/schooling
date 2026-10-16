---
title: Lightweight transactions, and what they cost
version: 1
---

`QUORUM` reads and writes make a read see the last write. They do not stop **two writes racing**,
and the shop's monitor shows why. Two customers read `units = 1` at `QUORUM`, each decides there is
one left, each writes `units = 0` at `QUORUM`. Every statement succeeded, both customers were told
yes, and one monitor was sold twice. The check and the write were two operations, and nothing held
the row between them.

Cassandra's answer is the **lightweight transaction**, LWT: a write with an `IF` that the replicas
agree on before applying it, using the Paxos consensus protocol. It is lightweight next to a
relational transaction, because it covers one partition and one statement.

## Compare and set

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> UPDATE shop.stock SET units = 1 WHERE sku = 'MN-330';
cqlsh> UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330' IF units = 1;

 [applied]
-----------
      True

cqlsh> UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330' IF units = 1;

 [applied] | units
-----------+-------
     False |     0

cqlsh> INSERT INTO shop.stock (sku, name, units) VALUES ('KB-101', 'Mechanical keyboard', 5) IF NOT EXISTS;

 [applied]
-----------
      True

cqlsh> INSERT INTO shop.stock (sku, name, units) VALUES ('KB-101', 'Mechanical keyboard', 9) IF NOT EXISTS;

 [applied] | sku    | name                | units
-----------+--------+---------------------+-------
     False | KB-101 | Mechanical keyboard |     5

cqlsh> SERIAL CONSISTENCY
Current serial consistency level is SERIAL.
cqlsh> exit
```

Restock the monitor, then sell it twice with the same conditional `UPDATE`. **The first returns
`[applied] True`. The second returns `False` and the value it found**, `units` 0, so the
application learns in one round of conversation that it lost the race and why. The same shape
guards an insert: `IF NOT EXISTS` created the keyboard's row once, and the second attempt was
refused and shown the row that was already there, with its 5 units, untouched.

That is the tool for anything that must happen once: claiming a username, taking the last unit,
moving an order from `pending` to `paid` exactly once.

## The two consistency levels of a conditional write

A lightweight transaction has two levels, and `cqlsh` shows the second with `SERIAL CONSISTENCY`:

- **The serial level, `SERIAL` by default**, is for the Paxos rounds that decide whether the
  condition holds. It always needs a majority of replicas, which is why the conditional `UPDATE`
  with two nodes down was refused with `Cannot achieve consistency level SERIAL` while the session
  was at `ONE`. `LOCAL_SERIAL` is the same within one data centre.
- **The ordinary level**, the one `CONSISTENCY` sets, is for the commit that writes the result once
  it is decided.

So an LWT is unavailable whenever a majority is, and there is no level that makes it answer with
fewer.

## What it costs

Tracing an ordinary `UPDATE` and a conditional one on the same row, and counting the messages `c1`
sent to the other two nodes:

```
ana@vm:~$ docker exec c1 cqlsh -e "CONSISTENCY QUORUM; TRACING ON; UPDATE shop.stock SET units = 4 WHERE sku = 'KB-101';" | grep -oE 'Sending [A-Z0-9_]+ message to /[0-9.:]+' | sort | uniq -c
      1 Sending MUTATION_REQ message to /172.18.0.3:7000
      1 Sending MUTATION_REQ message to /172.18.0.4:7000
ana@vm:~$ docker exec c1 cqlsh -e "CONSISTENCY QUORUM; TRACING ON; UPDATE shop.stock SET units = 3 WHERE sku = 'KB-101' IF units = 4;" | grep -oE 'Sending [A-Z0-9_]+ message to /[0-9.:]+' | sort | uniq -c
      1 Sending PAXOS_COMMIT_REQ message to /172.18.0.3:7000
      1 Sending PAXOS_COMMIT_REQ message to /172.18.0.4:7000
      1 Sending PAXOS_PREPARE_REQ message to /172.18.0.3:7000
      1 Sending PAXOS_PREPARE_REQ message to /172.18.0.4:7000
      1 Sending PAXOS_PROPOSE_REQ message to /172.18.0.3:7000
      1 Sending PAXOS_PROPOSE_REQ message to /172.18.0.4:7000
      1 Sending READ_REQ message to /172.18.0.3:7000
      1 Sending READ_REQ message to /172.18.0.4:7000
rc=0
```

The plain write is **one message to each other replica**, a mutation. The conditional write is
**four rounds**: `PREPARE` to claim the right to propose, `READ` to fetch the current value and
check the condition, `PROPOSE` to agree on the new value, and `COMMIT` to apply it. Each round waits
for a majority before the next begins, so the conditional write costs about four round trips where
the plain one costs one. In one data centre that is a few milliseconds; across an ocean it is four
times the distance of lesson 1.

Two more costs follow from the same mechanism. Conditional writes to the **same partition** queue
behind each other, and under contention some fail with a timeout and must be retried, so an LWT on
a hot row is a bottleneck. And mixing conditional and plain writes on the same cells defeats the
point: a plain `UPDATE` does not take part in Paxos, and can overwrite a value an LWT just agreed on.
The rule is to use LWT for the few operations that must not race, keep every write to those cells
conditional, and leave everything else to the cheaper levels of the previous sections.
