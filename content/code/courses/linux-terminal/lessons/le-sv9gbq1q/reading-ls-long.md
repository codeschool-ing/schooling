---
title: Reading a long listing, field by field
version: 1
---

This is the densest line in the course, and you will look at it for the rest of your career.

```
ana@vm:~/work$ ls -l logs
total 12
-rw-r--r-- 1 ana ana 440 Mar 26  2025 app.log
-rw-r--r-- 1 ana ana   8 Mar 19  2025 app.log.1
-rw-r--r-- 1 ana ana   0 Mar 26  2025 empty.log
-rw-r--r-- 1 ana ana  31 Mar 26  2025 error.log
```

Take one line and pull it apart.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A single line of ls -l output, broken into eight labelled fields: a type character, nine permission characters, the link count, the owner, the group, the size in bytes, the modification time and the name.\"><rect x=\"20\" y=\"18\" width=\"680\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--amber)\">-</text><text x=\"148.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">rw-r--r--</text><text x=\"226.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">1</text><text x=\"272.4\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">ana</text><text x=\"328.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper-dim)\">ana</text><text x=\"385.2\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">440</text><text x=\"490.2\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper-dim)\">Mar 26  2025</text><text x=\"616.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">app.log</text><path d=\"M70.8 72 L70.8 94\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70.8\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">type</text><path d=\"M148.8 72 L148.8 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"148.8\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">permissions</text><path d=\"M226.8 72 L226.8 94\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"226.8\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">links</text><path d=\"M272.4 72 L272.4 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"272.4\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">owner</text><path d=\"M328.8 72 L328.8 94\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"328.8\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">group</text><path d=\"M385.2 72 L385.2 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"385.2\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">size</text><path d=\"M490.2 72 L490.2 94\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"490.2\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">modified</text><path d=\"M616.8 72 L616.8 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"616.8\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">name</text><text x=\"360.0\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">eight fields, always in this order, for every entry</text></svg>", "caption": "One line of `ls -l`, taken apart. The first character is the kind of thing; the nine after it are the permissions lesson 4 is about."}
```

## The eight fields

| # | field | what it says |
|---|---|---|
| 1 | `-` | **what kind of thing this is** — one character |
| 2 | `rw-r--r--` | **permissions** — nine characters, three audiences of three |
| 3 | `1` | **link count** — how many names point at this data |
| 4 | `ana` | **owner** |
| 5 | `ana` | **group** |
| 6 | `440` | **size in bytes** |
| 7 | `Mar 26  2025` | **when the contents last changed** |
| 8 | `app.log` | **name** |

## Field 1: the character everybody skips

It is not a dash for decoration. It is the type:

| | what it is | where you meet it |
|---|---|---|
| `-` | an ordinary file | everywhere |
| `d` | a directory | everywhere |
| `l` | a symbolic link | `/bin`, `/lib`, and section 11 |
| `c` | a character device | `/dev/null`, `/dev/tty` |
| `b` | a block device | `/dev/vda` — a disk |
| `s` | a socket | `/run`, where services listen |
| `p` | a named pipe | rarely, and you will know |

So the fastest way to count the directories in a listing is to read the first column downward:

```
ana@vm:~/work$ ls -l
total 28
-rw-r--r-- 1 ana ana   66 Mar 22  2025 Makefile
-rw-r--r-- 1 ana ana  118 Mar 22  2025 README.md
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 build
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 data
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 logs
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 notes
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 src
```

Two files, five directories, and you did not have to open anything to know it.

## Field 2: nine characters, in three groups of three

`rw-r--r--` is `rw-`, `r--`, `r--`: **what the owner may do, what the group may do, what everybody
else may do.** `r` read, `w` write, `x` execute, `-` not allowed.

That is the whole of lesson 4 and it deserves the whole of lesson 4 — the arithmetic, the
directory rules, the bits that are not in those nine characters. What you need here is only to
stop seeing it as noise. `-rw-r--r--` means *a file the owner can change and everybody can read*,
which is what a normal file looks like. `drwxr-xr-x` means *a directory everybody can enter and
list, and only the owner can add to*, which is what a normal directory looks like.

## Field 3: the link count, and why directories start at 2

For a file it is almost always `1`, and section 11 is about the day it is not.

For a directory it is **never** 1, and the reason is `.` and `..` from section 04. An empty
directory has two names pointing at it: its own name in its parent, and the `.` inside itself. Add
a subdirectory and that subdirectory's `..` points at it too, so the count becomes 3.

```
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 logs
```

`2` means `logs` contains no subdirectories. That is a real, free piece of information sitting in
a column nobody reads.

## Fields 4 and 5: owner and group

Two names, and they answer *which* of the three groups of permission characters applies to you.
If you are `ana`, the first three. If you are in the group `ana` but are not her, the middle
three. If neither, the last three — and that is the case more often than people expect.

**Only one of the three groups ever applies**, and it is the first one that matches. Lesson 4
spends a section on that, because the intuition — "I am in the group, so I also get the group's
rights on top of mine" — is wrong and costs an afternoon.

## Field 6: the size, and what it means for a directory

For a file, the size is bytes. `-h` makes it readable:

```
ana@vm:~/work$ ls -lh
-rw-r--r-- 1 ana ana   66 Mar 22  2025 Makefile
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 build
```

For a **directory**, the number is not the size of what is inside. `4096` is the size of the
directory's own list of names — and a directory containing four hundred gigabytes of video will
still say `4096`. That is section 13's whole subject; the thing to fix now is the expectation.

## Field 7: the date that changes shape

One listing, two date formats:

```
ana@vm:~/work$ ls -la
total 40
drwxr-xr-x  7 ana ana 4096 Mar 26  2025 .
drwxr-x--- 10 ana ana 4096 Sep 14 21:58 ..
-rw-r--r--  1 ana ana   46 Mar 22  2025 .env
-rw-r--r--  1 ana ana   66 Mar 22  2025 Makefile
-rw-r--r--  1 ana ana  118 Mar 22  2025 README.md
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 build
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 data
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 logs
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 notes
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 src
```

Every line says `Mar 2025` except `..`, which says `Sep 14 21:58`. **`ls` prints the time for anything
changed within roughly the last six months, and the year for anything older.** It is trying to be
useful — recent files are the ones where the hour matters — and it catches people out when they
sort a listing and see two different formats.

`ls -l --full-time` prints the whole thing, unambiguous, every time. Worth knowing when you are
comparing two machines' clocks.

And note *which* time it is: **the last time the contents changed.** Not when the file was made.
Section 08 gets the other two timestamps out of `stat`.

## And the `total` line

```
total 12
```

That is not a file count and not the sum of the sizes. It is **the number of 1-KiB blocks the
disk gave to these entries** — the space actually occupied, which is why four files of 440, 8, 0
and 31 bytes add up to 12. Section 13 explains why those numbers do not match; for now, `total` is
about disk, and the size column is about content.
