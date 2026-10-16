---
title: The order of a recovery, and the decisions in it
version: 1
---

A ransomware recovery fails in a particular way: somebody restores quickly, reconnects everything,
and the intruder, still inside, does it again the next night with what they learned the first time.
The order of the steps matters more than their speed, and it is worth having written down before the
night it is needed.

1. **Isolate.** Cut the affected machines off from the network, and from each other, before anything
   else. Do not switch them off unless told to by whoever leads the response: a running machine holds
   evidence, in memory and in its logs, that a reboot destroys.
2. **Preserve.** Keep a copy of what is there, damaged database included, for the investigation and
   for any legal obligation. A snapshot of the damaged disks is enough; it is evidence, not a backup.
3. **Find a clean place to restore into.** New servers, built from scratch, with credentials that
   never existed on the old ones. Restoring onto the compromised machine restores onto the intruder's
   foothold.
4. **Find a clean copy.** Check the backups you intend to use before trusting them: does the repository
   look like it did (lesson 7's drill history helps), do the backups verify, was any retention or job
   changed recently. The immutable copy of lesson 9 is the one that cannot have been touched.
5. **Restore, then audit.** Restore to before the damage, and before you let anything connect, compare
   roles, functions, configuration and access rules against an inventory from before the intrusion, as
   the last section did.
6. **Change every credential**, everywhere the old ones were stored, and only then reconnect the
   application.
7. **Watch closely for a while.** The alerts of this lesson, tighter than usual, for weeks: the
   intruder knows your systems and may try again.

## Who decides what

Most of those steps are not the database administrator's decision alone. Whether to isolate a
production system, whether to involve the police or a regulator, whether and how to tell customers,
and whether to pay at all are decisions for the people who lead the organisation, usually with
lawyers and specialist responders. What the database administrator brings is the facts that make
those decisions possible: **which copies exist, which are known to be clean, how far back they go,
and how long a restore takes**, all measured in the earlier lessons of this course rather than
guessed at on the night.

Lesson 22 treats an incident as a whole: detecting, deciding, communicating and writing it up
afterwards. Ransomware is the incident where every part of that is under the most pressure, and
where having rehearsed it shows most.

## Rehearsing it

A **tabletop exercise** walks the steps above with the people who would do them, around a table,
against a made-up scenario, without touching any system: the backups were deleted at 02:00 last
Sunday, the database was overwritten on Wednesday night, what do we do now, and who does it. It costs
an afternoon, and it finds the gaps a script cannot: the phone number nobody has, the cloud account
only one person can log into, the passphrase that turns out to live on the server being restored.

Combine it once a year with a real restore from the immutable copy, onto clean servers, by somebody
who did not set the backups up, and the organisation will have done, before the attack, the hardest
thing it would otherwise have to do for the first time during one.
