---
title: The hierarchy, directory by directory
version: 1
---

Lesson 1 section 13 gave you eight names so you could stop feeling lost. This is the full map, and
the point of it is not memorisation — it is that **the shape is standardised**, so a directory you
have never seen on a distribution you have never used still tells you what is in it.

The document is called the Filesystem Hierarchy Standard. Nobody reads it. Everybody follows it.

```
ana@vm:~$ ls -ld /bin /boot /dev /etc /home /lib /media /mnt /opt /proc /root /run /sbin /srv /sys /tmp /usr /var
lrwxrwxrwx  1 root root     7 Apr 22  2024 /bin -> usr/bin
drwxr-xr-x  2 root root  4096 Apr 22  2024 /boot
drwxr-xr-x  6 root root  2260 Sep 14 21:52 /dev
drwxr-xr-x 75 root root  4096 Sep 14 13:00 /etc
drwxr-xr-x  6 root root  4096 Sep 14 13:00 /home
lrwxrwxrwx  1 root root     7 Apr 22  2024 /lib -> usr/lib
drwxr-xr-x  2 root root  4096 Feb 17  2026 /media
drwxr-xr-x  6 root root  4096 Sep 14 19:46 /mnt
drwxr-xr-x 18 root root  4096 Sep 14 12:59 /opt
dr-xr-xr-x 87 root root     0 Sep 14 21:50 /proc
drwx------ 17 root root  4096 Sep 14 21:52 /root
drwxr-xr-x 15 root root  4096 Sep 14 20:52 /run
lrwxrwxrwx  1 root root     8 Apr 22  2024 /sbin -> usr/sbin
drwxr-xr-x  2 root root  4096 Feb 17  2026 /srv
dr-xr-xr-x 12 root root     0 Sep 14 21:58 /sys
drwxrwxrwt 38 root root 36864 Sep 14 21:59 /tmp
drwxr-xr-x 12 root root  4096 Feb 17  2026 /usr
drwxr-xr-x 11 root root  4096 Feb 17  2026 /var
```

Before the table, two things that listing just told you for free.

**Four of them are arrows.** `/bin`, `/lib`, `/sbin` and `/lib64` are not directories at all —
they are symlinks pointing into `/usr`. That is the *usr merge*, finished across every mainstream
distribution between 2012 and 2023, and section 11 explains what a symlink is. For now: `/bin/ls`
and `/usr/bin/ls` are the same file reached by two names.

**`/proc` and `/sys` have size zero.** Not empty — zero. Nothing in them is on a disk. Section 14
is about what they actually are.

## The whole map

| | what is in it | do you go there |
|---|---|---|
| `/bin`, `/sbin` | commands. `sbin` is the administrative half | rarely, by name — `$PATH` finds them for you |
| `/boot` | the kernel and the bootloader | almost never, and carefully |
| `/dev` | devices, as files | to name a disk or `/dev/null` |
| `/etc` | configuration for the whole machine, as text | **constantly** |
| `/home` | one directory per person | you live here |
| `/lib`, `/lib64` | shared libraries the programs load | no |
| `/media` | removable things, mounted automatically | when a USB stick appears |
| `/mnt` | somewhere to mount something by hand | when you mount something by hand |
| `/opt` | software installed outside the package manager | when a vendor put it there |
| `/proc` | the kernel and every running process, as files | for one number at a time |
| `/root` | the administrator's home. **Not** `/` | as root |
| `/run` | state for things running *right now*; empty at boot | to find a PID or a socket |
| `/srv` | data served by this machine — a website, a share | if whoever built it used it |
| `/sys` | devices and kernel settings, as files | to read a sensor, set a knob |
| `/tmp` | scratch. Anyone can write. Wiped on reboot | for a throwaway file |
| `/usr` | everything installed: programs, libraries, data | to look at what you have |
| `/var` | what **changes** while the machine runs — logs above all | **constantly** |

## The four you will actually spend your life in

**`/etc` is configuration, and it is text.** Service definitions, users, network, package sources,
timezone. There is no registry. A change is a diff, which means `/etc` can be read with `cat`,
searched with `grep`, compared, and kept in git.

**`/var` is what changes.** `/var/log` is where you go when something broke. `/var/lib` is where
services keep their working data — a database's files are usually under `/var/lib`. `/var/cache`
is throwaway. The rule of thumb: *if the machine writes it while running, it is under `/var`.*

```
ana@vm:~$ ls /var
backups  cache  lib  local  lock  log  mail  opt  run  spool  tmp
```

**`/usr` is what was installed**, and inside it the same shape repeats one level down:

```
ana@vm:~$ ls /usr
bin  games  include  lib  lib64  libexec  local  sbin  share  src
```

`/usr/bin` is programs, `/usr/lib` is what they load, `/usr/share` is data that does not depend on
the processor — icons, manuals, translations. **`/usr/local` is the one to remember**: it is for
software *you* put there by hand, and the package manager never touches it. That separation is
why a hand-built tool and a packaged one can coexist.

**`/home` is people.** One directory each, and normally the only one you can write in.

## The three that look alike and are not

**`/tmp`, `/var/tmp` and `/run`.** All three are scratch, and the difference is how long the
scratch lives:

| | survives a reboot | typical use |
|---|---|---|
| `/tmp` | no | a file that exists for the length of one command |
| `/var/tmp` | **yes** | a file a program needs across a restart |
| `/run` | no — it does not even exist until boot | PIDs, sockets, locks for running services |

**`/mnt` and `/media`.** `/media` is where the system mounts things it found — a USB stick turns
up as `/media/ana/KINGSTON`. `/mnt` is where *you* mount something deliberately. Nothing enforces
this; it is a convention, and following it means the next person can guess.

**`/opt` and `/usr/local`.** Both hold software outside the package manager. `/opt` is the vendor's
own tree, all in one directory — `/opt/somevendor/`, with its own `bin` and `lib` inside. Some
distributions hold a hard line on the difference. Most people use whichever the installer chose.

## Two names that mislead everybody exactly once

**`/usr` is not "user".** Historically it was — home directories lived there — but it has meant
*Unix System Resources* for forty years. People are in `/home`.

**`/root` is not `/`.** `/` is the top of the tree. `/root` is the administrator's home directory
sitting inside it. And you cannot look:

```
ana@vm:~$ cd /root
bash: cd: /root: Permission denied
```

Which is lesson 4, arriving on schedule.

## A real machine has more than this

The listing above named eighteen directories because it asked for eighteen by name. A plain `ls /`
on a machine you did not build will show extras: `lost+found` on an ext4 filesystem, `snap` on
Ubuntu, `swapfile`, a `data` somebody mounted, sometimes a directory a container runtime put
there.

**That is normal and it is not a problem.** The standard says what must be there and what it is
for; it does not forbid anything else. When you meet a name you do not recognise at the root of a
tree, `ls -l` it and look at who owns it — that answers the question more often than searching for
the name does.
