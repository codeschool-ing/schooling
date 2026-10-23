---
title: RPO and RTO: how much you lose and how long it takes
version: 1
---

Availability is about the ordinary failures, the ones measured in minutes and hours. Recovery is
about the bad one: the database corrupted, the storage lost, the data centre flooded. Two numbers
describe what a business accepts for that day, and each system gets its own pair.

| | stands for | the question it answers |
|---|---|---|
| RPO | recovery point objective | how much data, measured in time, may be lost? |
| RTO | recovery time objective | how long may the service be gone? |

**The RPO looks backwards from the failure and the RTO looks forwards.** An RPO of 15 minutes means
the recovered system may lack up to the last 15 minutes of work before the failure. An RTO of 8
hours means it is back, usable, within 8 hours of the failure.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-recovery\" aria-label=\"A timeline of a failure of SAP. On the left, the last log backup; 15 minutes later, the failure. The span between them is the RPO, the work that may be lost. From the failure, the RTO of 8 hours runs to the right, divided into the steps of recovery: 20 minutes to detect, 40 to decide, 4 hours to restore the database, 1 hour to apply the logs, 1.5 hours to check and reconnect. The steps take 7.5 hours, half an hour inside the objective.\"><defs><marker id=\"l12-recovery-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30.0 120.0 L170.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 94.0 L70.0 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"157.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">last log</text><text x=\"70.0\" y=\"170.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">backup</text><path d=\"M170.0 80.0 L170.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"165.0\" y=\"154.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">failure</text><path d=\"M166.0 90.0 L74.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-recovery-es-ah-paper-dim)\" marker-start=\"url(#l12-recovery-es-ah-paper-dim)\"></path><text x=\"120.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RPO 15 min: work</text><text x=\"120.0\" y=\"74.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">that may be lost</text><rect x=\"171.0\" y=\"106.0\" width=\"18.7\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M180.3 134.0 L180.3 162.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"180.3\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">detect</text><rect x=\"191.7\" y=\"106.0\" width=\"39.3\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M211.3 134.0 L211.3 178.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"211.3\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">decide</text><rect x=\"233.0\" y=\"106.0\" width=\"246.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">restore 2,400 GB</text><rect x=\"481.0\" y=\"106.0\" width=\"60.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"511.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">logs</text><rect x=\"543.0\" y=\"106.0\" width=\"91.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"588.5\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">check, reconnect</text><path d=\"M635.0 120.0 L700.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M635.0 100.0 L635.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"635.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">back after 7.5 h</text><path d=\"M666.0 80.0 L666.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M174.0 90.0 L662.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-recovery-es-ah-paper-dim)\" marker-start=\"url(#l12-recovery-es-ah-paper-dim)\"></path><text x=\"418.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RTO 8 h: until the service is usable again</text><text x=\"666.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">objective</text></svg>", "caption": "The RPO looks back from the failure, the RTO forward. The restore itself is half of the eight hours. (The RPO is drawn wider than its scale.)"}
```

## Two mistakes that sound like answers

The first is to read the RPO as a description of the backups. "We back up every night" is a
mechanism; the RPO is the target the mechanism has to meet, and a nightly backup meets an RPO of 24
hours and no better. Asked what Serra Alta could lose, three teams answered with their backup
schedule. **The objective comes from the business and the mechanism from the architect**, and the
first conversation has to be about what the business can stand to lose.

The second is to read the RTO as the time a restore takes. The restore is one step. Joana worked
out the steps for SAP with Edson, from a failure at an ordinary moment on a weekday:

| step | time |
|---|---|
| detect the failure and get the right people on a call | 20 min |
| decide to restore rather than repair, and which backup to use | 40 min |
| restore the 2,400 GB database at about 600 GB an hour | 4 h |
| apply the log backups to reach the latest point | 1 h |
| check the data, start the application servers, reconnect the integrations | 1.5 h |

That is 7.5 hours against an RTO of 8. **The restore is half of the RTO**, and the other half is
people, decisions and checks, none of which go faster under pressure.

## The objectives, system by system

The point of setting the pair per system is that systems deserve different ones. Joana's first
proposal, agreed with the owners:

| system | RPO | RTO | what meets it today |
|---|---|---|---|
| SAP ECC | 15 min | 8 h | log backups every 15 minutes, copied to the second data centre; a full backup every night |
| Portal B2B | 5 min | 2 h | the PostgreSQL write-ahead log archived at least every 5 minutes |
| Coleta | 0 for collections | 12 h | a nightly save, and the trucks' handhelds, which keep seven days |
| Documentum | 24 h | 24 h | nightly backups of the database and of the content files |

Coleta's row shows that **an RPO belongs to the data, not only to the machine that stores it.**
Coleta's own backup is a nightly save, so on its own it could lose a day. But every collection
started on a handheld that still holds it, and a restored Coleta can ask the trucks to send again.
The collections can be lost by Coleta and recovered from the edge, which makes their effective RPO
zero. The manual adjustments that Coleta's users key in during the day have no such copy, and for
them the RPO really is a day.

The SAP row has a number behind it as well. In the busiest hour SAP receives about 200 sales orders.
With log backups every 15 minutes, a failure just before the next backup can lose 15 minutes of them, which is about 50 orders. Somebody will have to enter each of them again from the EDI
messages, the portal's records and the sales reps' e-mails.

## What a lower RPO costs

The cost rises slowly at first and steeply near zero:

| RPO | the usual mechanism | what it costs |
|---|---|---|
| a day | a nightly backup | storage, and a restore that is slow |
| minutes | frequent log backups or log shipping to another site | a second site with storage, and the discipline to copy the logs |
| seconds | continuous asynchronous replication | a second site with a running copy of the system |
| zero | synchronous replication: a write completes only when both sites have it | a second site close enough that every write waits for it, and a slower write path for ever |

Every step down that table is paid for every day, whether the disaster comes or not. That is why
the RPO is a business decision: somebody has to say that 50 sales orders are worth the cost of the
second site, or are not.

## The restore that was never tested

A backup proves nothing until it has been restored. Documentum had been backed up every night since
2010, and nobody had restored it since the year it was installed.

Joana asked for a test restore into an empty environment. The restore finished, the system started,
and documents opened. Then Cláudia's team ran their checks and found 37 lab certificates whose
records existed but whose files did not. A document management system keeps its metadata in a
database and the content in files, and Serra Alta backed up the two at different times: the content
files at 23:00, the database at 02:00. Every certificate stored between 23:00 and 02:00, which is to
say the night shift's lab results, had a record in the restored database and no file in the restored
content. **Two backups of one system, taken at different moments, restore to a state that never
existed.** Nothing in the backup reports showed it, because each backup had succeeded.

The fix was to take both from one consistent moment. The finding was worth more than the fix:
Documentum's real RPO had never been 24 hours for the night shift's work, and nobody would have
known until the day the certificates were needed for an audit.

## The RPO of an integration

A restored system has gone back in time, and the systems around it have not. Suppose SAP is
restored to a point 15 minutes before its failure. In those 15 minutes, the bus delivered EDI orders
to SAP and sent the supermarket chains their acknowledgements; SAP sent invoices to Salesforce and
goods receipts to finance's reports. After the restore, the chains believe orders were received that
SAP does not have, and Salesforce shows invoices for documents that no longer exist.

So **every integration that touches a restored system has an RPO of its own**, and it is set by
whether the other side can send again. The questions for each one go into its contract:

- can the producer resend from a given time, and how far back? The bus's flows that keep a message
  store can replay; a partner who sent an EDI message once and forgot it cannot.
- is the consumer safe against receiving the same message twice, since a replay from "15 minutes
  before" will resend some that did arrive? That is lesson 10's idempotent consumer.
- what was in flight? IBM MQ writes persistent messages to its log, and they survive the queue
  manager restarting; non-persistent messages do not. A flow that sends payments as non-persistent
  messages has decided its RPO without anybody noticing.

After any restore, the runbook from the previous section applies: the system is in a degraded mode
until its integrations have been replayed and reconciled. Lesson 14 brings the same discipline of
reconciliation to a planned move of data, where there is time to rehearse it.
