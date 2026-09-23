---
title: Ownership, and why giving a file away needs root
version: 2
---

Two commands, and one rule that explains the whole section.

```
chown ana file          # change the owner
chown ana:team file     # change the owner and the group
chgrp team file         # change only the group
```

## Owner and group are numbers

```
ana@vm:~$ ls -l /srv/perm/teamonly.txt
-rw-r----- 1 ana team 13 Sep 14 22:45 /srv/perm/teamonly.txt
ana@vm:~$ ls -ln /srv/perm/teamonly.txt
-rw-r----- 1 1001 1004 13 Sep 14 22:45 /srv/perm/teamonly.txt
```

`-n` asks for the raw values, and there they are. **The filesystem stores `1001` and `1004`.** The
names are looked up when `ls` prints them, from `/etc/passwd` and `/etc/group`, which is section
08's subject.

That matters in two places. Copy a disk to a machine where uid 1001 is somebody else, and the files
now belong to that somebody. And inside a container, the same number maps to a different account
than it does outside — which is why a file written by a container turns up owned by a stranger.

## Only root may give a file away

```
ana@vm:~/perm$ ls -l public.txt
-rw-r--r-- 1 ana ana 6 Sep 14 22:44 public.txt
ana@vm:~/perm$ chown bruno public.txt
chown: changing ownership of 'public.txt': Operation not permitted
```

Ana owns the file and is refused. **An ordinary user cannot hand a file to somebody else**, even a
file they own outright.

The reason is quotas and accountability. If you could give files away, you could dump a hundred
gigabytes into a directory and then assign them all to a colleague, and their disk quota would pay
for it. It also means the owner of a file is somebody who actually chose to have it.

As root it works, and every form does:

```
root@vm:/srv/perm# ls -l public.txt
-rw-r--r-- 1 ana ana 22 Sep 14 22:45 public.txt
root@vm:/srv/perm# chown bruno public.txt
root@vm:/srv/perm# ls -l public.txt
-rw-r--r-- 1 bruno ana 22 Sep 14 22:45 public.txt
root@vm:/srv/perm# chown ana:team public.txt
root@vm:/srv/perm# ls -l public.txt
-rw-r--r-- 1 ana team 22 Sep 14 22:45 public.txt
```

`chown user` changes the owner and leaves the group. `chown user:group` changes both. `chown
:group` — with nothing before the colon — changes only the group, which is `chgrp` written another
way.

## The group is the half you *can* change

```
ana@vm:~/perm$ chgrp team public.txt
```

No complaint. Ana owns the file and is a member of `team`, and those are the two conditions:
**you may set a file's group to any group you belong to, on a file you own.**

That is the whole reason section 08 exists. The group is the part of the model an ordinary user
controls, and it is how two people share a file without anybody becoming root.

Try it with a group you are not in and it is refused for the same reason `chown` was.

## `-R`, and the two flags that matter with it

```
sudo chown -R www-data:www-data /srv/www
```

Recursive, and it is the normal way to hand a whole tree to a service account after deploying it.
Two options are worth knowing:

| | does |
|---|---|
| `-R` | the directory and everything under it |
| `--from=old:old` | change only entries that currently have that owner — a surgical fix |
| `-h` | act on a symlink itself rather than its target |
| `--reference=file` | copy another file's owner and group |

**`-R` follows into mounted filesystems**, which has surprised people who ran it at the top of a
tree with a network share underneath. `find ... -exec chown` with `-xdev` is the careful version.

## The mistakes worth naming

**`chown ana.team file`** — a dot instead of a colon. It works on GNU systems for historical
reasons and is ambiguous when a username contains a dot. Use the colon.

**`sudo chown -R $USER /`** — somebody trying to fix a permission problem in their home directory,
with a typo in the path. It rewrites the ownership of the whole system, and the machine does not
boot. There is no undo; the only recovery is a reinstall or a backup of the metadata. **Check the
path before you press enter on a recursive `chown`**, exactly as lesson 3 section 07 said for `rm
-rf`.

**Changing the owner does not change the mode.** A file that was `-rw-------` and owned by `ana` is
still `-rw-------` after `chown bruno` — now readable by bruno instead, and by nobody else. The two
are separate, and a deploy that fixes ownership but leaves a `600` file for a service running as
somebody else will still fail.
