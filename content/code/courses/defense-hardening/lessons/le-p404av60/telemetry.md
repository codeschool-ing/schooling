---
title: Telemetry, and where it comes from
version: 1
---

**Telemetry is the record of what happened on a machine, kept so that somebody can ask about it
later.** Three kinds carry most of the weight on a server, and `web` already produces two of them
without anybody installing anything.

**Processes, with their parents.** Every running program has a parent, the process that started
it, and the tree they form is the most useful single thing an analyst can read. On `web` the
portal and its front door look like this:

```
ana@web:~$ ps -eo user,pid,ppid,args --forest | grep -E "nginx|portal|sshd" | grep -v grep
portal        55       1 /usr/bin/python3 /opt/portal/portal.py
root          73       1 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data      74      73  \_ nginx: worker process
www-data      75      73  \_ nginx: worker process
www-data      76      73  \_ nginx: worker process
www-data      77      73  \_ nginx: worker process
```

Read the tree. nginx's master runs as root and its four workers as `www-data`; the portal is one
Python process under the account `portal`, started by systemd, process 1. That is the normal
shape, and it is worth knowing before anything goes wrong, because an alert is a difference from
it. A `bash` hanging under the portal's process, or under nginx, would be the whole story in one
line.

**Logins.** The journal already records every SSH session, with the account, the address it came
from and the fingerprint of the key that was used. Log into `web` once from `admin`, so there is
one to read:

```
ana@admin:~$ ssh web true
ana@web:~$ sudo journalctl -u ssh --no-pager -o short-iso | grep Accepted
2026-10-23T02:02:02-03:00 web sshd[106]: Accepted publickey for ana from 192.168.60.30 port 57922 ssh2: ED25519 SHA256:uNd8LFH2OUEz1CO+izl+KXX0/r30W6iqUjUjMA8jRkk
```

A login is evidence of who, where nothing else is: the key's fingerprint names the key, and the
key, in a well-run place, names a person.

**The third kind is the kernel's own audit trail, and here it is missing.** Linux has an audit
system that can record every program started, every file opened and every permission changed, at
the moment it happens, from inside the kernel. `auditctl` is its control program, and on `web` it
cannot even list the rules:

```
ana@web:~$ sudo auditctl -l; echo "exit $?"
Error sending rule list data request (Operation not permitted)
There was an error while processing parameters
exit 255
```

The `Operation not permitted` is not a missing package; `auditd` is installed. **The kernel keeps
one audit trail for the whole computer, and does not hand a piece of it to each container.** A
process inside `web` asking for the audit rules is asking for the host's, and a container is not
allowed that. Your own Ubuntu virtual machine, outside the containers, has a kernel audit trail
that works; the machines of this lab do not, and that is why `build` switched `auditd` off.

That is also the first honest thing to say about EDR on containers in general. A product that
watches containers runs **on the host**, below them, where the kernel's events are, and sees every
container from there. An agent installed inside each container sees as much as this lesson's
sensor does.

## What a sensor records about a process

When a process starts, a useful record answers six questions, and the next section's sensor writes
one JSON line with a field for each:

| field | the question |
|---|---|
| `pid`, `ppid` | which process, and which one started it |
| `user` | which account it runs as |
| `exe` | which program file it is, resolved, so a renamed copy still says where it came from |
| `cmd` | the arguments it was given |
| `parents` | the chain above it, up to the service or the login it descends from |
| `time`, `host` | when, and on which machine, so lines from many machines can be put side by side |

The difference between `exe` and `cmd` matters more than it looks. `cmd` is whatever the process
says its name is, and a process may say anything. `exe` is the kernel's link to the file actually
being run, and only the kernel writes it.
