---
title: `umask`, which decides what a new file is born with
version: 1
---

Nothing asked you what permissions `report.txt` should have. Something decided, and it decided the
same thing every time:

```
ana@vm:~/um$ umask
0022
ana@vm:~/um$ touch a.txt
ana@vm:~/um$ mkdir a.dir
ana@vm:~/um$ ls -l
total 4
drwxr-xr-x 2 ana ana 4096 Sep 14 22:45 a.dir
-rw-r--r-- 1 ana ana    0 Sep 14 22:45 a.txt
```

`644` for the file, `755` for the directory. Those two numbers are where nearly every file on the
machine starts, and the `0022` is why.

## It is a mask: it says what to take away

A program creating a file asks for a mode. Nearly all of them ask for the same two:

| | asked for |
|---|---|
| a **file** | `666` — read and write for everybody, and no execute |
| a **directory** | `777` |

**Nothing gets what it asked for.** The kernel removes every bit the umask has set, and what is
left is the mode:

| | file | directory |
|---|---|---|
| requested | `666` | `777` |
| umask | `022` | `022` |
| **result** | **`644`** | **`755`** |

Take the umask digit away from the requested digit — `6 - 0 = 6`, `6 - 2 = 4`, `6 - 2 = 4` — and
you have `644`. The subtraction only works because the digits happen to line up here; what is
really happening is that each bit set in the mask is cleared in the result. Where the two differ is
a case you will not meet: a umask of `7` against a request of `6` gives `0`, not `-1`.

**Notice what the umask cannot do.** It only removes. A umask of `000` gives you `666` and `777`,
never a file with `x` on it, because nothing asked for `x` in the first place. That is why a new
script is not executable and you have to say `chmod +x` — section 05.

## Changing it, and watching it work

```
ana@vm:~/um$ umask 077
ana@vm:~/um$ touch b.txt
ana@vm:~/um$ mkdir b.dir
ana@vm:~/um$ ls -l
total 8
drwxr-xr-x 2 ana ana 4096 Sep 14 22:45 a.dir
-rw-r--r-- 1 ana ana    0 Sep 14 22:45 a.txt
drwx------ 2 ana ana 4096 Sep 14 22:45 b.dir
-rw------- 1 ana ana    0 Sep 14 22:45 b.txt
```

`077` removes everything from group and other: `600` and `700`. And look at `a.txt` and `a.dir` —
**unchanged.** A umask applies when a file is created and never again.

The other direction:

```
ana@vm:~/um$ umask 002
ana@vm:~/um$ touch c.txt
ana@vm:~/um$ ls -l c.txt
-rw-rw-r-- 1 ana ana 0 Sep 14 22:45 c.txt
```

`664` — group can write. That is the umask for working in a shared directory, and it is what the
setgid bit in section 10 is usually paired with.

`-S` prints it the other way round, as what is *allowed* rather than what is removed:

```
ana@vm:~/um$ umask -S
u=rwx,g=rx,o=rx
```

Easier to read, and the same fact.

## The three values you will meet

| | files | directories | for |
|---|---|---|---|
| `022` | 644 | 755 | the default on most distributions |
| `002` | 664 | 775 | shared work — the group can write |
| `077` | 600 | 700 | private — servers handling anything sensitive |

**`027` is the one to know about for servers**: files `640`, directories `750`. The group reads,
strangers see nothing at all. It is a common hardening setting, and it breaks software that assumed
`022`, which is how you find out it was set.

## Where it comes from and how to change it for good

The umask you have is set at login, and there are three or four places it can come from:

| | |
|---|---|
| `/etc/login.defs` | `UMASK 022`, the system-wide default on Debian and Ubuntu |
| `pam_umask` | how that default is actually applied at login |
| `/etc/profile`, `/etc/bash.bashrc` | a system-wide shell setting |
| `~/.bashrc`, `~/.profile` | yours, for interactive shells |

Typing `umask 077` at a prompt changes the current shell and its children, and nothing else. It is
gone when you log out.

**A umask in `~/.bashrc` does not apply to a service.** A service is started by systemd, not by
your shell, and it has its own — lesson 5's `UMask=` in a unit file. When a daemon writes files with
the wrong permissions, that is where to look, and editing your own dotfiles will not touch it.

## Two things that do not obey it

**`cp -p` and `tar -x` restore the modes they recorded.** That is the point of preserving
permissions, and it is why a file extracted from an archive can be more open than anything you
could create by hand.

**`chmod` is absolute.** `chmod 666 file` gives you `666`, umask or no umask. The mask is about
*creation*, and `chmod` is not creation.

There is one exception worth naming, because it looks like a contradiction: **`chmod +x` with no
`u`, `g` or `o` is filtered by the umask.**

```
ana@vm:~/uq$ umask 077
ana@vm:~/uq$ chmod 600 t1.txt t2.txt
ana@vm:~/uq$ chmod +x t1.txt
ana@vm:~/uq$ chmod a+x t2.txt
ana@vm:~/uq$ ls -l
total 0
-rwx------ 1 ana ana 0 Sep 14 22:57 t1.txt
-rwx--x--x 1 ana ana 0 Sep 14 22:57 t2.txt
```

Same intention, two different results. The bare `+x` was filtered and gave the owner alone; `a+x`
said who, and was not. **Write the audience out** and this never comes up.
