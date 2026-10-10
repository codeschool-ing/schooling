---
title: What drills find, and the file that remembers
version: 1
---

After the moving-target run, the database went quiet and the drill ran a third time:

```
ana@vm:~$ ./restore-drill.sh > /dev/null
ana@vm:~$ cat drills.csv
when,backup,restore_s,recovery_s,verify_s,total_s,result
2026-10-10 16:50:15,20261010-164946F,2.2,2.5,6.0,16.7,ok
2026-10-10 16:50:34,20261010-164946F,3.2,2.5,6.7,17.9,DIFFERENT
2026-10-10 16:50:55,20261010-164946F,2.5,2.5,6.0,16.8,ok
```

Three lines of history: two good drills and the one that failed for its own reasons, each with the
backup it used and how long every phase took. Over months that file becomes the most useful record a
database administrator has:

- **The restore time, as a trend.** The phases grow with the data. A restore that took 20 minutes in
  January and 50 in June will take longer than the promise in lesson 8 some time in the autumn, and
  the file says so in time to act: a faster restore server, parallel restore, more frequent full
  backups so there is less log to replay.
- **The last good drill.** Asked during an audit or an incident "when did we last prove the backups
  work", the answer is a date and a line, not a memory.
- **The failures, kept.** A `DIFFERENT` that was explained, like the one above, is still a line, and
  the explanation belongs in a note beside it.

## The failures drills actually find

Real drills fail far more often on the way to the data than on the data itself. In rough order of
how often teams report meeting them:

1. **Something the restore needs is not where the backup is**: an encryption key, a password, the
   configuration file of the tool, a tablespace's directory, the extensions the database uses.
2. **The restore machine is not ready**: a different major version installed, too little disk, a
   port or a firewall rule, a directory with the wrong owner.
3. **The archive has a gap**, from a period when archiving was failing and nobody looked.
4. **The procedure is in one person's head**, and the drill is the first time anybody else has
   followed it.
5. **It is too slow**: the restore works and takes longer than the business can wait.
6. And sometimes, the one everybody imagines: **the backup is damaged.**

Only the last is a backup failure in the narrow sense. The rest are failures of **recovery**, and
every one of them stays invisible until somebody restores on purpose.
