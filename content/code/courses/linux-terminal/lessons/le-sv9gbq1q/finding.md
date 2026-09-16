---
title: Finding things: `find`
version: 1
---

`find` has a reputation for being ugly, and it is earned by one thing: its syntax is older than
almost every other command you will use and it does not follow the rules from lesson 1 section 07.
The options are single-dashed *words* — `-name`, not `--name` — and their order changes what
happens.

Learn the shape once and it stops being strange:

```
find   WHERE   WHAT-TO-MATCH   WHAT-TO-DO
```

**Where** is a directory to start from. **What to match** is one or more tests. **What to do** is
optional and defaults to *print it*.

```
ana@vm:~/work$ find . -name '*.c'
./src/util.c
./src/main.c
```

Start at `.`, match names ending in `.c`, print them. And it descended into `src` without being
asked — **`find` is recursive by default**, which is the difference between it and `ls`.

## The tests worth knowing

| test | matches |
|---|---|
| `-name '*.log'` | by name, case-sensitive |
| `-iname 'readme*'` | by name, ignoring case |
| `-type f` / `-type d` / `-type l` | files / directories / symlinks |
| `-size +100k` | bigger than 100 KiB — also `M`, `G`, and `-` for smaller |
| `-mtime -1` | changed in the last day |
| `-mmin -5` | changed in the last five minutes |
| `-newer somefile` | changed more recently than that file |
| `-empty` | zero bytes, or an empty directory |
| `-user ana` | owned by somebody |
| `-perm 644` | with exactly those permissions (lesson 4) |
| `-maxdepth 1` | do not descend |

A few of them, run:

```
ana@vm:~/work$ find . -iname 'readme*'
./README.md
ana@vm:~/work$ find . -type d
.
./src
./notes
./logs
./data
./build
ana@vm:~/work$ find . -size +100k
./build/util.o
./build/ledger.o
ana@vm:~/work$ find . -empty
./logs/empty.log
```

**Quote the pattern.** `find . -name '*.c'` works; `find . -name *.c` may not, and the reason is
section 10 — the shell expands the star before `find` ever runs. Quoting hands the star to `find`
intact, and `find` does its own matching.

### The time tests, where the numbers mislead

```
ana@vm:~/work$ find . -mtime -1
./logs
./logs/today.log
ana@vm:~/work$ find . -mtime +180 -name '*.md'
./notes/2025-01-plan.md
./notes/2025-02-plan.md
./README.md
```

`-mtime` counts **days**, and the sign is the whole meaning:

| | means |
|---|---|
| `-mtime -1` | less than 1 day ago — *recent* |
| `-mtime +180` | more than 180 days ago — *old* |
| `-mtime 7` | in the 24-hour window that started 7 days ago — rarely what anybody wants |

`-mmin` is the same in minutes, and it is the one to reach for when you are debugging something
that happened while you were watching. If you want a real date rather than a count, `-newermt`
takes one:

```
ana@vm:~/work$ find logs -type f -newermt '2025-03-20'
logs/empty.log
logs/error.log
logs/app.log
```

## Combining tests

Two tests side by side mean **and**. For **or**, say so:

```
ana@vm:~/work$ find . -name '*.c' -o -name '*.h'
./src/util.h
./src/util.c
./src/main.c
```

`-o` is or, `!` is not, and parentheses group — escaped, because the shell wants them otherwise:
`find . \( -name '*.c' -o -name '*.h' \) -type f`.

`-type f -name '*.log'` reads as *a file, and named like that*, and that ordinary and-by-adjacency
is how nearly every real `find` is built.

## Doing something with what you found

`-exec` runs a command on each result. `{}` stands in for the file, and the whole thing ends with
`\;` or `+`:

```
ana@vm:~/work$ find . -size +100k -exec ls -lh {} +
-rw-r--r-- 1 ana ana 196K Mar 26  2025 ./build/ledger.o
-rw-r--r-- 1 ana ana 196K Mar 26  2025 ./build/util.o
```

| ending | does |
|---|---|
| `\;` | run the command **once per file** |
| `+` | run it **once**, with all the files as arguments |

`+` is faster and usually what you want. `\;` is what you need when the command takes exactly one
file, like `mv {} /somewhere/`.

The backslash is there because `;` would otherwise end the command as far as the shell is
concerned — the same "who reads this first" question as the quoted star.

**There is also `-delete`**, and it deserves a warning:

```
find . -name '*.tmp' -delete
```

It works, it is fast, it says nothing, and it will happily delete a thousand files because a
pattern was wider than you thought. **Run it as a plain `find` first.** The same command without
`-delete` prints exactly the list that `-delete` would remove, which makes checking free.

## Reading past the noise

```
ana@vm:~/work$ find /etc -name 'hosts'
find: ‘/etc/redis’: Permission denied
find: ‘/etc/credstore.encrypted’: Permission denied
find: ‘/etc/polkit-1/rules.d’: Permission denied
/etc/hosts
find: ‘/etc/credstore’: Permission denied
find: ‘/etc/ssl/private’: Permission denied
```

The answer is in there — `/etc/hosts`, on the fourth line — surrounded by directories you are not
allowed to look in. Notice the **interleaving**: the complaints are going to standard error and
the results to standard output, and the terminal is showing you both streams mixed together in
real time.

```
ana@vm:~/work$ find /etc -name 'hosts' 2>/dev/null
/etc/hosts
```

`2>/dev/null` throws the error stream away. Lesson 8 explains what the `2` is; for now it is the
idiom that makes `find` usable outside your own home directory, and you will type it constantly.

## `locate`, and why it is not installed

There is a second way to search, and it works completely differently:

```
ana@vm:~$ locate report.csv
bash: locate: command not found
```

`locate` does not search the disk. It searches a **database** that a nightly job builds by walking
the whole filesystem once. That makes it nearly instant on a machine with millions of files, and
it makes it wrong about anything created since the database was last built.

On Ubuntu it is not installed by default — `apt install plocate`, and then `sudo updatedb` to
build the index the first time.

| | `find` | `locate` |
|---|---|---|
| looks at | the real filesystem, now | an index, from last night |
| speed | proportional to the tree | instant |
| finds a file made a minute ago | yes | no |
| can test size, time, owner, type | yes | no |

Use `locate` when you half-remember a filename somewhere on a big machine. Use `find` for
everything else — and for anything where being wrong matters.
