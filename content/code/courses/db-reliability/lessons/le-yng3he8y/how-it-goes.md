---
title: How an attack reaches the backups first
version: 1
---

Ransomware is usually pictured as a single moment: the files are encrypted and a note appears. For
the people who later have to recover, the important part happened before that moment, often weeks
before, and it is the part this lesson is about.

Seen from the defending side, the reports of these attacks follow the same order again and again:

1. **A way in.** A stolen password, a phished laptop, a server left exposed to the internet, an
   unpatched service. Nothing about the database yet.
2. **Time inside.** The intruder looks around, quietly, for days or weeks, and arranges to keep
   access: an extra account, a key added somewhere, a scheduled task. Reports call this the **dwell
   time**, and it is long because quiet is the goal.
3. **The backups.** Before anything visible happens, the intruder finds and destroys whatever would
   let the victim recover without paying: snapshots deleted, backup repositories emptied, retention
   shortened, backup jobs disabled. Lesson 9's question, which credentials can delete the copies,
   is decided here.
4. **The damage.** Files encrypted, or databases overwritten, across as many machines as possible at
   once, usually at night or on a holiday.
5. **The demand.** Pay for the key. Often also pay so that a copy of the data, taken during the dwell
   time, is not published.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A timeline of an attack: the way in, weeks inside during which an extra account is created, the backups deleted, then the damage. A restore point just before the damage brings the data back and the account with it. A restore point before the way in is clean and loses more.\"><defs><marker id=\"l10a-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l10a-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><defs><marker id=\"l10a-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M20 80 L70 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M150 80 L170 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 80 L430 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 80 L570 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M650 80 L700 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10a-wi)\"></path><rect x=\"70\" y=\"64\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">way in</text><rect x=\"170\" y=\"64\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"290\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">weeks inside: an extra account</text><rect x=\"430\" y=\"64\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"490\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">backups deleted</text><rect x=\"570\" y=\"64\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">damage</text><path d=\"M560 130 L560 100\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10a-pa)\"></path><text x=\"560\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">restore here: data back, account too</text><path d=\"M45 170 L45 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10a-ph)\"></path><text x=\"30\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">restore here: clean, more lost</text></svg>", "caption": "Why the clean point is earlier than the damage. A restore to the moment before the damage brings back what the intruder left during the weeks inside; only a point before the way in is clean, and it loses everything since."}
```

Two things follow for a database administrator, and the rest of the lesson is built on them.

**The backups are a target, not a bystander.** Everything lesson 9 built (a copy elsewhere, behind
another credential, immutable until a date) exists because of step 3. A backup the intruder's
credentials can reach is deleted before anybody knows there is an intruder.

**The damage is not where the attack started.** A restore to the moment before the encryption
brings back the data and, with it, everything the intruder arranged during the weeks before: the
extra account, the changed configuration. The clean point is earlier than it looks, and the second
half of this lesson finds that out on the shop.

And one thing backups do not solve at all: **data that was copied out** during the dwell time is
outside your control whatever you restore. That is a matter for encryption at rest, access control
and the people who handle disclosure, not for this course, and it is named here so that nobody
mistakes a good restore for the end of the incident.
