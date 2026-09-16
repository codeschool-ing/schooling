---
title: Moving and looking: `pwd`, `cd`, `ls`
version: 1
---

Three commands, and you will type them more than everything else in this course put together.
`pwd` says where you are, `cd` moves, `ls` looks. This section is about the handful of options
worth having in your fingers rather than in a manual.

## `cd`, and the four things it takes

```
cd /var/log        # absolute: there, from the root
cd logs            # relative: down into logs, from here
cd ..              # up one
cd                 # home — with no argument at all
cd -               # back to where you just were
```

**`cd` with nothing goes home.** That is worth knowing on day one, because it is the reliable way
out of anywhere you got lost.

### The three ways it refuses

```
ana@vm:~$ cd /nosuchplace
bash: cd: /nosuchplace: No such file or directory
ana@vm:~$ cd work/README.md
bash: cd: work/README.md: Not a directory
ana@vm:~$ cd /root
bash: cd: /root: Permission denied
```

Three different failures, three different words, and the word is the diagnosis:

| message | what is actually wrong |
|---|---|
| `No such file or directory` | the path is wrong — a typo, or you are not where you thought |
| `Not a directory` | the path is right and it names a **file** |
| `Permission denied` | the path is right and you are not allowed in (lesson 4) |

Note who is speaking: `bash:`, not `cd:`. **`cd` is not a program** — it cannot be, because a
program changing its own directory would not change the shell's. It is built into the shell, which
is why `man cd` finds nothing and `help cd` finds everything. Lesson 1 section 16 drew that line.

## `ls`, and the seven options that matter

Plain `ls` gives you names, in columns, alphabetically, hiding anything that starts with a dot:

```
ana@vm:~/work$ ls
Makefile  README.md  build  data  logs  notes  src
```

Everything else is one of these:

| option | does | when |
|---|---|---|
| `-l` | one line each, with the details | **the default you actually want** |
| `-a` | include hidden names, and `.` and `..` | looking for a dotfile |
| `-A` | include hidden names, but not `.` and `..` | the same, less noise |
| `-h` | sizes as `4.0K`, `196K`, `1.2G` | always, with `-l` |
| `-t` | newest first | "what changed here?" |
| `-r` | reverse the order | with `-t`, so the newest is last |
| `-S` | biggest first | "what is filling this up?" |
| `-d` | the directory itself, not what is in it | `ls -ld somedir` |
| `-R` | descend into every subdirectory | a small tree, or a long wait |
| `-1` | one name per line, no columns | feeding another command |

They combine, and the order between them does not matter:

```
ana@vm:~/work$ ls -lh
total 28K
-rw-r--r-- 1 ana ana   66 Mar 22  2025 Makefile
-rw-r--r-- 1 ana ana  118 Mar 22  2025 README.md
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 build
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 data
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 logs
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 notes
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 src
```

The next section reads that listing field by field. Three combinations are worth learning as
words, because you will use them for the rest of your career:

**`ls -la`** — everything, with details. The one you type by reflex.

**`ls -ltr`** — newest at the bottom, right above your prompt:

```
ana@vm:~/work$ ls -ltr
total 28
-rw-r--r-- 1 ana ana  118 Mar 22  2025 README.md
-rw-r--r-- 1 ana ana   66 Mar 22  2025 Makefile
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 src
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 notes
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 logs
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 data
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 build
```

In a directory with two hundred log files, that is the only listing that is useful, because the
one you want is the last line printed rather than somewhere in the scrollback.

**`ls -lSh`** — biggest first, readable sizes. The first move when a disk is full.

## `-a` and `-A`, and the dot that hides

```
ana@vm:~/hid$ ls
visible.txt
ana@vm:~/hid$ ls -a
.  ..  .cache  .config  .hidden.txt  visible.txt
ana@vm:~/hid$ ls -A
.cache  .config  .hidden.txt  visible.txt
```

One directory, three answers. **A name beginning with a dot is hidden**, which is the entire
mechanism — there is no hidden attribute anywhere, just a convention that `ls` honours. Lesson 1
section 11 covered the convention; section 14 covers what people keep in those files.

`-A` is `-a` without `.` and `..`, and it is usually what you meant.

## `-d`, and the question people ask wrong

```
ana@vm:~/work$ ls -ld logs
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 logs
ana@vm:~/work$ ls -l logs
total 12
-rw-r--r-- 1 ana ana 440 Mar 26  2025 app.log
-rw-r--r-- 1 ana ana   8 Mar 19  2025 app.log.1
-rw-r--r-- 1 ana ana   0 Mar 26  2025 empty.log
-rw-r--r-- 1 ana ana  31 Mar 26  2025 error.log
```

Given a directory, `ls` lists **what is inside it**. `-d` says *no, the thing itself* — which is
what you want when the question is about the directory's own permissions, owner or date.

You will need this in lesson 4 constantly, and it is the option beginners never find because the
manual calls it "list directories themselves, not their contents" and nobody reads that line
until they already know what it means.

## One surprise worth meeting now

```
ana@vm:~/work$ ls -l /bin
lrwxrwxrwx 1 root root 7 Apr 22  2024 /bin -> usr/bin
ana@vm:~/work$ ls -ld /bin/
drwxr-xr-x 2 root root 36864 Mar 31 13:31 /bin/
```

`/bin` is a symlink to `usr/bin`. With `-l`, `ls` shows you **the link**. Add a trailing slash and
it follows it and shows you **the directory**. Same seven characters typed, two different
questions asked.

Section 11 is about links. The habit to take from here is smaller and immediately useful: **a
trailing slash means "through it, into the thing"** — and when a listing surprises you, check
whether you are looking at a link.
