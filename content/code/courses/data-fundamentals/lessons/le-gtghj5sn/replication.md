---
title: Replication: copies, and copies that are behind
version: 1
---

**A replica is a copy of the data on another machine, kept current by sending it every change. It
protects against losing a machine, and it does not protect against a mistake.** The wrong picture is
that a replica is a backup. It is not: a `DELETE` run by mistake on Monday at ten reaches every
replica within moments, exactly as faithfully as a correct write would. A backup is a copy from
before, kept apart, and that is `db-reliability`'s subject.

## A leader and its followers

The commonest arrangement gives one replica the job of accepting writes. That replica is the
**leader** (the older word is primary). It applies each write, records it in a log of changes, and
sends the log to the other replicas, the **followers**, which replay it in the same order. Reads can
go to any of them. Lesson 4 sends its heavy reads to a follower for exactly that reason: a copy that
answers analysts without slowing the app down is a follower, under the name *read replica*.

The decision that shapes everything else is when the leader tells the client a write is done.

- **Synchronously**, after at least one follower has confirmed it has the write too. A write that was
  confirmed survives losing the leader. The cost is that every write waits for the follower, and a
  follower that stops answering stops the writes.
- **Asynchronously**, at once, with the followers catching up afterwards. Writes are fast and a
  follower can fail without anybody noticing. The cost is that a follower is always somewhat behind,
  and if the leader dies, the writes it had not sent yet are gone.

Many systems take the middle: one follower synchronous, the rest asynchronous, so that every
confirmed write exists on two machines while the others cannot slow anything down.

## Reading something that is not there yet

How far a follower is behind is its **replication lag**. It is usually small, and it grows when the
leader is busy or the network is slow, which is exactly when people are reading. The program below
simulates one leader, one follower and a lag of 800 ms, which is a number chosen for the
demonstration rather than measured anywhere. ana docks her bicycle at the end of ride R000123, and
the app reads the ride back. Save it as `replica.py`:

```schooling-example
{"language": "python", "file": "spread/replica.py", "parts": [
{"code": "# spread/replica.py\nLAG_MS = 800                    # how far behind the follower runs, in this simulation\n\n", "note": "The follower runs 800 ms behind the leader. That number is this program's choice, not a measurement: a real follower's lag moves with the load."},
{"code": "leader = {\"R000123\": \"riding\"}\nfollower = dict(leader)\nlog = []                        # every write the leader made: (time in ms, key, value)\napplied = 0                     # how much of the log the follower has applied\n\n\n", "note": "Two copies of the same data, and the leader's log of changes. Both start with ride R000123 in progress."},
{"code": "def write(t, key, value):\n    leader[key] = value\n    log.append((t, key, value))\n    print(f\"t={t:4} ms  write {key} = {value} on the leader\")\n\n\n", "note": "A write changes the leader at once and goes on the log. Nothing reaches the follower yet."},
{"code": "def read(t, key, where):\n    global applied\n    while applied < len(log) and log[applied][0] + LAG_MS <= t:\n        _, k, v = log[applied]\n        follower[k] = v         # the follower replays the leader's log, late\n        applied += 1\n    value = (leader if where == \"leader\" else follower)[key]\n    print(f\"t={t:4} ms  read  {key} from the {where:8} -> {value}\")\n\n\n", "note": "Before a read, the follower replays every entry of the log that is at least 800 ms old. Then the read answers from whichever copy it was sent to."},
{"code": "write(0, \"R000123\", \"docked\")\nread(50, \"R000123\", \"follower\")\nread(50, \"R000123\", \"leader\")\nread(900, \"R000123\", \"follower\")\n", "note": "The ride ends at 0 ms. The app reads it back at 50 ms, once from each copy, and once more from the follower at 900 ms."}
]}
```

```
ana@lab:~/roda/spread$ python replica.py
t=   0 ms  write R000123 = docked on the leader
t=  50 ms  read  R000123 from the follower -> riding
t=  50 ms  read  R000123 from the leader   -> docked
t= 900 ms  read  R000123 from the follower -> docked
```

Fifty milliseconds after the write, the leader says `docked` and the follower still says `riding`.
At 900 ms the follower has caught up and both agree. If the app sent ana's read to the follower, she
docked her bicycle and was told her ride was still running.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three timelines: the leader, the app and the follower. At 0 ms the app writes docked to the leader. At 50 ms it reads from the follower and gets riding, the old value. The change reaches the follower at 800 ms. At 900 ms the app reads from the follower again and gets docked.\" data-fig=\"replication-lag\"><defs><marker id=\"replication-lag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">leader</text><line x1=\"150\" y1=\"50\" x2=\"700\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the app</text><line x1=\"150\" y1=\"128\" x2=\"700\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">follower</text><line x1=\"150\" y1=\"206\" x2=\"700\" y2=\"206\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><line x1=\"170.0\" y1=\"122\" x2=\"170.0\" y2=\"57\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#replication-lag-ah)\"></line><text x=\"164.0\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">write</text><text x=\"176.0\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">docked</text><circle cx=\"170.0\" cy=\"50\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><line x1=\"174.0\" y1=\"54\" x2=\"570.0\" y2=\"200\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#replication-lag-ah)\"></line><text x=\"450.0\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the change arrives 800 ms later</text><circle cx=\"570.0\" cy=\"206\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><line x1=\"195.0\" y1=\"134\" x2=\"195.0\" y2=\"199\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#replication-lag-ah)\"></line><text x=\"203.0\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">read</text><text x=\"203.0\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">riding</text><text x=\"255.0\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">(the old value)</text><line x1=\"620.0\" y1=\"134\" x2=\"620.0\" y2=\"199\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#replication-lag-ah)\"></line><text x=\"628.0\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">read</text><text x=\"628.0\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">docked</text><text x=\"170.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"195.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50</text><text x=\"570.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">800</text><text x=\"620.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">900</text><text x=\"700\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ms</text></svg>", "caption": "The app writes to the leader and reads from a follower. A read that reaches the follower before the change does is answered with the old value."}
```

The usual remedy has a name, **read-your-writes**: whatever a person has just changed is read back
from the leader, for a while after the change or until the follower has replayed past it. Everybody
else's reads still go to the followers. It does not make the followers current; it makes sure the
one person who knows what the answer should be is not shown the old one. Lesson 10 lists this
promise beside the others a system can make about what a read returns.

## When the leader goes

If the leader stops, a follower is promoted to take its place, which is called **failover**. With
asynchronous replication the promoted follower may be missing the last writes the old leader
confirmed, and they are lost. Worse, an old leader that was only cut off, not dead, can come back
still believing it is the leader, and for a while two machines accept writes for the same data. That
is called **split brain**, and it is one of the things lesson 10 is about.

Two other arrangements exist and you should recognise them: **several leaders**, each accepting
writes and sending them to the others, which is common across data centres far apart; and **no
leader at all**, which is the next section.
