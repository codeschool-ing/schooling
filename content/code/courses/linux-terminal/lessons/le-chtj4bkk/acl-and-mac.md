---
title: Where twelve bits run out
version: 1
---

The model in this lesson has a hard limit, and it is easy to state: **a file has one owner and one
group.** So it can say *ana, and anybody in team, and everybody else* — and it cannot say *ana and
carla, and nobody else*.

The traditional answer is to make a group for every combination, which works until you have four
people and fourteen groups. Two mechanisms exist above the twelve bits, and they solve different
problems.

## ACLs: extra names on one file

An **access control list** lets a file carry permissions for named users and named groups beyond
the three rows.

```
ana@vm:~/acl$ ls -l report.txt
-rw-r----- 1 ana ana 11 Sep 14 22:46 report.txt
ana@vm:~/acl$ getfacl report.txt
# file: report.txt
# owner: ana
# group: ana
user::rw-
group::r--
other::---
```

With no ACL set, `getfacl` prints the ordinary mode in a different notation: `user::`, `group::` and
`other::` are the three rows you already know. Now add carla:

```
ana@vm:~/acl$ setfacl -m u:carla:r report.txt
ana@vm:~/acl$ ls -l report.txt
-rw-r-----+ 1 ana ana 11 Sep 14 22:46 report.txt
ana@vm:~/acl$ getfacl report.txt
# file: report.txt
# owner: ana
# group: ana
user::rw-
user:carla:r--
group::r--
mask::r--
other::---
```

Two things changed. There is a new line, `user:carla:r--`. And `ls -l` now ends the mode with a
**`+`** — which is the only sign in an ordinary listing that a file has an ACL at all.

It works:

```
carla@vm:~$ cat /home/ana/acl/report.txt
the report
```

Carla is not the owner, is not in the group, and `other` is `---`. She reads it because the ACL
names her.

`-m` modifies, `-x` removes one entry, `-b` removes them all:

```
ana@vm:~/acl$ setfacl -x u:carla report.txt
ana@vm:~/acl$ getfacl report.txt
# file: report.txt
# owner: ana
# group: ana
user::rw-
group::r--
mask::r--
other::---
```

### The `mask` line, which is where people get caught

`mask::r--` is a **ceiling** on every entry except the owner's and `other`'s. An entry granting
`rw-` under a mask of `r--` gives `r--`. That is not a bug; it is how a file with an ACL still
behaves sensibly when somebody runs `chmod` on it.

And that is the trap: **`chmod g+w` on a file with an ACL changes the mask, not the group's own
entry.** The `ls -l` middle row for an ACL'd file *is* the mask, which means the ordinary listing
is telling you something subtler than it looks. Read `getfacl` when a `+` is present.

### What they are good for, and what they cost

| | |
|---|---|
| good for | one person who needs access to one tree, with no new group |
| | a web server that must read a directory somebody else owns |
| | default permissions for a whole directory — `setfacl -d` |
| cost | invisible in `ls -l` except for one character |
| | `cp` drops them unless you say `-p` or `--preserve=all` |
| | `tar` drops them unless you say `--acls` |
| | not every filesystem supports them |

**That third cost is the one that bites.** A backup that silently loses its ACLs looks fine until
the restore. If a tree depends on ACLs, the tool that copies it has to be told.

`setfacl -d -m g:team:rwx /srv/shared` sets a *default* ACL — permissions that new files in that
directory inherit. It is the ACL answer to section 63's setgid bit, and it can do more, because it
can name individuals.

## SELinux and AppArmor: a different question entirely

Everything so far is **discretionary** access control — *discretionary* because the owner decides.
Ana owns the file, so ana chooses who reads it.

**Mandatory access control** sits above that, and the owner does not get a vote. A policy, written
by whoever built the system, says what each program may touch. The nginx process may read
`/srv/www` and may not read `/home` — **even as root**, and even if the bits allow it.

| | |
|---|---|
| **SELinux** | Red Hat, Fedora, Rocky, Alma. Labels on every file and process |
| **AppArmor** | Ubuntu, Debian, SUSE. Profiles attached to program paths |

The point of both is containment rather than permission: if a web server is compromised, the
attacker has a web server's access and not root's.

### How to tell whether one is in your way

A denial that makes no sense — the bits are right, the owner is right, `namei -l` is clean, and it
still fails — is the signature.

| | SELinux | AppArmor |
|---|---|---|
| is it on? | `getenforce` | `sudo aa-status` |
| what is labelled what? | `ls -Z` | profiles in `/etc/apparmor.d/` |
| what was denied? | `sudo ausearch -m avc -ts recent` | `/var/log/syslog`, `dmesg` |
| relabel a file | `restorecon -v path` | — |

On this machine neither is running, and the tools say so plainly:

```
root@vm:~# getenforce
bash: line 7: getenforce: command not found
root@vm:~# ls -Z /etc/hosts
? /etc/hosts
```

`command not found` means SELinux's userspace is not even installed, and the `?` where `ls -Z`
would print a label means the file carries none. **That is a useful thing to be able to check
quickly**, because half the advice you will read online assumes one of the two is on.

### The thing not to do

The first search result for an SELinux denial is always `setenforce 0`. It works, in the sense that
`chmod 777` works: the check is gone, along with every other check the policy was making.

The right move is to find the denial in the audit log, understand what was being asked, and fix the
label or add a rule. `audit2allow` will even write the rule for you from the log entry. On Ubuntu
the equivalent is `aa-complain` on the one profile, which logs instead of blocking while you work
out what it needs.
