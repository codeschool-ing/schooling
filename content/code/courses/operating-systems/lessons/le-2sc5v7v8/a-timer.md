---
title: A scheduled task, written from scratch
version: 1
---

The nightly backup needs three things: **a script** that does the work, **a service** that runs the
script, and **a timer** that starts the service. The script, `/usr/local/bin/office-backup`, compresses
`/etc/apt` into `/var/backups`. The other two are short text files:

```
ana@server:~$ cat /etc/systemd/system/office-backup.service
[Unit]
Description=Copy /etc/apt to /var/backups

[Service]
Type=oneshot
ExecStart=/usr/local/bin/office-backup
ana@server:~$ cat /etc/systemd/system/office-backup.timer
[Unit]
Description=Run office-backup every weekday at 02:00

[Timer]
OnCalendar=Mon..Fri 02:00
Persistent=true

[Install]
WantedBy=timers.target
```

- The **service** is `Type=oneshot`: it runs, finishes and stops, rather than staying up like cron.
- The **timer** has the same name, so it knows which service to start. **`OnCalendar=Mon..Fri 02:00`**
  is every weekday at two. **`Persistent=true`** means that if the server was off at two, the backup runs
  as soon as it starts again, instead of being skipped.
- **`WantedBy=timers.target`** is what `enable` hooks the timer into, so it is armed at every boot.

```
ana@server:~$ sudo systemctl daemon-reload
ana@server:~$ sudo systemctl enable --now office-backup.timer
Created symlink /etc/systemd/system/timers.target.wants/office-backup.timer → /etc/systemd/system/office-backup.timer.
ana@server:~$ systemctl list-timers office-backup.timer --no-pager
NEXT                          LEFT LAST                        PASSED UNIT                ACTIVATES
Sun 2026-09-27 23:00:00 -03 2 days Fri 2026-09-25 11:20:56 -03      - office-backup.timer office-backup.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
ana@server:~$ sudo systemctl start office-backup.service
ana@server:~$ sudo journalctl -u office-backup.service --no-pager -o cat | tail -3
backup written: /var/backups/etc-apt.tar.gz
office-backup.service: Deactivated successfully.
Finished office-backup.service - Copy /etc/apt to /var/backups.
ana@server:~$ ls -lh /var/backups/etc-apt.tar.gz
-rw-r--r-- 1 root root 3.6K Sep 25 11:24 /var/backups/etc-apt.tar.gz
```

1. **`daemon-reload`** tells systemd to read the new files. Forgetting it is the usual reason a unit
   "does not exist" right after being written.
2. **`enable --now`** armed the timer now and at every boot; `enable` printed the link it created.
3. **`list-timers`** shows when it will run next.
4. **`start office-backup.service`** ran the backup **now**, without waiting for the timer. It is how a
   scheduled task is tested, and it should be tested before anybody relies on it.
5. The journal kept the script's output, **`backup written`**, and the file is there.

**Look at the NEXT column.** It says Sunday at 23:00, not Monday at 02:00. This transcript prints times
in São Paulo, and the server's own clock zone is **UTC**, as lesson 3's `timedatectl` showed: 02:00 UTC
on Monday is 23:00 on Sunday in São Paulo. A backup meant to run while the office sleeps would run
while somebody is still working late. **Set a server's time zone when you install it**,
`sudo timedatectl set-timezone America/Sao_Paulo`, or write every schedule in UTC on purpose.
