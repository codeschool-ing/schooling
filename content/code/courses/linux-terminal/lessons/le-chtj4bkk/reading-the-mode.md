---
title: Reading a mode, character by character
version: 1
---

Ten characters, and they are the first thing on every line of a long listing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The mode string -rwxr-xr-- split into four parts: a leading type character, then three groups of three characters labelled the owner, the group and everybody else, with the octal digits 7, 5 and 4 under them.\"><rect x=\"182\" y=\"16\" width=\"356\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"207.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--amber)\">-</text><text x=\"241.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--phosphor)\">r</text><text x=\"275.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--phosphor)\">w</text><text x=\"309.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--phosphor)\">x</text><text x=\"343.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper)\">r</text><text x=\"377.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper)\">-</text><text x=\"411.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper)\">x</text><text x=\"445.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper-dim)\">r</text><text x=\"479.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper-dim)\">-</text><text x=\"513.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper-dim)\">-</text><path d=\"M207.0 82 L207.0 100\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"207.0\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">type</text><path d=\"M227.0 88 L227.0 82 L323.0 82 L323.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"275.0\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the owner</text><text x=\"275.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"17\" fill=\"var(--phosphor)\">7</text><path d=\"M329.0 88 L329.0 82 L425.0 82 L425.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"377.0\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the group</text><text x=\"377.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"17\" fill=\"var(--phosphor)\">5</text><path d=\"M431.0 88 L431.0 82 L527.0 82 L527.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"479.0\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">everybody else</text><text x=\"479.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"17\" fill=\"var(--phosphor)\">4</text><text x=\"360\" y=\"172\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">read 4, write 2, execute 1 — added up within each group of three</text></svg>", "caption": "Ten characters: one for the kind of thing, then three audiences of three. Only one of the three rows applies to you, and it is the first one that matches."}
```

## Character 1: the type, which is not a permission

Lesson 3 section 06 covered it and it is worth repeating, because people count nine characters and
find ten:

| | |
|---|---|
| `-` | an ordinary file |
| `d` | a directory |
| `l` | a symbolic link |
| `c`, `b` | a device |
| `s`, `p` | a socket, a named pipe |

A symlink is always `lrwxrwxrwx`, and that is not a security problem: **the permissions that
matter are the target's.** A symlink's own bits are never consulted.

## Characters 2 to 10: three rows of three

Each row is read in the same fixed order, `r` then `w` then `x`, and a `-` means the bit is off.
**Position is meaning.** `r-x` and `-wx` differ by which slots are filled, not by which letters
appear.

Four modes you will see constantly, and what each is for:

| mode | octal | what it is |
|---|---|---|
| `-rw-r--r--` | 644 | an ordinary file: the owner edits, everybody reads |
| `-rw-------` | 600 | a private file: a key, a password, a token |
| `-rwxr-xr-x` | 755 | a program or a script: everybody runs it, the owner changes it |
| `drwxr-xr-x` | 755 | an ordinary directory |

Learn those four as shapes. Most of what you meet is one of them, and a file that is not one of
them is worth a second look.

## Reading them out loud, from the real thing

```
bruno@vm:/srv/perm$ ls -l
total 16
-rw------- 1 ana ana   9 Sep 14 22:45 private.txt
-rw-r--r-- 1 ana ana  22 Sep 14 22:45 public.txt
-rwxr-xr-x 1 ana ana  34 Sep 14 22:45 script.sh
-rw-r----- 1 ana team 13 Sep 14 22:45 teamonly.txt
```

**`private.txt` — `-rw-------`.** A file. The owner reads and writes. The group gets nothing.
Everybody else gets nothing. `ana` and root, and that is the list.

**`public.txt` — `-rw-r--r--`.** A file. The owner reads and writes; everybody who can reach it
reads it. Nobody but `ana` changes it.

**`script.sh` — `-rwxr-xr-x`.** A file with `x` in all three rows: anybody may run it. Only `ana`
may edit it. That combination is what nearly every program in `/usr/bin` looks like.

**`teamonly.txt` — `-rw-r-----`.** A file. `ana` reads and writes. The group `team` reads. Everybody
else gets nothing, which is the `---` at the end, and it is why carla was refused in section 02.

## `x` is the one with two meanings

On a **file**, `x` means *this may be executed*. Without it, the file is data no matter what is
inside it:

```
ana@vm:~/x$ ls -l script.sh
-rw-r--r-- 1 ana ana 34 Sep 14 22:49 script.sh
ana@vm:~/x$ ./script.sh
bash: ./script.sh: Permission denied
ana@vm:~/x$ chmod +x script.sh
ana@vm:~/x$ ls -l script.sh
-rwxr-xr-x 1 ana ana 34 Sep 14 22:49 script.sh
ana@vm:~/x$ ./script.sh
the script ran
```

The file did not change. One bit did.

On a **directory**, `x` means something else entirely, and section 06 is about it. Carry nothing
across.

## The two extra characters you will meet

```
-rwsr-xr-x 1 root root 64152 May 30  2024 /usr/bin/passwd
drwxrwsr-x 2 root team  4096 Sep 14 22:44 /srv/team
drwxrwxrwt 38 root root 36864 Sep 14 22:45 /tmp
```

An `s` where an `x` should be, and a `t` at the end. Those are the special bits, they are section
10, and for now the thing to notice is only that **they sit in an `x` slot** — so a lowercase `s`
means the special bit is on *and* execute is on, and an uppercase `S` means the special bit is on
and execute is not, which is almost always a mistake.

And a `+` at the end of the nine:

```
-rw-r-----+ 1 ana ana 11 Sep 14 22:46 report.txt
```

That means the file carries an **access control list** — extra permissions that the nine
characters cannot express. Section 13. When a file's access does not match its mode, look for the
plus.

## How to answer "may I?" without guessing

Three questions, in order, and section 02 gave you the first two:

1. **Who am I?** `id` — and read the group list, not just the name.
2. **Which row applies?** Owner, then group, then other. The first match, and only that one.
3. **Can I reach it at all?** Every directory on the way needs `x`. This is the one people forget,
   and section 06 is where it earns its own section.

`namei -l` walks a path and prints the mode of every step, which answers all three at once:

```
bruno@vm:~$ namei -l /srv/closed/readable.txt
f: /srv/closed/readable.txt
drwxr-xr-x root root /
drwxr-xr-x root root srv
drwx------ ana  ana  closed
                      readable.txt - Permission denied
```

Four lines, and the third one is the answer: `closed` is `drwx------` and owned by `ana`, so bruno
never reaches the file at all — whatever the file's own mode says. Compare a path that works:

```
bruno@vm:~$ namei -l /srv/perm/teamonly.txt
f: /srv/perm/teamonly.txt
drwxr-xr-x root root /
drwxr-xr-x root root srv
drwxr-xr-x root root perm
-rw-r----- ana  team teamonly.txt
```

Every directory grants `x` to everybody, so the walk reaches the file and the file's own mode
decides. **This is the single most useful command for a denial you do not understand**, and almost
nobody knows it exists.
