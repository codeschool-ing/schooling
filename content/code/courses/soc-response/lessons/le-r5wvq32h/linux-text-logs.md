---
title: Linux: the files under /var/log
version: 1
---

On an Ubuntu machine, most logs an analyst reads are **text files under `/var/log`**, and the program
that writes the main ones is `rsyslog`. It does not decide what happens; it decides where each message
goes. Its rules are short enough to read whole:

```
root@soc:~# ls -l /var/log/auth.log /var/log/syslog /var/log/kern.log
-rw-r----- 1 syslog adm   0 Oct  7 04:34 /var/log/auth.log
-rw-r----- 1 syslog adm   0 Oct  7 04:34 /var/log/kern.log
-rw-r----- 1 syslog adm 310 Oct  7 04:34 /var/log/syslog
root@soc:~# grep -v '^#' /etc/rsyslog.d/50-default.conf | grep .
auth,authpriv.*			/var/log/auth.log
*.*;auth,authpriv.none		-/var/log/syslog
kern.*				-/var/log/kern.log
mail.*				-/var/log/mail.log
mail.err			/var/log/mail.err
*.emerg				:omusrmsg:*
```

Each rule has a **selector** on the left and a destination on the right. A selector is
`facility.severity`: the facility says which part of the system the message comes from, and the severity
how bad it is. `auth,authpriv.*` means every message about authentication, at any severity, goes to
`auth.log`. The second line sends everything else to `syslog`, except authentication (`.none`), so that
passwords' neighbourhood is not spread across a file more people can read. The `-` before a path tells
rsyslog not to force the line to disk after each write: faster, and a crash loses the last few lines.

The facilities and severities are numbers fixed by RFC 5424, and a SIEM receives them as numbers:

| severity | name | | facility | name |
|---|---|---|---|---|
| 0 | emerg | | 0 | kern |
| 1 | alert | | 1 | user |
| 2 | crit | | 3 | daemon |
| 3 | err | | 4 | auth |
| 4 | warning | | 10 | authpriv |
| 5 | notice | | 16 to 23 | local0 to local7 |
| 6 | info | | | |
| 7 | debug | | | |

The `local` facilities are free for anything, which is why network equipment so often logs as `local7`.

Now one real authentication event. `su` switches user, and PAM, the library that checks who you are on
Linux, writes the session to the `authpriv` facility:

```
root@soc:~# su - ana -c true
root@soc:~# grep pam_unix /var/log/auth.log
2026-10-07T04:34:57.752346-03:00 soc su[9596]: pam_unix(su-l:session): session opened for user ana(uid=30033) by (uid=0)
2026-10-07T04:34:57.762003-03:00 soc su[9596]: pam_unix(su-l:session): session closed for user ana
```

The time stamp is **RFC 3339 with microseconds and the offset**, `-03:00`, which is Ubuntu 24.04's default
and the format worth asking for everywhere. Then the host, `soc`; the program and its process number,
`su[9596]`; and the message. Note the permissions in the listing above: `syslog adm`, mode `rw-r-----`.
**Only root and the `adm` group read these files**, so a user who is not in `adm` is refused even the
line they caused:

```
ana@soc:~$ logger -t backup 'nightly copy finished: 412 files'
ana@soc:~$ tail -n 1 /var/log/syslog
tail: cannot open '/var/log/syslog' for reading: Permission denied
root@soc:~# tail -n 1 /var/log/syslog
2026-10-07T04:34:57.776265-03:00 soc backup: nightly copy finished: 412 files
```

`logger` is how a script writes to syslog; with `-t` it names itself, and the line lands in `syslog`
because the default facility is `user`. Ubuntu puts the first account created at installation in `adm`;
everybody else is refused, which is correct for a file that records who logged in and from where.

A few more places under `/var/log` matter in an investigation:

| file | what it holds | how to read it |
|---|---|---|
| `auth.log` | logins, `sudo`, `su`, SSH, PAM | text |
| `syslog` | everything not routed elsewhere | text |
| `kern.log` | the kernel: devices, firewall lines logged by the kernel | text |
| `apt/history.log`, `dpkg.log` | software installed and removed, with dates | text |
| `wtmp`, `btmp`, `lastlog` | successful logins, failed logins, last login per user | binary: `last`, `lastb`, `lastlog` |
| `audit/audit.log` | the kernel's audit trail, when `auditd` is installed | `ausearch` |
| `journal/` | the systemd journal | `journalctl`, in the next section |
