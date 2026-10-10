---
title: A base backup and an archive: any moment after it
version: 1
---

Put the pieces of the last two lessons together. A base backup is the database at one moment,
together with a note, `backup_label`, saying where in the log recovery has to start. The archive is
every segment of the log since. Replaying the archive over the base backup can stop **anywhere**:
at the end of the base backup, at the last archived record, or at any point in between.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A timeline. A base backup taken on Sunday at 02:00, followed by a long row of archived segments up to now. A bracket under the whole stretch says any moment there can be restored. Further along, one segment is drawn missing, and a note says recovery ends there, however much comes after.\"><defs><marker id=\"l4t-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">base backup</text><text x=\"75\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sunday 02:00</text><rect x=\"140\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"174\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"208\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"242\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"276\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"310\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"344\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"378\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"412\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"446\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"480\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"514\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"548\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"582\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"616\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"650\" y=\"50\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"372\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">archived segments</text><text x=\"702\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">now</text><path d=\"M20 110 L20 118 L544 118 L544 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"282\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">any moment here can be restored</text><path d=\"M563 84 L563 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4t-am)\"></path><text x=\"563\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">one missing segment</text><text x=\"563\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ends recovery here</text></svg>", "caption": "A base backup and the archive after it. Recovery can stop at any moment from the end of the backup onwards, as long as the chain of segments is unbroken; the first gap is as far as it can go."}
```

That is why archiving is called the backup that never ends. The base backup is taken nightly, or
weekly; the archive grows continuously in between; and the restorable moments are not a few points
a day but every committed transaction from the oldest base backup kept to the last segment archived.

Two consequences decide how the pieces have to be kept, and lessons 5, 6 and 7 rest on both:

- **A base backup without its log is useless, and the log without a base backup is useless.**
  Recovery starts from a base backup and needs every segment from that backup's start point,
  unbroken, up to the moment you want. One missing segment ends recovery there, however much
  archive comes after it. So the archive is kept from the start of the **oldest** base backup you
  intend to restore from, and an old base backup is only deleted together with the segments that
  only it needed.
- **The restore takes as long as the replay.** Recovering to a moment a week after the base backup
  means replaying a week of log, which on a busy database is hours. The interval between base
  backups is therefore a decision about restore time as much as about storage, and lesson 8 puts a
  number on it.

What is not here yet is how to stop at the moment you want, and how to tell the server what that
moment is. That is lesson 6. Lesson 5 first gives the base backups and the archive to a tool, which
keeps them together, verifies them and deletes them in the right order.
