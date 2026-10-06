---
title: The restore test
version: 1
---

The shop's data lives on `db`, under `/srv/shop`. Here is everything in it:

```
root@db:~# find /srv/shop -type f | sort
/srv/shop/data/customers.csv
/srv/shop/data/orders.csv
/srv/shop/invoices/2026-10-01.txt
/srv/shop/invoices/2026-10-02.txt
/srv/shop/invoices/2026-10-03.txt
```

Orders and customers in `data/`, and the invoices for the first three days of October in
`invoices/`. Now the backup job, which runs every night and has never reported a problem:

```
root@db:~# cat backup.sh
#!/bin/bash
# Nightly backup of the shop's data, written in March.
set -e
day=$1
tar --sort=name --mtime='2026-10-04 18:00:00 -0300' --owner=0 --group=0 --numeric-owner \
    -cf - -C /srv/shop data | gzip -n > /backup/shop-$day.tar.gz
root@db:~# ./backup.sh 2026-10-04
root@db:~# tar -tzf /backup/shop-2026-10-04.tar.gz
data/
data/customers.csv
data/orders.csv
```

`backup.sh` uses `tar` to pack a folder into one file and `gzip` to compress it, and writes the result
to `/backup` with the day in its name. Run for 4 October, it prints nothing, which for a Unix program
means success. `tar -tzf` lists what the archive contains, and that is the first clue: `data/` and its
two files. Nothing else.

Most people would stop here. The job ran, the file exists, it has the orders in it. **A restore test
does not ask whether the backup ran. It asks whether the data comes back.** So ana restores the
archive into an empty folder and compares it with the live data:

```
root@db:~# mkdir restore && tar -xzf /backup/shop-2026-10-04.tar.gz -C restore
root@db:~# diff -r /srv/shop restore; echo "exit $?"
Only in /srv/shop: invoices
exit 1
```

`diff -r` compares two folders file by file and prints every difference. `Only in /srv/shop:
invoices` means a whole folder exists in the live data and is absent from the restore. `exit 1` is
`diff` saying the two are not the same.

The cause is in the job's first line: *written in March*. The invoices folder came later, and the job
was never told about it. It has backed up `data` every night since, successfully.
That success is what hid the problem: **no error, no alert, and no invoices.** Had the server died, the shop would have
restored its orders and lost every invoice, which in Brazil are documents a business is required to
keep.

### The fix, and the proof

```
root@db:~# sed -i 's/ data | gzip/ data invoices | gzip/' backup.sh
root@db:~# tail -2 backup.sh
tar --sort=name --mtime='2026-10-04 18:00:00 -0300' --owner=0 --group=0 --numeric-owner \
    -cf - -C /srv/shop data invoices | gzip -n > /backup/shop-$day.tar.gz
root@db:~# ./backup.sh 2026-10-05
root@db:~# rm -r restore && mkdir restore && tar -xzf /backup/shop-2026-10-05.tar.gz -C restore
root@db:~# diff -r /srv/shop restore; echo "exit $?"
exit 0
```

`sed` changes the job's last line so that `tar` packs `data invoices`, and `tail -2` shows the line as
it is now. The job runs for 5 October, ana clears the old restore and restores the new archive, and
`diff -r` prints nothing and exits 0: **the restore is identical to the live data.** That silence is
the result a restore test is looking for.

The lesson generalises beyond this one job. A backup selects what to copy, and the selection was
written at some point in the past. Anything added since is unprotected until somebody notices, and
only a restore compared with the live data notices. **Back up by including everything and excluding
what you have decided not to keep**, rather than by listing what to include, and the next new folder
is protected by default, like lesson 5's default deny turned around.
