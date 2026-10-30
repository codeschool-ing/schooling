---
title: High availability, read replicas and the restore
version: 1
---

**A database can fail in two ways: the machine can go, or somebody can make a mistake.** A flexible
server has a different copy for each, and a third for reading, and confusing them is the commonest
way to discover in an incident that the copy you paid for was the wrong one.

**This section is taught from Microsoft's documentation, and nothing in it was run**: replication and
failover between machines are exactly what one container on a laptop cannot show.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"One write, in time from left to right, across four lanes: the application, the primary in zone 1, the high-availability standby in zone 2, and a read replica. The application sends COMMIT; the primary writes it to the standby, the standby acknowledges, and only then does the primary answer OK. After the OK, the primary ships the change to the read replica, which applies it later. The gap between the OK and the replica applying it is the replica lag.\" data-fig=\"l10-ha\"><defs><marker id=\"arr-l10-ha-amber\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--amber)\"></path></marker><marker id=\"arr-l10-ha-phosphor\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">application</text><line x1=\"170\" y1=\"50\" x2=\"700\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">primary, zone 1</text><line x1=\"170\" y1=\"105\" x2=\"700\" y2=\"105\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">standby, zone 2</text><line x1=\"170\" y1=\"160\" x2=\"700\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">read replica</text><line x1=\"170\" y1=\"215\" x2=\"700\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"190\" y1=\"50\" x2=\"228\" y2=\"101\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-phosphor)\"></line><text x=\"200\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><line x1=\"240\" y1=\"105\" x2=\"278\" y2=\"156\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-phosphor)\"></line><line x1=\"290\" y1=\"160\" x2=\"328\" y2=\"109\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-phosphor)\"></line><line x1=\"340\" y1=\"105\" x2=\"378\" y2=\"54\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-phosphor)\"></line><text x=\"392\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OK</text><text x=\"285\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">synchronous: the OK waits</text><line x1=\"420\" y1=\"105\" x2=\"588\" y2=\"211\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l10-ha-amber)\"></line><text x=\"505\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">asynchronous: shipped after the OK</text><circle cx=\"596\" cy=\"215\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"610\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">applied</text><line x1=\"384\" y1=\"240\" x2=\"384\" y2=\"252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"596\" y1=\"240\" x2=\"596\" y2=\"252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"384\" y1=\"246\" x2=\"596\" y2=\"246\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"490\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">replica lag</text><line x1=\"384\" y1=\"54\" x2=\"384\" y2=\"240\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 2\"></line><text x=\"690\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "The standby of high availability hears every write before the OK; a read replica hears it only after, which is why it can be read and why it can be behind."}
```

## High availability, for the machine

**High availability keeps a standby server that receives every write before the commit returns.**
When the primary fails, Azure promotes the standby and the server's name moves to it, and the
application reconnects to a database that lost nothing committed. There are two modes, and the
provider lists them when it is given a third:

```
ana@laptop:~/azure/tf/flex$ sed -i.bak 's/"ZoneRedundant"/"ZoneRedundant2"/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected high_availability.0.mode to be one of ["SameZone" "ZoneRedundant"], got ZoneRedundant2
```

| mode | where the standby is | what it survives |
|---|---|---|
| `ZoneRedundant` | another availability zone of the region | the loss of a server, or of a whole zone |
| `SameZone` | the same zone as the primary | the loss of a server, with less latency on each commit |

**The standby answers no queries**; it exists to be promoted. It doubles the compute and storage of
the server on the bill, and it is not offered on Burstable at all, which the next part shows
`validate` does not know.

```
ana@laptop:~/azure/tf/flex$ sed -i.bak 's/"GP_Standard_D2ds_v5"/"B_Standard_B1ms"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf
Success! The configuration is valid.

```

**That passes, and Azure would refuse it**: the documentation says high availability is not supported
on the Burstable tier. Like lesson 8's pool, the rule lives between two values, the tier and the
block, and only Azure checks the pair.

## Read replicas, for reading

**A read replica is a separate server that replays the primary's changes after they are committed.**
It has its own name, it answers queries, and it is always a little behind, which is the replica lag
the figure draws. Quitanda's analysts' reports at nine in the morning belong on one, away from the
checkouts. A replica can be in another region, and it can be promoted into a standalone server, which
makes it the copy a company uses to move a database between regions or to survive the loss of one.
What it cannot do is protect against a mistake: a `DELETE` without a `WHERE` reaches it a moment
later.

## The restore, for the mistake

**Backups are automatic, and a restore is to any point inside the retention period**, 7 to 35 days, as
the provider's range for `backup_retention_days` says:

```
ana@laptop:~/azure/tf/flex$ sed -i.bak 's/backup_retention_days         = 7/backup_retention_days         = 40/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected backup_retention_days to be in the range (7 - 35), got 40
```

Like lesson 8's databases, a restore creates a
new server and leaves the old one as it is, so the work after a mistake is restoring to a minute before
it and copying the rows back. **Geo-redundant backup** keeps the backups in the paired region as well,
so a server can be restored there if the whole region is lost. It is chosen when the server is created
and cannot be switched on later, which is why `main.tf` writes `false` down rather than leaving it
out.
