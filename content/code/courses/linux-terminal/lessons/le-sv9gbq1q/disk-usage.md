---
title: What is taking the space
version: 1
---

Two commands, and they answer two different questions that people expect to agree.

| | asks | answers by |
|---|---|---|
| `df` | *how full is this **filesystem**?* | asking the filesystem |
| `du` | *how much space do these **files** use?* | adding up the files it can see |

They disagree more often than you would think, and every one of the disagreements is worth
understanding, because each is a real failure mode.

## `df`: how full is it

```
ana@vm:~/work$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
```

`-h` for human-readable, always. Give it a path and it answers about the filesystem that path is
on — so `df -h .` is the fastest way to ask "am I about to run out of room *here*".

**Size, Used and Avail do not add up, and that is normal.** 11 used plus 27 available is not 252.
On an ordinary ext4 installation the gap is small and has one main cause: **5% of the filesystem
is reserved for root**, so that a disk which is full for everybody else still leaves the
administrator enough room to log in and fix it. That is also why `Use%` is computed against what
*you* can use rather than against `Size`.

The gap on this machine is much larger than 5%, because it is a virtual machine whose disk carries
a reservation set outside the filesystem. Worth knowing as a shape: on cloud and container hosts,
`Size` is frequently the size of something bigger than what you are allowed to fill.

### The second way a disk fills up

```
ana@vm:~/work$ df -i /
Filesystem       Inodes  IUsed    IFree IUse% Mounted on
/dev/vda       16777216 210406 16566810    2% /
```

`-i` counts **inodes** rather than bytes. Section 46 introduced them: one per file, and a
filesystem is created with a fixed number of them.

So a filesystem can be 4% full and still refuse to create a file, because it has run out of
inodes — millions of tiny session files, or a cache nobody ever pruned. The symptom is
`No space left on device` with a `df -h` that looks fine, and the answer is `df -i`.

**Check both.** It is the first thing to do when a disk is "full" and does not look it.

## `du`: what is using it

```
ana@vm:~/work$ du -sh
472K    .
```

`-s` for a summary rather than a line per directory, `-h` for readable. The idiom you will
actually type is this one:

```
ana@vm:~/work$ du -sh * | sort -h
4.0K    Makefile
4.0K    README.md
12K     data
16K     logs
16K     notes
16K     src
396K    build
```

**`du -sh * | sort -h`, and then `cd` into the biggest one and do it again.** That is how a full
disk is diagnosed, and it takes about four rounds to walk from `/` to the directory actually
responsible. `sort -h` understands `K`, `M` and `G`, which plain `sort` does not.

`--max-depth` is the same walk without the `cd`:

```
ana@vm:~/work$ du -h --max-depth=1 | sort -h
12K     ./data
16K     ./logs
16K     ./notes
16K     ./src
396K    ./build
472K    .
```

**Run `du` on `/` and you will wait**, because it walks every file on the machine. On a large
server start at `/var` — which is where things grow — and put `2>/dev/null` after it, for the
same reason `find` needed it in section 44.

## Why the numbers are never quite the sizes

```
ana@vm:~/work$ ls -l logs/app.log
-rw-r--r-- 1 ana ana 440 Mar 26  2025 logs/app.log
ana@vm:~/work$ du -sh logs/app.log
4.0K    logs/app.log
```

440 bytes, and four kilobytes of disk. **A filesystem allocates space in blocks**, 4 KiB here, and
a file gets whole blocks whether it fills them or not. A 1-byte file costs 4 KiB, and a directory
of ten thousand tiny files costs forty megabytes to hold a few hundred kilobytes of content.

That is the difference between *size* and *space*, and `du` will show you either:

```
ana@vm:~/work$ du --apparent-size -sh logs/app.log
440     logs/app.log
```

`du` counts disk. `ls -l` and `du --apparent-size` count content. **`du` is right about the
disk being full**, which is why it is the default.

The same applies to a directory: `ls -ld data` says `4096` — the size of its list of names —
while `du -sh data` says `12K`, which is that list plus everything it names.

## The one that wastes an afternoon: deleted, and still there

```
root@vm:/root# dd if=/dev/zero of=/mnt/backups/big.bin bs=1M count=30 status=none
root@vm:/root# tail -f /mnt/backups/big.bin > /dev/null &
root@vm:/root# rm /mnt/backups/big.bin
root@vm:/root# du -sh /mnt/backups
24K     /mnt/backups
root@vm:/root# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   31M   22M  59% /mnt/backups
```

A 30 MB file was created, a program was left reading it, and it was deleted. Now **`du` says
24 KB and `df` says 31 MB are in use**, on the same filesystem, at the same moment. Both are
telling the truth.

Section 46 explained why. `rm` removes a *name*. The data stays until the last reference goes —
and an open file handle is a reference, exactly like a name is. `du` walks names, so it cannot see
this file. The filesystem counts blocks, so it can.

`lsof` finds it:

```
root@vm:/root# lsof /mnt/backups 2>/dev/null
COMMAND  PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
tail    1929 root    3r   REG    7,0 31457280   14 /mnt/backups/big.bin (deleted)
```

There it is, with `(deleted)` after the name and its full 31457280 bytes still counted. Stop the
process and the space comes back by itself:

```
root@vm:/root# kill %1
root@vm:/root# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   28K   52M   1% /mnt/backups
```

**This is the single most common "I deleted the logs and nothing happened".** A service was
holding its log file open, somebody deleted the file instead of truncating it, and the disk stayed
full until the service was restarted. The right fix is to empty the file rather than remove it:

```
: > /var/log/huge.log
```

That truncates it to zero while the program keeps writing to the same open file. Lesson 5's
`logrotate` is the version of this that runs by itself.

## The other three disagreements, named

**A mount underneath.** `du /mnt` counts what is inside anything mounted under it; `df /mnt`
answers only about `/mnt`'s own filesystem. `du -x` stays on one filesystem, which is usually what
you meant.

**Files you cannot see.** `du` as an ordinary user silently skips directories it may not read, so
its total is low. A `du` that matters is a `du` run with `sudo`.

**Hard links.** `du` counts an inode once, no matter how many names reach it. That is the right
answer, and it means `du` on two directories separately can add up to more than `du` on both at
once.
