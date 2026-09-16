---
title: Making, copying, moving and removing
version: 1
---

Six commands do all of it, and none of them will ask you whether you are sure.

| | does | the option that matters |
|---|---|---|
| `mkdir` | make a directory | `-p` — make the parents too |
| `touch` | make an empty file, or update its time | — |
| `cp` | copy | `-r` for directories, `-i` to be asked |
| `mv` | move, and also rename | `-i` to be asked |
| `rm` | remove | `-r` for directories, `-f` to stop complaining |
| `rmdir` | remove an **empty** directory | — |

## `mkdir` and `touch`

```
ana@vm:~/sandbox$ mkdir archive
ana@vm:~/sandbox$ touch report.txt
ana@vm:~/sandbox$ ls -l
total 0
-rw-r--r-- 1 ana ana 0 Sep 14 22:01 report.txt
```

`touch` on a name that does not exist creates an empty file. On a name that **does** exist, it
changes nothing but the timestamp:

```
ana@vm:~/sandbox$ ls -l old.txt
-rw-r--r-- 1 ana ana 0 Jan  1  2025 old.txt
ana@vm:~/sandbox$ touch old.txt
ana@vm:~/sandbox$ ls -l old.txt
-rw-r--r-- 1 ana ana 0 Sep 14 22:01 old.txt
```

That is what the name means — touching a file without changing it — and it is how you make
something look recently modified to a build system or a backup job.

`mkdir -p` makes every level of a path at once, and does not complain if some already exist:

```
ana@vm:~/sandbox$ mkdir -p deep/a/b/c
```

Three directories, one command. In a script, `-p` is nearly always what you want, because "make
this if it is not already there" is what you meant and the bare form fails when it is.

## `cp`, and the `-r` you will forget once

```
ana@vm:~/sandbox$ cp report.txt report-copy.txt
ana@vm:~/sandbox$ cp report.txt archive/
```

Two forms, and the difference is the **destination**: to a name, it copies under that name; to a
directory, it copies into it, keeping the name. That is one rule and it holds for `mv` too.

A directory needs `-r`:

```
ana@vm:~/sandbox$ cp archive backup
cp: -r not specified; omitting directory 'archive'
ana@vm:~/sandbox$ cp -r archive backup
ana@vm:~/sandbox$ ls backup
report-2.txt  report.txt
```

Read that first message carefully: it is not an error, it is `cp` telling you it **skipped**
something. In a command copying twenty things it will skip the directory and copy the rest, and
the only sign is one line you might scroll past.

**The other `cp` options worth knowing now:**

| | does |
|---|---|
| `-a` | archive: recursive, and keeps permissions, owner and timestamps |
| `-i` | ask before overwriting |
| `-n` | never overwrite, silently |
| `-v` | print each file as it goes |
| `-u` | only copy if the source is newer |

`cp -a` is the one to use when a copy should be indistinguishable from the original. Plain `cp`
gives the copy today's date and your umask, which is fine for a working file and wrong for a
backup.

## `mv` renames *and* moves, because they are the same operation

```
ana@vm:~/sandbox$ mv report-copy.txt report-2.txt
ana@vm:~/sandbox$ mv report-2.txt archive/
```

There is no `rename` command in the base system. **Renaming is moving within one directory** — you
are changing which name in which directory points at the data, and that is all a move is.

That also explains something you will notice: moving a 4 GB file within one filesystem is
instant, and moving it to a different disk takes minutes. Within one filesystem it is a rename.
Across filesystems it is a copy and a delete wearing a rename's clothes.

`mv` needs no `-r`. A directory moves as one thing.

## Nothing asks. Here is what that costs.

```
ana@vm:~/sandbox$ cat keep.txt
the good one
ana@vm:~/sandbox$ cp other.txt keep.txt
ana@vm:~/sandbox$ cat keep.txt
the other one
```

No prompt. No message. No trash. **`keep.txt` is gone**, and there is nothing to restore it from
unless you have a backup. `mv` does exactly the same:

```
ana@vm:~/sandbox$ mv other.txt keep.txt
ana@vm:~/sandbox$ ls
archive  deep  keep.txt  old.txt
```

Two files went in, one came out, and nothing was said about it.

**`-i` makes it ask:**

```
ana@vm:~/sandbox$ cp -i other.txt keep.txt
cp: overwrite 'keep.txt'? n
ana@vm:~/sandbox$ cat keep.txt
the good one
```

The `n` is typed, and nothing happens. Many distributions ship `alias cp='cp -i'` for the root account
precisely because of this, and lesson 9 shows you how to set that up for yourself.

But **do not build a habit on the alias**, for a reason that catches people out: an alias does not
apply in a script, over `ssh -c`, or under `sudo`. The habit that travels is smaller — *before an
overwrite, `ls` the destination.*

## `rm`, `rmdir`, and `rm -rf`

```
ana@vm:~/sandbox$ rm report.txt
ana@vm:~/sandbox$ rm backup
rm: cannot remove 'backup': Is a directory
ana@vm:~/sandbox$ rm -r backup
```

`rmdir` removes a directory **only if it is empty**, which is a feature:

```
ana@vm:~/sandbox$ rmdir deep
rmdir: failed to remove 'deep': Directory not empty
ana@vm:~/sandbox$ rmdir deep/a/b/c
```

That refusal is a safety net. When you *know* a directory should be empty, `rmdir` checks the
assumption for you and `rm -r` does not.

`-f` means "do not complain, do not ask":

```
ana@vm:~/sandbox$ rm -f nosuchfile.txt
ana@vm:~/sandbox$ echo $?
0
ana@vm:~/sandbox$ rm nosuchfile.txt
rm: cannot remove 'nosuchfile.txt': No such file or directory
ana@vm:~/sandbox$ echo $?
1
```

That is the legitimate use of `-f` and the reason it exists: in a script, "remove this if it is
there" should not fail when it is not.

### `rm -rf` deserves its reputation

It means *remove, recursively, without asking, without complaining*. It is a normal working tool
— it is how you delete a `node_modules` — and it is the command that has destroyed more work than
every other command on this list put together.

Three habits, and they cost nothing:

**Run it as `ls` first.** `ls -d /path/to/thing` before `rm -rf /path/to/thing`. You are checking
that the path you typed is the path you meant.

**Never let a variable end up empty.** `rm -rf "$DIR/"` with `DIR` unset is `rm -rf /`. This is not
folklore; it is a bug that has shipped in real installers more than once. Lesson 9's section on
quoting and `set -u` is where that gets fixed properly.

**Be suspicious of a trailing slash and a star together.** `rm -rf /some/path /*` is one stray
space away from `rm -rf /some/path/*`, and the two do very different things.

Modern GNU `rm` refuses `rm -rf /` outright, which helps with exactly one of the ways this goes
wrong.

## And a last one about directories

```
mv src dest
```

If `dest` does not exist, `src` is renamed to `dest`. If `dest` **does** exist and is a directory,
`src` is moved *inside* it, giving you `dest/src`. Same command, two outcomes, decided by
something that is not on the line.

This is the trap section 04 promised. The check is the same one as everywhere else in this
section: `ls` the destination first.
