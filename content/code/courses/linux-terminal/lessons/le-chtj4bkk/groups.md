---
title: Groups, and the one you did not know you had
version: 1
---

A group is a named set of accounts, and it is the unit of sharing on a Linux machine. Two people
who need the same files do not get one account between them and do not become root — they get put
in a group, and the files get that group.

```
ana@vm:~$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana),27(sudo),1004(team)
```

Three numbers and three names in one line, and it repays reading slowly.

## Primary and supplementary

**`gid=1002(ana)` is the primary group.** Every account has exactly one, it is recorded in
`/etc/passwd` beside the account, and **it is the group that new files get**. Ana's primary group
is called `ana`, which is a convention — Debian and Ubuntu give every user a personal group of
their own name, so that a shared directory is the exception rather than the default.

**`groups=1002(ana),27(sudo),1004(team)` is the full list**, primary plus supplementary. Ana is in
`sudo`, which is why section 64 will work for her, and in `team`, which is why she could read
`teamonly.txt`.

**All of them count for permission checks.** When the kernel asks "is this person in the file's
group", it checks the whole list. The primary group's only special job is deciding what new files
belong to.

`id` has a flag for each piece:

```
ana@vm:~$ id -u
1001
ana@vm:~$ id -un
ana
ana@vm:~$ id -gn
ana
ana@vm:~$ id -nG
ana sudo team
```

`-u` user, `-g` primary group, `-G` all groups, `-n` for names instead of numbers. `groups` on its
own is `id -nG` with a shorter name, and it takes an account:

```
ana@vm:~$ groups bruno
bruno : bruno team
```

## Where they are written down

```
ana@vm:~$ getent group team
team:x:1004:ana,bruno
ana@vm:~$ getent passwd ana
ana:x:1001:1002::/home/ana:/bin/bash
```

Two text files, one line each, colon-separated. `/etc/group` is `name:x:gid:members`, and those
members are the **supplementary** memberships. `/etc/passwd` is where the primary one lives — the
`1002` in ana's line, fourth field.

**So ana's membership of `team` is written in `/etc/group`, and her membership of `ana` is not.**
That catches people reading `/etc/group` looking for somebody and not finding them.

`getent` rather than `grep` is the habit worth building. It asks the system's name service, so it
answers correctly on a machine whose accounts come from LDAP or Active Directory rather than from a
file — and lesson 5 is where that matters.

## Adding somebody to a group

```
sudo usermod -aG team bruno
```

**The `-a` is not optional.** `usermod -G team bruno` sets his supplementary groups to exactly
`team` — removing every other one he had, silently. It is the single most common way to lock
somebody out of `sudo`, and it is an argument away from the correct command.

`gpasswd -a bruno team` does the same thing and cannot be got wrong in that particular way.

## The part that confuses everybody: it does not take effect

```
ana@vm:~$ id -nG
ana sudo team
ana@vm:~$ sudo usermod -aG deploy ana
[sudo] password for ana:
ana@vm:~$ id -nG
ana sudo team
ana@vm:~$ getent group deploy
deploy:x:1006:ana
```

The change worked — `/etc/group` says so on the last line — and `id` in this shell still does not
see it.

**Group membership is attached to a process when it starts**, and inherited by its children. Your
shell was started before the change, so it is carrying the old list, and so is everything you run
from it. Nothing will refresh it.

The real fix is to log out and log back in. There is also a way to get one shell with the new
group:

```
ana@vm:~$ newgrp deploy
ana@vm:~$ id -nG
deploy sudo ana team
ana@vm:~$ id -gn
deploy
ana@vm:~$ touch /tmp/newgrp-test.txt
ana@vm:~$ ls -l /tmp/newgrp-test.txt
-rw-r--r-- 1 ana deploy 0 Sep 14 22:56 /tmp/newgrp-test.txt
ana@vm:~$ exit
ana@vm:~$ id -nG
ana sudo team
```

Read what `newgrp` did. It started **a new shell** — that is why `exit` came back to the old one —
with `deploy` as the **primary** group, which is why the file it created belongs to `deploy` rather
than to `ana`.

That last part is the useful half: `newgrp` is how you create files as a group without changing
your account. `sg deploy -c 'command'` does it for one command instead of a whole shell.

**When somebody says "I added you to the group and it still does not work", this is why, about
nine times in ten.** Log out. Log back in. Then look at the permissions.

## Groups you did not create

A machine arrives with twenty or so, and the ones worth recognising:

| | |
|---|---|
| `sudo`, or `wheel` on Red Hat | may use `sudo` — section 64 |
| `adm` | may read the logs in `/var/log` |
| `docker` | may talk to the Docker daemon, **which is root in practice** |
| `www-data` | the account a web server runs as |
| `users` | a general group; some distributions use it, most do not |

**`docker` deserves the warning.** Anybody in it can start a container that mounts `/` and writes
to it, which is a full root escalation with no password. Putting somebody in the `docker` group is
the same decision as giving them `sudo`, and it is usually made as though it were not.
