---
title: Honeytokens, bait that is data
version: 1
---

**A honeytoken is a piece of data that nothing legitimate ever reads.** Where a honeypot catches
somebody exploring the network, a honeytoken catches somebody going through files, which is what
anybody does on a server they have just got into: look for passwords, keys and connection strings
that open the next door.

On `web`, make a file that looks exactly like what they would hope to find: an old backup job's
database credentials, left in a forgotten directory. Every value in it is invented. There is no
`db.jatoba.example`, no account `svc_backup` anywhere in the firm, and the password opens nothing.

```
ana@web:~$ sudo mkdir -p /srv/portal/old-backup
ana@web:~$ printf "# old backup job, kept for reference\nDB_HOST=db.jatoba.example\nDB_USER=svc_backup\nDB_PASS=Ipe-Amarelo-2019\n" | sudo tee /srv/portal/old-backup/db-credentials.txt >/dev/null
ana@web:~$ sudo systemd-run -q --unit canary bash /home/ana/canary.sh
```

The last command starts `canary.sh`, the watcher on the file, as a service. Save it first in your
home on `web`; it is a few lines of shell around `inotifywait`, the same kernel notification lesson
9's guard used:

```schooling-example
{"language": "sh", "file": "canary.sh", "parts": [{"code": "#!/bin/bash\n# canary.sh: raise an alert whenever anybody opens the bait file.\nBAIT=/srv/portal/old-backup/db-credentials.txt\ninotifywait -m -q -e open --format '%e' \"$BAIT\" | while read -r event; do\n  logger -p auth.warning -t canary \"the bait file $BAIT was opened\"\ndone", "note": "The kernel tells `inotifywait` every time the file is opened, by anybody, for any reason, and each time a warning goes to the system log. Nothing reads the file during normal work, so the first line this writes is already worth a person's attention."}]}
```

Now open the file the way somebody looking through `/srv` would, and look at the log:

```
ana@web:~$ sleep 1; sudo cat /srv/portal/old-backup/db-credentials.txt | head -1
# old backup job, kept for reference
ana@web:~$ sleep 1; sudo journalctl -t canary -o short-iso --no-pager
2026-10-23T10:13:49-03:00 web canary[131]: the bait file /srv/portal/old-backup/db-credentials.txt was opened
```

The read itself succeeded, and that is intended: a honeytoken that refused to be read would tell
the reader it was bait. **The alert came from the opening, not from anything the reader did with
it.** Here the reader was you, with `sudo`; in a real case the line would arrive with the time,
and the system's other logs would say which account was active then.

## A token that keeps working after it leaves

The file names an account, `svc_backup`. **No system in the firm has that account**, so nothing
legitimate ever tries it. Somebody who copied the file and later tries the credentials, from any
machine, leaves a line that says so:

```
ana@desk:~$ ssh -o BatchMode=yes svc_backup@web true
svc_backup@web: Permission denied (publickey,password).
ana@web:~$ sudo journalctl -u ssh -o short-iso --no-pager | grep svc_backup
2026-10-23T10:13:51-03:00 web sshd[140]: Invalid user svc_backup from 192.168.60.20 port 36808
2026-10-23T10:13:51-03:00 web sshd[140]: Connection closed by invalid user svc_backup 192.168.60.20 port 36808 [preauth]
```

`Invalid user svc_backup from 192.168.60.20`: the name that exists only in the bait file was tried,
from `desk`. That line can be found by a rule as simple as a `grep`, and it means one thing.
**This is the strongest kind of honeytoken**, because it fires wherever the stolen data is used, not
only where it was stored. The same idea is a fake row in a client table that, if it ever appears in
an export or online, proves which copy leaked, or an e-mail address that exists only in one file and
receives mail the day the file is sold.
