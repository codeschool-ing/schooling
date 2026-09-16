---
title: File descriptors, and reading a process through `/proc`
version: 1
---

A process does not hold filenames. It holds **numbers**, and each number is an entry in a table the
kernel keeps for it — a file descriptor. Opening a file gets you the next free number; reading and
writing use the number and never the name again.

Three of them are always there, by convention that everything obeys:

| | | |
|---|---|---|
| `0` | **stdin** | where input comes from |
| `1` | **stdout** | where output goes |
| `2` | **stderr** | where errors go |

That is why `2>&1` is spelled the way it is: it is not punctuation, it is **"make descriptor 2 a
copy of descriptor 1"**.

## Looking at a real one

`tail -f`, started with its output and errors redirected to different files:

```
ana@vm:~/work$ tail -f logs/app.log > /tmp/out.txt 2>/tmp/err.txt &
ana@vm:~/work$ FDPID=$!
ana@vm:~/work$ ls -l /proc/$FDPID/fd
total 0
lr-x------ 1 ana ana 64 Sep 15 07:23 0 -> /dev/null
l-wx------ 1 ana ana 64 Sep 15 07:23 1 -> /tmp/out.txt
l-wx------ 1 ana ana 64 Sep 15 07:23 2 -> /tmp/err.txt
lr-x------ 1 ana ana 64 Sep 15 07:23 3 -> /home/ana/work/logs/app.log
lr-x------ 1 ana ana 64 Sep 15 07:23 4 -> anon_inode:inotify
```

**Everything the redirection did is visible as a number.** `1` is `/tmp/out.txt` and `2` is
`/tmp/err.txt`, because that is what `>` and `2>` are: they set up descriptors before `exec`, in
section 03's gap between `fork` and `exec`. `0` is `/dev/null` because this was a background job.

`3` is the file `tail` actually opened — the first free number after the three it was handed. `4` is
an `inotify` descriptor, which is how `-f` learns the file changed without asking in a loop.

And read the first letter of the mode: `lr-x` for the ones opened for reading, `l-wx` for the ones
opened for writing. **Lesson 4's mode bits, describing a direction rather than a permission.**

## The rest of `/proc/PID`

```
ana@vm:~/work$ cat /proc/$FDPID/cmdline | tr '\0' ' '; echo
tail -f logs/app.log 
ana@vm:~/work$ ls -l /proc/$FDPID/cwd /proc/$FDPID/exe
lrwxrwxrwx 1 ana ana 0 Sep 15 07:23 /proc/1402/cwd -> /home/ana/work
lrwxrwxrwx 1 ana ana 0 Sep 15 07:23 /proc/1402/exe -> /usr/bin/tail
```

| | |
|---|---|
| `cmdline` | the arguments, **null-separated** — hence the `tr` |
| `exe` | a symlink to the program |
| `cwd` | a symlink to its working directory |
| `environ` | its environment, also null-separated |
| `status` | a readable summary: state, threads, memory, uid |
| `fd/` | the table above |

**These are the answer when a process is doing something and you cannot ask it.** `cwd` tells you
where it thinks it is, which explains a relative path that resolves somewhere surprising. `exe`
tells you which binary it really is, which is how you find out that the `python3` running is not the
one on your `PATH`.

`lsof -p PID` prints the same information with names instead of numbers, and a lot more of it:

```
ana@vm:~/work$ lsof -p $FDPID 2>/dev/null | head -8
COMMAND  PID USER   FD      TYPE DEVICE SIZE/OFF    NODE NAME
tail    1402  ana  cwd       DIR  254,0     4096  573441 /home/ana/work
tail    1402  ana  rtd       DIR  254,0     4096       2 /
tail    1402  ana  txt       REG  254,0    64032  151626 /usr/bin/tail
tail    1402  ana  mem       REG  254,0  2125328  152035 /usr/lib/x86_64-linux-gnu/libc.so.6
tail    1402  ana  mem       REG  254,0   360460  151717 /usr/lib/locale/C.utf8/LC_CTYPE
tail    1402  ana  mem       REG  254,0       50  151724 /usr/lib/locale/C.utf8/LC_NUMERIC
tail    1402  ana  mem       REG  254,0     3360  151727 /usr/lib/locale/C.utf8/LC_TIME
```

The `FD` column is where the numbers would be; `cwd`, `rtd` and `txt` are not descriptors but the
working directory, the root directory and the executable, and `mem` rows are mapped libraries.
**`lsof` is the friendlier tool and `/proc` is the one that is always installed.**

## The trick worth the whole section

Delete a file that something still has open, and the space does not come back.

```
ana@vm:~/work$ ls -lh /tmp/big.bin
-rw-r--r-- 1 ana ana 2.0G Sep 15 08:19 /tmp/big.bin
ana@vm:~/work$ df -h /tmp | tail -1
/dev/vda        252G   13G   25G  34% /
ana@vm:~/work$ tail -f /tmp/big.bin > /dev/null &
[1] 3200
ana@vm:~/work$ P=$!
ana@vm:~/work$ rm /tmp/big.bin
ana@vm:~/work$ ls /tmp/big.bin
ls: cannot access '/tmp/big.bin': No such file or directory
ana@vm:~/work$ df -h /tmp | tail -1
/dev/vda        252G   13G   25G  34% /
ana@vm:~/work$ ls -l /proc/$P/fd/3
lr-x------ 1 ana ana 64 Sep 15 08:20 /proc/3200/fd/3 -> '/tmp/big.bin (deleted)'
ana@vm:~/work$ kill $P
ana@vm:~/work$ df -h /tmp | tail -1
/dev/vda        252G   11G   27G  29% /
```

Read the three `df` lines. **13G, then 13G after deleting two gigabytes, then 11G after killing a
process that was not even writing to it.**

Lesson 3 section 10 said `rm` removes a name, not a file. This is the consequence: the directory
entry is gone — `ls` cannot find it — and the data is still there because **a descriptor is also a
reference**. The kernel frees the blocks when the last name and the last open descriptor are both
gone, and not before.

And `/proc` says so out loud: `-> '/tmp/big.bin (deleted)'`.

**This is the single most common "the disk is full and I cannot find what is using it" story.** The
log was rotated, the old file was deleted, the service still has it open, and `du` reports nothing
because `du` walks names. The commands that find it:

```
lsof +L1                  # every open file with no name left
lsof -nP | grep deleted   # the same thing, cruder and more portable
```

And the fix is not `rm` — there is nothing left to remove. **Restart or signal the process that
holds it**, which for a log is usually `kill -HUP`, telling the daemon to reopen its files. That is
section 08's hangup used for what it is actually for on a server.

## Running out of them

A descriptor table has a size, and it is a limit you can hit:

```
ana@vm:~/work$ ulimit -n
20000
ana@vm:~/work$ ulimit -u
64318
```

`ulimit -n` is the maximum number of open files for one process. **Twenty thousand sounds like a
lot and a busy server reaches it**, because every network connection is a descriptor too — the same
table, the same numbers.

`Too many open files` in a log means exactly this, and it is almost always a leak: something opens
and never closes. `ls -l /proc/PID/fd | wc -l` counts them, and the list usually names the culprit
by repeating one thing thousands of times.

`ulimit -a` prints the whole set, and `LimitNOFILE=` in a unit file is where a service's version of
it is configured — lesson 5 again, because a service does not get your shell's limits.
