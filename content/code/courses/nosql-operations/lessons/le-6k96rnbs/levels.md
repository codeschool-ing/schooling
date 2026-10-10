---
title: ONE, QUORUM and ALL on the same table
version: 1
---

Lesson 1 promised to run one Cassandra table both ways: refusing when copies cannot agree, and
answering anyway. **The table does not change between the two. Only the consistency level of each
statement does.** It is the number of replicas that must answer before the coordinator replies to
the client, and with three copies the three levels worth knowing are these:

| level | replicas that must answer, of 3 | what it survives |
| --- | --- | --- |
| `ONE` | 1 | two nodes down |
| `QUORUM` | 2, a majority: 3 divided by 2, rounded down, plus 1 | one node down |
| `ALL` | 3 | nothing |

A write is still **sent to every replica that is up**, whatever the level; the level is how many
acknowledgements the coordinator waits for before saying yes. A read asks as many replicas as the
level needs and returns the newest value among their answers.

## One node down

Stop `c3` the way a crash or a reboot would take it out, and confirm the cluster has noticed:

```
ana@vm:~$ docker stop c3
c3
ana@vm:~$ docker exec c1 nodetool status shop | grep -E "^(UN|DN)"
UN  172.18.0.3  80.02 KiB   16      100.0%            4e6c6943-bad2-4a89-a579-c61d93c795b4  rack1
UN  172.18.0.2  100.91 KiB  16      100.0%            4f53c005-bbb3-41b0-85b5-e123a1c42d23  rack1
DN  172.18.0.4  119.66 KiB  16      100.0%            1480b2b6-2542-4292-8efe-6389e94e299a  rack1
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY ONE
Consistency level set to ONE.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';

 units
-------
     1

(1 rows)
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';

 units
-------
     1

(1 rows)
cqlsh> UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330';
cqlsh> CONSISTENCY ALL
Consistency level set to ALL.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 dc1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level ALL" info={\'consistency\': \'ALL\', \'required_replicas\': 3, \'alive_replicas\': 2}')})
cqlsh> UPDATE shop.stock SET units = 1 WHERE sku = 'MN-330';
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 dc1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level ALL" info={\'consistency\': \'ALL\', \'required_replicas\': 3, \'alive_replicas\': 2}')})
cqlsh> exit
```

`DN` is down and normal: still a member of the ring, not answering. `ONE` and `QUORUM` read the
monitor's stock as before, and the `UPDATE` at `QUORUM`, selling the monitor, succeeded with two of
three replicas. **`ALL` refused, before trying**: `Cannot achieve consistency level ALL`, with
`required_replicas` 3 and `alive_replicas` 2. The coordinator knew `c3` was down from gossip, so it
did not send anything and wait; it answered `Unavailable` at once. The write at `ALL` was refused
the same way, which is the point of `ALL`: no write is acknowledged that is not on every copy.

`NoHostAvailable` around it is the Python driver inside `cqlsh` saying that the one host it
talked to, `127.0.0.1`, gave that answer. The server's error is the `Unavailable` inside.

## Two nodes down

```
ana@vm:~$ docker stop c2
c2
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 dc1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level QUORUM" info={\'consistency\': \'QUORUM\', \'required_replicas\': 2, \'alive_replicas\': 1}')})
cqlsh> CONSISTENCY ONE
Consistency level set to ONE.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';

 units
-------
     0

(1 rows)
cqlsh> UPDATE shop.stock SET units = 5 WHERE sku = 'MN-330' IF units = 0;
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 dc1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level SERIAL" info={\'consistency\': \'SERIAL\', \'required_replicas\': 2, \'alive_replicas\': 1}')})
cqlsh> exit
```

Now `QUORUM` is refused too: it needs 2 and has 1. **`ONE` still answers, and answers `0`**, the
sale made at `QUORUM` a minute ago, because `c1` was one of the two replicas that took it. That
is not luck you can count on in general: a read at `ONE` answers from whichever single replica it
reaches, and if that replica had missed the last write, `ONE` would return the old value with the
same confidence.

The last line is a lightweight transaction, the subject of the last section, and its refusal is
worth noticing now: **it asked for `SERIAL`, needing 2 replicas, although the session was at
`ONE`.** A conditional write needs a majority whatever level you set.

Bring the two nodes back and wait for all three to be up:

```sh
docker start c2 c3
until [ "$(docker exec c1 nodetool status 2>/dev/null | grep -c '^UN')" = 3 ]; do sleep 5; done
```

```
ana@vm:~$ docker exec c1 nodetool status shop | grep -E "^(UN|DN)"
UN  172.18.0.3  159.33 KiB  16      100.0%            4e6c6943-bad2-4a89-a579-c61d93c795b4  rack1
UN  172.18.0.2  100.91 KiB  16      100.0%            4f53c005-bbb3-41b0-85b5-e123a1c42d23  rack1
UN  172.18.0.4  164.56 KiB  16      100.0%            1480b2b6-2542-4292-8efe-6389e94e299a  rack1
```

That is the promise kept: the same table, the same row and the same cluster, and a read that
refused at one level answered at another. **In the theorem's terms from lesson 1, `ALL` and
`QUORUM` chose consistency and `ONE` chose availability**, statement by statement. The next section
puts the arithmetic under the choice.
