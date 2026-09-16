---
title: The same three letters, on a directory
version: 1
---

A directory is a list of names. That sentence is the whole section: once you read the three bits
as permissions **on a list**, every strange behaviour in this section becomes obvious.

| | on a file | on a directory |
|---|---|---|
| `r` | read the contents | **read the list of names** |
| `w` | change the contents | **add, remove and rename entries** |
| `x` | run it as a program | **go through it, and look at what is in it** |

`x` is the one with a new meaning, and it is usually translated as *search* or *traverse*. Without
it, a directory is a wall — not because the things inside are protected, but because you cannot
reach them to ask.

## Three directories, three half-permissions

Here are three directories with identical contents, differing only in their mode, read by somebody
who owns none of them:

```
bruno@vm:/srv$ ls -ld dirbits/rx dirbits/r dirbits/x
dr--r--r-- 2 ana ana 4096 Sep 14 22:45 dirbits/r
dr-xr-xr-x 2 ana ana 4096 Sep 14 22:45 dirbits/rx
d--x--x--x 2 ana ana 4096 Sep 14 22:45 dirbits/x
```

**`r-x` — both bits. This is a normal directory.**

```
bruno@vm:/srv$ ls dirbits/rx
file.txt
bruno@vm:/srv$ cat dirbits/rx/file.txt
the contents
```

List it, and read what is in it. Nothing surprising.

**`r--` — read without execute. You get the names and nothing else.**

```
bruno@vm:/srv$ ls dirbits/r
file.txt
bruno@vm:/srv$ cat dirbits/r/file.txt
cat: dirbits/r/file.txt: Permission denied
```

`ls` worked. `cat` did not. You can see that `file.txt` exists and you cannot go through the
directory to reach it. **The file's own mode is `-rw-r--r--`** — world-readable — and it makes no
difference at all.

**`--x` — execute without read. You get the contents, if you already know the name.**

```
bruno@vm:/srv$ ls dirbits/x
ls: cannot open directory 'dirbits/x': Permission denied
bruno@vm:/srv$ cat dirbits/x/file.txt
the contents
```

The exact opposite. Listing is refused, and reading a file by name works perfectly.

**Read that pair again, because it is the thing to take away.** `r` is *seeing what is here*. `x`
is *going through*. They are separate questions, and a directory can answer yes to either one on
its own.

## `--x` is not a curiosity, it is how home directories work

A directory that grants `x` but not `r` is the standard way to say *there are things in here for
the people who know about them, and I am not publishing a list*. You will meet it on:

- `/home/someone` on a shared machine, set to `711`, so anybody can reach a path you told them
  about and nobody can enumerate what you have;
- a web server's document root, where directory listing is off for the same reason;
- `/var/log` on some distributions.

"Security through obscurity" is the usual sneer, and it is not what this is: the files still have
their own permissions. What `--x` removes is the *index*, which is a real thing to withhold.

## Every directory on the way needs `x`

This is the rule that explains most confusing denials. Reaching `/srv/closed/readable.txt` means
walking `/`, then `srv`, then `closed`, and **each of those needs `x` for you.** One missing bit
anywhere in the chain and the file is unreachable, whatever it says about itself.

```
bruno@vm:~$ namei -l /srv/closed/readable.txt
f: /srv/closed/readable.txt
drwxr-xr-x root root /
drwxr-xr-x root root srv
drwx------ ana  ana  closed
                      readable.txt - Permission denied
```

`readable.txt` is `-rw-r--r--`. Anybody may read it. Nobody but `ana` can get to it.

**When a denial makes no sense, the answer is usually a directory rather than the file.** Run
`namei -l` on the full path and read down the column of modes.

## `w` on a directory is the one that surprises people

**Deleting a file is a write to the directory, not to the file.**

So you can delete a file you cannot read, cannot write, and do not own — if you can write the
directory it is in. And you cannot delete a file you own outright, if the directory says no.

That is not a bug. Removing a file means removing its name from a list, and changing a list is a
write to the list. Lesson 3 section 11 already told you this from the other side: `rm` is `unlink`.

It has one large consequence, and it is why `/tmp` exists in the state it does. A directory anybody
may write is a directory where anybody may delete anybody's files — which would make `/tmp`
useless. The fix is one extra bit, and it is section 10.

## What a mode means, in words

| mode | reads as |
|---|---|
| `drwxr-xr-x` | 755 — the owner manages it, everybody may look and pass through |
| `drwxr-x---` | 750 — the owner and the group; strangers see nothing |
| `drwx------` | 700 — yours. `~/.ssh` is this |
| `drwx--x--x` | 711 — pass through by name, no listing |
| `drwxrwxrwt` | 1777 — `/tmp`, and the `t` is section 10 |

**And one that is almost always a mistake:** a directory with `w` but no `x`. You may add a name to
a list you cannot walk into, which means creating files you then cannot open. It is what `chmod -R`
with a file mode produces, and section 05 showed it happening.
