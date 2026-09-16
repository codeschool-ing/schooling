---
title: Dotfiles, and the files that are not files
version: 1
---

Two kinds of thing in the tree are not what they look like. The first is hidden by a convention so
thin it is almost a joke. The second is not on a disk at all.

## A dot at the front, and that is the whole mechanism

```
bruno@vm:~$ ls
projects
bruno@vm:~$ ls -a
.  ..  .bash_logout  .bashrc  .cache  .config  .gitconfig  .local  .profile  .ssh  projects
```

One directory, two answers. **There is no hidden attribute.** `ls` skips names beginning with `.`
unless you ask, and so does the shell's `*` (section 10). Nothing else is involved: rename
`notes.txt` to `.notes.txt` and it is hidden; rename it back and it is not.

That convention exists because your home directory would otherwise be unusable. Every program you
run keeps its settings there, and none of them are things you want to see when you are looking for
your own files.

### What lives in them

| | holds |
|---|---|
| `.bashrc`, `.profile` | your shell's settings — lesson 9 |
| `.ssh/` | keys and known hosts. **The most sensitive directory you own** |
| `.gitconfig` | your name, your email, your aliases |
| `.config/` | the modern place: one subdirectory per program |
| `.local/` | programs and data installed for you alone |
| `.cache/` | throwaway. Safe to delete, and often large |

```
bruno@vm:~$ cat .gitconfig
[user]
        name = Bruno
        email = bruno@example.com
```

Plain text, like everything else. That is the point section 02 made about `/etc`, one level down:
**your settings are files you can read, diff and copy to another machine.**

### `.ssh` is the one to be careful with

```
bruno@vm:~$ ls -ld .ssh
drwx------ 2 bruno bruno 4096 Sep 14 22:27 .ssh
bruno@vm:~$ ls -la .ssh
total 12
drwx------ 2 bruno bruno 4096 Sep 14 22:27 .
drwxr-x--- 7 bruno bruno 4096 Sep 14 22:27 ..
-rw------- 1 bruno bruno   42 Sep 14 22:27 config
```

`drwx------` on the directory, `-rw-------` on what is inside: nobody but the owner, at all.
**`ssh` checks this and refuses to work if it is wrong**, which is the correct behaviour and
catches everybody once, usually after copying a key from somewhere with a permissive `cp`. Lesson
4 makes those characters readable.

### And `.cache` is the one to delete

```
bruno@vm:~$ du -sh .cache
8.0K    .cache
```

Eight kilobytes on a new account, and gigabytes on a working one. When section 13's hunt leads
into a home directory, `~/.cache` is usually the answer, and deleting it costs nothing but the
time to rebuild what was in it.

## `/proc` is the kernel, pretending to be files

```
ana@vm:~$ ls -ld /proc /sys
dr-xr-xr-x 91 root root 0 Sep 14 21:50 /proc
dr-xr-xr-x 12 root root 0 Sep 14 21:58 /sys
```

Size zero, on both. Nothing here is stored anywhere. `/proc` is a **filesystem the kernel makes
up as you read it** — and it is the purest expression of lesson 1's "everything is a file".

Ask it a question and it answers:

```
ana@vm:~$ cat /proc/uptime
2142.03 8389.82
ana@vm:~$ cat /proc/loadavg
0.00 0.02 0.00 1/112 2104
ana@vm:~$ head -3 /proc/meminfo
MemTotal:       16482220 kB
MemFree:        15875500 kB
MemAvailable:   15912844 kB
ana@vm:~$ grep 'model name' /proc/cpuinfo | head -1
model name      : Intel(R) Xeon(R) Processor @ 2.10GHz
```

Those numbers did not exist until you asked. Here is the proof, and it is worth a moment:

```
ana@vm:~$ ls -l /proc/uptime
-r--r--r-- 1 root root 0 Sep 14 21:50 /proc/uptime
ana@vm:~$ wc -c /proc/uptime
16 /proc/uptime
```

