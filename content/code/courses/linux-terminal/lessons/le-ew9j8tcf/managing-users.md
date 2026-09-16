---
title: Making, changing and removing an account
version: 1
---

There are two commands for creating a user and they are not the same tool.

| | is | behaviour |
|---|---|---|
| `useradd` | the low-level one, on every Linux | does exactly what you ask, and nothing else |
| `adduser` | a Perl script, Debian and Ubuntu only | asks questions, makes the home directory, sets a password |

**Use `adduser` by hand and `useradd` in a script**, because the first is friendly and the second
is predictable. Red Hat has no `adduser` worth the name — there it is a symlink to `useradd`, and
scripts that assume otherwise break when they move.

## `useradd` does the minimum, and the minimum surprises people

```
root@vm:~# useradd dora
root@vm:~# getent passwd dora
dora:x:1005:1008::/home/dora:/bin/sh
root@vm:~# ls -ld /home/dora
ls: cannot access '/home/dora': No such file or directory
```

Read that carefully. The account exists. Its home directory is recorded as `/home/dora`. **And
`/home/dora` does not exist.** The shell is `/bin/sh` rather than bash, because nobody said
otherwise.

`useradd` created a line. It did not create anything else, and it did not warn you.

An account whose home is missing still logs in, and lands in `/` with an error — one of the more
confusing first experiences a new user can be given. Say what you want:

```
root@vm:~# useradd -m -s /bin/bash -c 'Dora Silva' dora
root@vm:~# getent passwd dora
dora:x:1005:1008:Dora Silva:/home/dora:/bin/bash
root@vm:~# ls -la /home/dora
total 20
drwxr-x---  2 dora dora 4096 Sep 14 23:22 .
drwxr-xr-x 10 root root 4096 Sep 14 23:22 ..
-rw-r--r--  1 dora dora  220 Mar 31  2024 .bash_logout
-rw-r--r--  1 dora dora 3771 Mar 31  2024 .bashrc
-rw-r--r--  1 dora dora  807 Mar 31  2024 .profile
```

| | |
|---|---|
| `-m` | make the home directory |
| `-s` | login shell — section 02's field 7 |
| `-c` | the comment field, historically the full name |
| `-G` | supplementary groups at creation |
| `-u` | a specific UID, when it has to match another machine |
| `-r` | a **system** account: UID below 1000, no home |

## Where those three dotfiles came from

```
root@vm:~# ls -la /etc/skel
total 20
drwxr-xr-x  2 root root 4096 Feb 17  2026 .
drwxr-xr-x 75 root root 4096 Sep 14 23:22 ..
-rw-r--r--  1 root root  220 Mar 31  2024 .bash_logout
-rw-r--r--  1 root root 3771 Mar 31  2024 .bashrc
-rw-r--r--  1 root root  807 Mar 31  2024 .profile
```

**`/etc/skel` is the skeleton**, and `-m` copies it into the new home. Anything you put there
appears in every account made afterwards — a company `.bashrc`, a default editor setting, a README.
Note that `ls` without `-a` shows it as empty, which is lesson 3 section 14's dot doing its job.

It does not apply retroactively. Accounts that already exist keep what they have.

## `usermod` changes one field at a time

```
root@vm:~# usermod -aG team dora
root@vm:~# id dora
uid=1005(dora) gid=1008(dora) groups=1008(dora),1004(team)
root@vm:~# usermod -s /usr/sbin/nologin dora
root@vm:~# getent passwd dora
dora:x:1005:1008:Dora Silva:/home/dora:/usr/sbin/nologin
```

The flags mirror `useradd`'s, plus a few of its own:

| | |
|---|---|
| `-aG` | **append** to the supplementary groups — lesson 4 section 08 on why `-a` matters |
| `-s` | change the shell |
| `-L` / `-U` | lock / unlock, the same as `passwd -l` |
| `-e 2026-12-31` | expire the account on a date |
| `-d /new/home -m` | move the home directory and update the record |

**`-l` renames the account, and only the account:**

```
root@vm:~# usermod -l dorasilva dora
root@vm:~# getent passwd dorasilva
dorasilva:x:1005:1008:Dora Silva:/home/dora:/usr/sbin/nologin
root@vm:~# ls -ld /home/dora
drwxr-x--- 2 dorasilva dora 4096 Sep 14 23:22 /home/dora
```

The name changed. **The home directory is still `/home/dora`**, and so is the record pointing at
it. The files still belong to her because they were always uid `1005` — lesson 4 section 07's
point, arriving from the other side. Renaming a person is `usermod -l newname -d /home/newname -m
oldname`, and the pieces are separate because they can be.

## `userdel`, and the directory it leaves behind

```
root@vm:~# userdel dorasilva
root@vm:~# getent passwd dorasilva
root@vm:~# ls -ld /home/dora
drwxr-x--- 2 1005 dora 4096 Sep 14 23:22 /home/dora
```

The account is gone — `getent` prints nothing. **The home directory is still there, and `ls` now
prints `1005` where a name used to be**, because there is nothing left to look the number up in.

That is the single most visible demonstration of section 02's claim that the filesystem stores
numbers. Nothing about those files changed. The mapping did.

`userdel -r` removes the home directory and the mail spool as well — and **it is worth not doing
by reflex.** The usual sequence when somebody leaves is:

1. lock the account, so nobody logs in as them: `usermod -L -e 1 name`;
2. remove their ssh keys, because section 06 explains why locking is not enough;
3. work out what they owned: `find / -uid 1005 2>/dev/null`;
4. hand those files to somebody, or archive them;
5. **then** delete the account.

Deleting first leaves orphaned files owned by a number — and the next account created gets the next
free UID, which on a small machine is frequently the one you just freed. Files that belonged to the
person who left now belong to the person who arrived, silently.

## Groups, briefly

```
groupadd deploy              # make one
groupdel deploy              # remove it
gpasswd -a bruno deploy      # add somebody
gpasswd -d bruno deploy      # remove somebody
```

`gpasswd -a` is `usermod -aG` without the way to get it wrong. And lesson 4 section 08's warning
applies to all of it: **the change does not reach a shell that is already open.**

## What to do on a machine with more than a handful of people

Nothing in this section scales past about twenty accounts on one machine. Beyond that, accounts
come from a directory — LDAP, Active Directory, a cloud identity provider — and `useradd` on the
machine is the wrong place to look.

The tell is `getent passwd` returning somebody who is not in `/etc/passwd`. Section 02 said to
build that habit for exactly this moment.
