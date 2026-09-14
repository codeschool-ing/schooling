---
title: Everything is a file
version: 1
---

It is the sentence people quote about Unix, usually without saying what it buys. It is not poetry
and it is not quite literal. **It means that most of what a program needs to talk to is reached
through the same interface as a file: open it, read from it, write to it, close it.**

The payoff is that tools you learn for files work on things that are not files.

## A disk is a file. So is your terminal.

```
ana@vm:~$ ls -l /dev/null /dev/zero /dev/urandom
crw-rw-rw- 1 root root 1, 3 Sep  3 04:53 /dev/null
crw-rw-rw- 1 root root 1, 9 Sep  3 04:53 /dev/urandom
crw-rw-rw- 1 root root 1, 5 Sep  3 04:53 /dev/zero
```

Three entries in `/dev`, listed by the same `ls` you used on your own directory. Two things in
that output are new.

**The first character is `c`, not `-`.** Section 39 of lesson 3 decodes that column in full; here
it is enough that `-` means an ordinary file and `c` means a **character device** — something the
kernel hands you a stream from rather than bytes off a disk.

**Where a size would be, there are two numbers.** `1, 3` is the major and minor number: which
driver, and which device that driver is being asked for. A device entry holds no bytes of its own,
so the column that would report its size reports what it points at instead.

The three you will actually meet:

| | what it does |
|---|---|
| `/dev/null` | swallows everything written to it and returns nothing when read. The bin |
| `/dev/zero` | an endless supply of zero bytes |
| `/dev/urandom` | an endless supply of random bytes |

`/dev/null` is the one you will use, and lesson 8 uses it constantly: `2> /dev/null` means *throw
the errors away*.

## `/proc` is the kernel answering questions in text

`/proc` is not on any disk. It is invented as you look at it — the kernel turning its own state
into text, on demand, because text is the interface everything else already speaks:

```
ana@vm:~$ head -3 /proc/meminfo
MemTotal:       16461028 kB
MemFree:        15633272 kB
MemAvailable:   15854168 kB
```

```
ana@vm:~$ cat /proc/uptime
342.25 1242.58
```

No tool had to be written to read that. `head` and `cat` work because the kernel chose to answer
in the same shape a file answers in. Lesson 11 reads `/proc` seriously, and every monitoring tool
you will ever run is doing what you just did.

There is a directory in there per running process, and `self` is whichever process is asking:

```
ana@vm:~$ ls /proc/self/fd
0
1
2
3
```

Those are the open files of the command you just ran — numbered, because that is how a program
refers to them. `0`, `1` and `2` are standard input, output and error, which is the whole of
lesson 8's redirection sitting there as three entries in a directory. Section 93 of lesson 6 comes
back to it.

## What this actually buys you

Three things, and they are the reason the idea survived fifty years:

**One set of tools, not one per kind of thing.** `cat`, `grep`, `wc`, `>` and `|` work on a text
file, a device, a kernel table and the output of another program. Nothing had to be extended to
make that true.

**Permissions are one system.** The nine bits of lesson 4 govern a document and a sound card the
same way, because the sound card is reached through something that has an owner and a mode. There
is no second permission system for devices.

**Composition.** `head -3 /proc/meminfo` is two programs that know nothing about each other and
nothing about memory. That is lesson 8's entire subject, and it works because of this section.

## Where it stops being true

Being precise about the limits is what keeps the idea useful rather than magical:

- **Network sockets are not in the filesystem.** You cannot `cat` a TCP connection. Unix domain
  sockets do appear as files; internet ones do not.
- **`/proc` and `/sys` are not files on a disk.** Nothing is stored. Copying `/proc` somewhere
  achieves nothing, and their sizes read as zero.
- **Some devices refuse most operations.** An entry in `/dev` being openable does not mean every
  program can do something sensible with it.

The honest form of the sentence is *almost everything is reached like a file*, and the value is in
"reached like", not in "is".
