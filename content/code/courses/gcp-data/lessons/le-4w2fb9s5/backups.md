---
title: Backups, and the restore that overwrites
version: 1
---

**Cloud SQL keeps two kinds of backup, and both belong to the instance.** **Automated backups** are
taken once a day, in the window that `--backup-start-time` sets, and the oldest is deleted when a new
one pushes the count past the retention. **On-demand backups** are taken when somebody asks, with
`gcloud sql backups create --instance=quitanda-orders`, and stay until somebody deletes them. The
first backup holds the whole disk; later ones hold what changed since, and Google's documentation
says a deleted backup's data is folded into the next one, so deleting an old backup never breaks a
newer one.

## How many, and for how long

The reference gives the defaults, in the block quoted in the previous section: **7 automated backups
on Enterprise, 15 on Enterprise Plus, anything from 1 to 365** with `--retained-backups-count`. And the
transaction log for point-in-time recovery has its own retention, 7 days on Enterprise and up to 35
on Enterprise Plus. The two are not the same promise:

| | what it answers | how far back |
|---|---|---|
| point-in-time recovery | the database at any second | the log retention: 7 days, or up to 35 |
| an automated backup | the database at the moment of that backup | the backup count: 7 by default |
| an on-demand backup | the database before a migration, a release, a year end | until somebody deletes it |

**A backup is not a moment you can move.** It holds the disk at one time and nothing after it, so it
answers "the database as it was before Tuesday's migration" and point-in-time recovery answers "the
database as it was at 15:46:55". Take an on-demand backup before every migration that changes data, and
name it so that the person reading the list next year knows what it was for.

## A restore overwrites the instance it goes to

**This is the one difference from the laptop that costs people their data.** Point-in-time recovery,
on Cloud SQL as on the laptop, creates a new instance beside the old one. **Restoring a backup does
not**: `gcloud sql backups restore BACKUP_ID --restore-instance=quitanda-orders` replaces everything on
the target instance with the backup's contents, and Google's documentation says so in a warning, as
`gcloud` does in the confirmation it asks for. Every order written since that backup is gone from the
instance unless the log can bring it back.

**So restore into another instance first.** Create an empty one, restore the backup into it with
`--restore-instance` naming the new one, look at what it holds, and only then decide what to copy or
where to point the application. The reference adds that restoring by the backup's name, rather than
its ID, can create the new instance in the same command. None of these was run here: there is no
instance to restore to.

## Backups and a deleted instance

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --\[no-\]retain-backups-on-delete/,/^$/p'
     --[no-]retain-backups-on-delete
        Retain automated/ondemand backups of the instance after the instance is
        deleted. Use --retain-backups-on-delete to enable and
        --no-retain-backups-on-delete to disable.
```

**By default, deleting an instance deletes its backups with it**, which is the opposite of what
somebody deleting an instance by mistake needs. `--retain-backups-on-delete` keeps them after the
instance is gone, and `--deletion-protection` from lesson 6 refuses the deletion in the first place.
For a copy that outlives the instance and the project too, `gcloud sql export sql` writes a dump into
a Cloud Storage bucket, where the retention policy of lesson 3 can lock it for as long as the law asks.

## What it costs

Backups are billed for what they hold, at 0.12 a GiB-month in São Paulo. A 100 GiB database whose
week of daily backups adds 30 GiB of changes holds about 130 GiB, which is the last number on this
section's line:

```
ana@laptop:~/gcp$ python3 -c 'h = 730; print(round((2 * 0.062 + 8 * 0.0105) * h + 100 * 0.255, 2), round((2 * 0.1239 + 8 * 0.021) * h + 100 * 0.51, 2), round(20 * 30 * 0.14, 2), round(130 * 0.12, 2))'
177.34 354.53 84.0 15.6
```

**15.6 a month to be able to go back a week.** Against the 354.53 of a regional instance and the
177.34 of a replica, it is the cheapest line of this lesson, and the only one that undoes a mistake.
The four together are the shape of the decision: a standby for the machine, a replica for the reads
or the region, and backups with the log for the person who typed `DELETE FROM orders`.
