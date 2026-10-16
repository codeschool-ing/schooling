---
title: Losing the primary, and the election that follows
version: 1
---

A primary goes away in one of two ways, and they look nothing alike from the inside. **Somebody stops
it**, for an upgrade or a restart, and it has time to hand over. **Or it dies**, a power cut or a
killed process, and the others have to notice the silence. MongoDB takes milliseconds over the
first and about ten seconds over the second, and the lab can show both.

## A planned stop

```sh
docker stop -t 30 mongo1
```

`-t 30` gives the server thirty seconds to stop cleanly before Docker kills it. Docker's default is
ten, and a replica-set member takes longer than that: it steps down, then spends up to fifteen
seconds telling clients it is going away before it exits.

```
ana@vm:~$ docker stop -t 30 mongo1
mongo1
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: '(not reachable/healthy)', health: 0 },
  { name: 'mongo2:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
ana@vm:~$ docker inspect --format '{{.State.FinishedAt}}' mongo1
2026-10-10T07:55:05.943247343Z
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'const m = rs.status().electionCandidateMetrics; ({ reason: m.lastElectionReason, electedAt: m.lastElectionDate, writableAt: m.wMajorityWriteAvailabilityDate })'
{
  reason: 'stepUpRequestSkipDryRun',
  electedAt: ISODate('2026-10-10T07:54:50.897Z'),
  writableAt: ISODate('2026-10-10T07:54:50.915Z')
}
```

Read the two timestamps against each other. `mongo2` was elected at 07:54:50.897 and could take
majority writes 18 ms later; `mongo1` finished stopping at 07:55:05.943, fifteen seconds after its
successor was already working. The reason, `stepUpRequestSkipDryRun`, names the mechanism: a
primary that steps down **asks an up-to-date secondary to stand at once**, and the election skips
the usual rehearsal because the old primary has already given up the job.

## A crash

`docker kill` sends `SIGKILL`, which ends the process with no chance to say anything, the nearest a
container gets to pulling the plug. Bring `mongo1` back first, so that the set has three members
again, and kill whichever member is now primary, `mongo2` in this run:

```
ana@vm:~$ docker start mongo1
mongo1
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo2:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
ana@vm:~$ docker kill mongo2
mongo2
ana@vm:~$ docker inspect --format '{{.State.FinishedAt}}' mongo2
2026-10-10T07:55:23.100639701Z
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'const m = rs.status().electionCandidateMetrics; ({ reason: m.lastElectionReason, electedAt: m.lastElectionDate, writableAt: m.wMajorityWriteAvailabilityDate })'
{
  reason: 'electionTimeout',
  electedAt: ISODate('2026-10-10T07:55:31.752Z'),
  writableAt: ISODate('2026-10-10T07:55:31.860Z')
}
```

`mongo1` came back as a secondary and stayed one. `mongo2` died at 07:55:23.101 and `mongo3` was
elected at 07:55:31.752, **8.65 seconds with no primary at all**. The reason is now
`electionTimeout`: members send each other a heartbeat every two seconds, and a secondary that has
not heard from a primary for `electionTimeoutMillis`, ten seconds by default, calls an election.
The ten seconds run from the last heartbeat the secondary received, not from the moment of the
crash, which is why the gap here is a little under ten.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"A timeline of the crash in this lesson's capture. Three lanes, one per member. mongo2 is primary until it is killed at 0 seconds; the heartbeats the others send it every two seconds go unanswered. For 8.65 seconds there is no primary. Then mongo3 runs for election, mongo1 votes for it, and mongo3 becomes primary; it accepts majority writes 0.11 seconds later.\"><defs><marker id=\"el9-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"el9-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"24\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mongo2</text><line x1=\"100\" y1=\"60\" x2=\"632\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"24\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mongo3</text><line x1=\"100\" y1=\"120\" x2=\"632\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"24\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mongo1</text><line x1=\"100\" y1=\"180\" x2=\"632\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><line x1=\"176\" y1=\"35\" x2=\"176\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></line><line x1=\"504.7\" y1=\"35\" x2=\"504.7\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></line><line x1=\"178\" y1=\"205\" x2=\"502.7\" y2=\"205\" stroke=\"var(--amber)\" stroke-width=\"1\" marker-end=\"url(#el9-ah-amber)\" marker-start=\"url(#el9-ah-amber)\"></line><text x=\"340.35\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no primary for 8.65 s</text><rect x=\"100\" y=\"51\" width=\"76\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"138.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">primary</text><text x=\"172\" y=\"42\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">killed</text><text x=\"252\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">×</text><text x=\"328\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">×</text><text x=\"404\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">×</text><text x=\"480\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">×</text><text x=\"366\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">heartbeats unanswered</text><rect x=\"100\" y=\"111\" width=\"404.7\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"138.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">secondary</text><rect x=\"504.7\" y=\"111\" width=\"127.30000000000001\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"568.35\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">primary</text><rect x=\"100\" y=\"171\" width=\"532\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"138.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">secondary</text><line x1=\"504.7\" y1=\"170\" x2=\"504.7\" y2=\"132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#el9-ah-phosphor)\"></line><text x=\"482.7\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">vote</text><text x=\"508.7\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">elected 8.65 s</text><text x=\"512.7\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">majority writes 8.76 s</text><line x1=\"176\" y1=\"222\" x2=\"176\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"176\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"252\" y1=\"222\" x2=\"252\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"252\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><line x1=\"328\" y1=\"222\" x2=\"328\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"328\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><line x1=\"404\" y1=\"222\" x2=\"404\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"404\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><line x1=\"480\" y1=\"222\" x2=\"480\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"480\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><line x1=\"556\" y1=\"222\" x2=\"556\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"556\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><line x1=\"632\" y1=\"222\" x2=\"632\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"632\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12</text><text x=\"632\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">seconds after the kill</text></svg>", "caption": "The crash, from the capture. Nobody decides that the primary is dead: the secondaries stop hearing it, and the ten-second election timeout, counted from the last heartbeat they got, does the rest."}
```

For those nine seconds a write has nowhere to go. A driver holds it and retries once a new primary
appears, which is why a well-configured application sees a slow request rather than an error; a
write that outlasts the driver's patience fails. **Ten seconds is a trade, not a constant.** Lower
it and a crash costs less, and a network that pauses for a few seconds starts elections nobody
needed.

## The old primary comes back

```
ana@vm:~$ docker start mongo2
mongo2
ana@vm:~$ docker exec mongo2 mongosh --quiet --eval 'rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'
[
  { name: 'mongo1:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo2:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo3:27017', state: 'PRIMARY', health: 1 }
]
```

`mongo2` rejoined as a secondary. It does not reclaim the job: the set has a primary and nothing
in its configuration prefers `mongo2`. It fetched what it had missed from `mongo3`'s oplog and went
on copying.

**Which member wins is the servers' decision, not yours.** In this run it was `mongo2` and then
`mongo3`; in yours it may be another, and every command from here on uses the names your own
`rs.status()` printed. An application never needs to know: the next section connects the way an
application does, and finds the primary on its own.
