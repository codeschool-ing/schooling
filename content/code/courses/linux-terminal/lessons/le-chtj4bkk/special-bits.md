---
title: setuid, setgid and the sticky bit
version: 1
---

Three more bits, a fourth octal digit, and each one exists because the nine characters could not
express something the system genuinely needed.

```
root@vm:~# stat -c '%a %A %n' /usr/bin/passwd /tmp /srv/team
4755 -rwsr-xr-x /usr/bin/passwd
1777 drwxrwxrwt /tmp
2775 drwxrwsr-x /srv/team
```

Three real things on this machine, one for each bit.

| | value | on a file | on a directory |
|---|---|---|---|
| **setuid** | 4 | run as the file's **owner** | (nothing, on Linux) |
| **setgid** | 2 | run as the file's **group** | new entries inherit the **group** |
| **sticky** | 1 | (nothing, on Linux) | you may remove **only your own** entries |

And they are shown by replacing an `x`, which is why you have to look twice:

| slot | `x` on | `x` off |
|---|---|---|
| owner's x | `s` — setuid | `S` |
| group's x | `s` — setgid | `S` |
| other's x | `t` — sticky | `T` |

**A capital means the special bit is set and execute is not**, which is nearly always a mistake —
a setuid program nobody may run does nothing at all.

## setuid: `passwd` is the reason it exists

```
-rwsr-xr-x 1 root root 64152 May 30  2024 /usr/bin/passwd
```

Changing your password means writing `/etc/shadow`, which is `-rw-------` and owned by root. You
cannot write it. And yet you can change your own password, without root, without asking anybody.

**The `s` is how.** When you run `passwd`, the process runs **as root** — as the file's owner —
rather than as you. It does the one narrow thing it exists to do, checks that the account you are
changing is your own, and exits.

That is a deliberate, audited hole in the model, and there are very few of them. Find them:

```
find /usr/bin -perm -4000 -ls
```

On a normal machine that is a short list — `passwd`, `sudo`, `su`, `mount`, `ping` on older
systems — and every entry is a program that was written knowing it would run as root.

**Never set it on something you wrote.** A setuid shell script is the classic vulnerability, and
Linux ignores the bit on scripts for exactly that reason; a setuid binary that takes a filename
from you and opens it is a way to read anything on the machine. If you find yourself reaching for
setuid, the answer you want is almost certainly `sudo` with a narrow rule — section 64.

## setgid on a directory: the one you will actually use

```
root@vm:~# ls -ld /srv/team
drwxrwsr-x 2 root team 4096 Sep 14 22:44 /srv/team
```

The `s` is in the group slot, and on a directory it means: **anything created in here belongs to
this directory's group**, regardless of who made it.

Watch it happen. Bruno's primary group is `bruno`, and his umask is the ordinary `022`:

```
bruno@vm:/srv/team$ umask
0022
bruno@vm:/srv/team$ touch fresh.md
bruno@vm:/srv/team$ ls -l fresh.md
-rw-r--r-- 1 bruno team 0 Sep 14 22:46 fresh.md
bruno@vm:/srv/team$ id -gn
bruno
```

**The file's group is `team`, and bruno's primary group is `bruno`.** Without the setgid bit it
would have been `bruno`, and ana — in `team` but not in `bruno` — would have been shut out of a
file in a directory built for sharing.

That is the whole recipe for a shared directory, and it is worth keeping:

```
sudo chgrp team /srv/team
sudo chmod 2775 /srv/team
umask 002
```

Group ownership, the setgid bit so new files inherit it, and a umask that leaves the group's `w`
alone — because setgid sets the *group* and the umask still decides the *bits*. Get one of the
three wrong and the directory half-works, which is the confusing kind of broken.

It is also inherited: a subdirectory made inside a setgid directory is itself setgid, so the whole
tree keeps the behaviour without anybody maintaining it.

## The sticky bit: why `/tmp` is not a disaster

`/tmp` is `1777` — **anybody may write it**. Section 59 said that a directory you can write is a
directory whose files you can delete, whoever owns them. On `/tmp` that would mean anybody could
delete anybody's work.

```
ana@vm:~$ printf 'anas file\n' > /tmp/anas.txt
ana@vm:~$ ls -l /tmp/anas.txt
-rw-r--r-- 1 ana ana 10 Sep 14 22:45 /tmp/anas.txt
```

```
bruno@vm:~$ ls -ld /tmp
drwxrwxrwt 38 root root 36864 Sep 14 22:45 /tmp
bruno@vm:~$ cat /tmp/anas.txt
anas file
bruno@vm:~$ rm /tmp/anas.txt
rm: cannot remove '/tmp/anas.txt': Operation not permitted
```

Bruno has `w` on `/tmp`. He can create files there and delete his own. **The `t` restricts removal
to the entry's owner** — and to the directory's owner, and to root.

It is called *sticky* for a historical reason that no longer applies: on early Unix it kept a
program's image in swap. The name outlived the feature.

You will meet it on `/tmp`, `/var/tmp`, and any directory somebody made world-writable on purpose.
**If you ever create a world-writable directory, set it.** `chmod 1777` rather than `chmod 777`,
and the difference is the whole of the safety.

## Setting them

```
chmod u+s file          # setuid
chmod g+s directory     # setgid
chmod +t directory      # sticky
chmod 2775 directory    # the same as g+s on 775
```

And the trap from section 57, repeated because it is the one that bites: **`chmod 755` on a `4755`
file clears the setuid bit.** A three-digit number sets the fourth digit to zero. Use the symbolic
form when you mean to change only the nine.

## What to do when you find one

A setuid binary you did not expect, in a place packages do not own, is worth taking seriously —
it is how a compromise persists. `find / -perm -4000 -type f 2>/dev/null` lists them, and
`dpkg -S` or `rpm -qf` says which package each belongs to. One that belongs to no package is the
one to ask about.
