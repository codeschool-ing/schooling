---
title: What a user actually is
version: 1
---

A user is a **line in a text file**. Not a person, not a login screen, not an account in a
database somewhere — a line, in `/etc/passwd`, with seven fields separated by colons.

```
root@vm:~# getent passwd ana
ana:x:1001:1002::/home/ana:/bin/bash
```

| | field | here |
|---|---|---|
| 1 | **name** | `ana` |
| 2 | **password** | `x` — see below |
| 3 | **UID**, the number that matters | `1001` |
| 4 | **primary GID** | `1002` |
| 5 | **comment**, historically the full name | empty |
| 6 | **home directory** | `/home/ana` |
| 7 | **login shell** | `/bin/bash` |

Lesson 4 said the filesystem stores numbers. **This file is where a number gets a name.** Change
the UID in field 3 and every file ana owns belongs to somebody else — the files did not move, the
mapping did.

## Field 2 is an `x`, and that is the whole point

There was a password hash there once, and `/etc/passwd` has to be readable by everybody — `ls -l`
needs it to print a name. A world-readable file of password hashes is an offline cracking target,
so the hashes moved:

```
root@vm:~# ls -l /etc/passwd /etc/shadow /etc/group
-rw-r--r-- 1 root root    748 Sep 14 22:55 /etc/group
-rw-r--r-- 1 root root   1357 Sep 14 22:45 /etc/passwd
-rw-r----- 1 root shadow  875 Sep 14 22:59 /etc/shadow
```

Read those three modes with lesson 4 in your hands. `/etc/passwd` is `644` — anybody may read it,
and they must. `/etc/shadow` is `640`, owned by `root` and the group `shadow` — **nobody without
root or that group reads it at all.** The `x` is a pointer saying *the real thing is next door*.

Section 72 is what is in there.

## Most accounts are not people

```
root@vm:~# head -5 /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
```

Five lines and one of them could log in. A fresh Ubuntu has around thirty accounts and one human.

**They are there so that services are not root.** The web server runs as `www-data`, so if
somebody breaks into it they get `www-data` — which can read the site's files and very little
else. One account per service is a boundary, and it is the cheapest one the system has.

Find the people:

```
root@vm:~# awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3, $7}' /etc/passwd
ubuntu 1000 /bin/bash
ana 1001 /bin/bash
bruno 1002 /bin/bash
carla 1003 /bin/bash
```

**UIDs below 1000 are system accounts by convention**, and every distribution follows it. `65534`
is `nobody`, which is where the numbering stops.

Find the ones that are not:

```
root@vm:~# awk -F: '$7 ~ /nologin|false/ {print $1, $7}' /etc/passwd | head -8
daemon /usr/sbin/nologin
bin /usr/sbin/nologin
sys /usr/sbin/nologin
games /usr/sbin/nologin
man /usr/sbin/nologin
lp /usr/sbin/nologin
mail /usr/sbin/nologin
news /usr/sbin/nologin
```

## Field 7 is a decision, not a description

The login shell is what runs when the account logs in, and `/usr/sbin/nologin` is a real program
whose whole job is to print a refusal and exit. So is `/bin/false`, which does not even print.

**An account with `nologin` still works.** It owns files, it runs services, `sudo -u` can execute
things as it. What it cannot do is get a shell, which is exactly the point. When you create an
account for a service, this is the field that matters.

`/etc/shells` lists what the system considers a real login shell:

```
root@vm:~# cat /etc/shells
# /etc/shells: valid login shells
/bin/sh
/usr/bin/sh
/bin/bash
/usr/bin/bash
/bin/rbash
/usr/bin/rbash
/usr/bin/dash
/usr/bin/tmux
```

`nologin` is deliberately absent, and some services — `ftp`, for one — refuse an account whose
shell is not on that list.

## `getent` rather than `grep`

```
root@vm:~# getent passwd ana
ana:x:1001:1002::/home/ana:/bin/bash
root@vm:~# grep '^ana:' /etc/passwd
ana:x:1001:1002::/home/ana:/bin/bash
```

Identical output, and they are not the same command. **`grep` reads a file. `getent` asks the
system.** On a machine whose accounts come from LDAP, Active Directory or a cloud directory,
`/etc/passwd` holds the system accounts and nothing else, and `grep` will tell you a real colleague
does not exist.

Build the `getent` habit now, while the two agree.

## Two things that follow from all of this

**A user is not a session.** The line exists whether or not anybody is logged in, and section 74 is
about the difference.

**Deleting the line does not delete the files.** Every file that account owned now belongs to a
number with no name, and section 73 shows exactly what that looks like.