**`ls` says the file is zero bytes. `wc` read sixteen of them.** `ls` asked for the size and the
kernel said zero, because there is no content sitting anywhere to have a size. `wc` opened it, and
the kernel generated the answer on the spot.

**Why this matters beyond the trick:** it means every tool you already know works on the running
system. `cat`, `grep`, `head`, `wc` — no API, no special client. Lesson 6's `top` and `ps` are
reading `/proc` and formatting it for you; lesson 11 goes there directly when `top` is not enough.

### The numbered directories are processes

```
ana@vm:~$ ls /proc | head -20
1
10
104
11
1147
1163
12
...
```

One directory per running process, named by its PID. Inside each is everything about it — what it
is running, what it has open, how much memory it holds. And there is a shortcut:

```
ana@vm:~$ readlink /proc/self/exe
/usr/bin/readlink
```

`/proc/self` is *the process doing the reading*. So `readlink` asked which program it was, and the
answer was itself. Lesson 6 lives in these directories.

### `/proc/sys` is different: you can write to it

`/proc/sys` holds kernel settings rather than kernel facts, and writing a value into one of those
files changes the running kernel immediately:

```
ana@vm:~$ cat /proc/sys/kernel/hostname
vm
```

`sysctl` is the polite front end for the same files, and `/etc/sysctl.conf` is where you put a
change so that it survives a reboot — because nothing in `/proc` does.

## `/sys` is the hardware, arranged as a tree

```
ana@vm:~$ cat /sys/class/net/lo/mtu
65536
```

Same idea, different subject: `/proc` grew up around processes and accumulated everything else,
and `/sys` was built later to expose devices and drivers in a structure that makes sense. Battery
level, screen brightness, network interface settings, which disks exist — all readable, many
writable as root.

You will meet it through other tools long before you go there yourself.

## The devices in `/dev` that are not devices

```
ana@vm:~$ ls -l /dev/null /dev/zero /dev/urandom /dev/tty
crw-rw-rw- 1 root root 1, 3 Sep 14 21:50 /dev/null
crw-rw-rw- 1 root root 5, 0 Sep 14 21:50 /dev/tty
crw-rw-rw- 1 root root 1, 9 Sep 14 21:50 /dev/urandom
crw-rw-rw- 1 root root 1, 5 Sep 14 21:50 /dev/zero
```

`c` in the first column — section 06's field 1 — for *character device*. And where a size would
be, two numbers: the major and minor device numbers, which are how the kernel knows which driver
to hand the request to.

None of these four is hardware. They are behaviours dressed as files.

| | reading gives you | writing to it |
|---|---|---|
| `/dev/null` | nothing, immediately | discards it |
| `/dev/zero` | endless zero bytes | discards it |
| `/dev/urandom` | endless random bytes | stirs the pool |
| `/dev/tty` | whatever you type | shows on your terminal |

```
ana@vm:~$ echo 'goes nowhere' > /dev/null
ana@vm:~$ cat /dev/null
ana@vm:~$ wc -c < /dev/null
0
```

**`/dev/null` is the one you will use constantly.** `2>/dev/null` from section 09 is exactly this:
send the error stream to the thing that throws everything away. It is not a special shell feature.
It is a file, and writing to it happens to do nothing.

```
ana@vm:~$ head -c 8 /dev/zero | od -c
0000000  \0  \0  \0  \0  \0  \0  \0  \0
0000010
ana@vm:~$ head -c 8 /dev/urandom | od -An -tx1
 e1 6d 57 c2 d5 97 26 ca
```

`/dev/zero` fills things: `dd if=/dev/zero of=disk.img bs=1M count=64` is how the 64 MB image in
section 12 was made. `/dev/urandom` is where every password generator and every random filename on
this machine gets its bytes.

**And they are infinite.** `cat /dev/zero > file` does not finish; it stops when the disk is full.
That is worth knowing before you try it.
