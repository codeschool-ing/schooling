---
title: Looking inside without opening anything
version: 1
---

Seven commands, and between them they answer every question you have about a file short of
editing it.

| | answers |
|---|---|
| `file` | *what kind of thing is this?* |
| `cat` | *show me all of it* |
| `less` | *let me page through it* |
| `head` | *the first few lines* |
| `tail` | *the last few lines — and the new ones as they arrive* |
| `wc` | *how much of it is there?* |
| `stat` | *everything the filesystem knows* |

## `file` first, always

```
ana@vm:~/work$ file README.md
README.md: ASCII text
ana@vm:~/work$ file src/main.c
src/main.c: C source, ASCII text
ana@vm:~/work$ file data/cache.bin
data/cache.bin: data
ana@vm:~/work$ file src
src: directory
ana@vm:~/work$ file logs/empty.log
logs/empty.log: empty
```

**`file` does not look at the extension.** It reads the first bytes and compares them against a
database of known signatures — which is why it can tell a C file from a plain one, and why a
`.txt` containing a JPEG is reported as a JPEG. On Linux the extension is a hint for humans;
nothing in the system is required to honour it.

```
ana@vm:~/work$ file /bin/ls
/bin/ls: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=05dad2c279f7651722809fa75adba6bf9ab1c209, for GNU/Linux 3.2.0, stripped
```

That is a program, and `file` just told you the architecture it was built for, that it needs
shared libraries, and that its debug symbols were removed.

**Make this the first command you run on an unfamiliar file**, because the one below it is `cat`,
and `cat` on the wrong thing is unpleasant.

## `cat` prints, and that is all it does

```
ana@vm:~/work$ cat data/report.csv
date,amount
2025-01-03,1200
2025-01-09,-340
2025-02-11,880
```

It does not page, wrap sensibly, or stop. Four lines is fine; forty thousand scroll past and you
are left at the end.

Two options are worth having:

```
ana@vm:~/work$ cat -n data/report.csv
     1  date,amount
     2  2025-01-03,1200
     3  2025-01-09,-340
     4  2025-02-11,880
```

`-n` numbers the lines. `-A` shows the invisible ones — tabs, trailing spaces, and the carriage
returns that lesson 1 section 12 was about.

And the name: `cat` is short for *concatenate*, because that is what it was for.

```
ana@vm:~/work$ cat README.md data/report.csv
# ledger

A small tool that reads a CSV and totals a column.

Build with `make`. Run with `./ledger data/report.csv`.
date,amount
2025-01-03,1200
2025-01-09,-340
2025-02-11,880
```

Two files, one stream. Printing a single file is the degenerate case everybody uses it for.

**`cat` on a binary will fill your terminal with garbage** and may leave it unable to draw text
properly, because some of those bytes are escape sequences the terminal obeys. If it happens,
type `reset` and press enter — blind if necessary — and the terminal comes back.

## `less` is how you read something long

```
less /var/log/syslog
```

`less` pages, searches, and does not load the whole file to start — it will open a four-gigabyte
log instantly. The keys worth knowing are few:

| key | does |
|---|---|
| `Space`, `b` | forward, back — one screen |
| `↑` `↓` | one line |
| `g`, `G` | the very start, the very end |
| `/word` | search forward; `n` for the next hit, `N` for the previous |
| `-S` | (on the command line) stop wrapping long lines |
| `F` | follow the file as it grows, like `tail -f` |
| `q` | quit |

**`q` is the one to learn first**, because being stuck inside a pager you did not mean to open is
a genuinely common first-week experience.

There is an older one called `more`, which is `less` with fewer features — the joke in the name is
deliberate, and `less` is what everybody uses.

## `head` and `tail`

```
ana@vm:~/work$ head -2 logs/app.log
app started
app ready
ana@vm:~/work$ tail -3 logs/app.log
app started
app ready
app handled a request
```

Ten lines by default, `-n` for a different count. Two less obvious forms:

```
ana@vm:~/work$ tail -n +29 logs/app.log
app ready
app handled a request
```

`+29` means *from line 29 onward* rather than *the last 29*. Useful for skipping a header.

```
ana@vm:~/work$ head -c 40 data/cache.bin
```

`-c` counts bytes rather than lines. Forty bytes of a binary file come out as forty bytes of
nonsense — but only forty, which is the point: it is the bounded way to peek at something you are
not sure about.

### `tail -f` is the one you will use most

```
tail -f /var/log/nginx/error.log
```

It prints the end of the file and then **stays**, printing each new line as it is written. That is
how you watch a service while you provoke it: `tail -f` in one terminal, the failing request in
another. `Ctrl+C` to stop.

`tail -F` — capital — keeps following even if the file is deleted and recreated, which is exactly
what happens when the logs rotate at midnight. Lesson 5 comes back to this with `journalctl -f`.

## `wc` counts

```
ana@vm:~/work$ wc logs/app.log
 30  80 440 logs/app.log
```

Three numbers, always in this order: **lines, words, bytes**. Ask for one of them and it prints
only that:

```
ana@vm:~/work$ wc -l logs/app.log
30 logs/app.log
ana@vm:~/work$ wc -c README.md
118 README.md
```

Give it several files and it adds a total:

```
ana@vm:~/work$ wc -l logs/*.log
 30 logs/app.log
  0 logs/empty.log
  1 logs/error.log
 31 total
```

`wc -l` is the most-used counting tool on Linux, because it sits at the end of a pipe: *how many
files matched, how many lines had that word, how many processes are running.* Lesson 8 is where it
becomes a reflex.

## `stat` is the whole record

```
ana@vm:~/work$ stat README.md
  File: README.md
  Size: 118             Blocks: 8          IO Block: 4096   regular file
Device: 254,0   Inode: 573447      Links: 1
Access: (0644/-rw-r--r--)  Uid: ( 1001/     ana)   Gid: ( 1002/     ana)
Access: 2026-09-14 22:02:12.911149501 +0000
Modify: 2025-03-22 14:30:00.000000000 +0000
Change: 2026-09-14 21:58:33.143136437 +0000
 Birth: 2026-09-14 21:58:33.115136436 +0000
```

Everything `ls -l` shows and several things it does not. Two of them matter:

**The inode number** — `573447` — is the filesystem's own name for this data, and section 46 is
built on it.

**Three timestamps, not one:**

| | changes when |
|---|---|
| **Access** (atime) | the contents are read |
| **Modify** (mtime) | the contents are changed — *this is what `ls -l` shows* |
| **Change** (ctime) | the contents **or the metadata** change — a rename, a `chmod`, a new owner |

The distinction earns its keep the day somebody swears they did not touch a file. `mtime` says the
contents are from March. `ctime` says something about the file changed today — so its permissions
or its name did, and that is a different conversation.

**`Birth` is the creation time**, and it is the newest of the four: older filesystems did not
record it at all, and plenty of tools still ignore it. Do not build anything on it without
checking it is there.

`stat -c` prints just the field you asked for, which is what you want inside a script:

```
ana@vm:~/work$ stat -c '%s %n' README.md
118 README.md
```
