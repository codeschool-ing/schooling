---
title: Three audiences, and only one of them is you
version: 1
---

Every file has an **owner** and a **group**, and lesson 3 section 06 already showed you both:

```
-rw-r----- 1 ana team 13 Sep 14 22:45 teamonly.txt
```

`ana` owns it. Its group is `team`. And the nine characters at the front are three sets of three:

| | characters | applies to |
|---|---|---|
| **user** | `rw-` | `ana`, the owner |
| **group** | `r--` | anybody in `team` |
| **other** | `---` | everybody else |

Linux calls them *user*, *group* and *other* — **u**, **g**, **o** — which is where `chmod u+x`
gets its letters.

## Three people, one file, three answers

Here is the same directory read by three accounts. `bruno` is in the group `team`; `carla` is not.

**`ana`, the owner:**

```
ana@vm:/srv/perm$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana),27(sudo),1004(team)
```

**`bruno`, in the group:**

```
bruno@vm:/srv/perm$ id
uid=1002(bruno) gid=1003(bruno) groups=1003(bruno),1004(team)
bruno@vm:/srv/perm$ ls -l
total 16
-rw------- 1 ana ana   9 Sep 14 22:45 private.txt
-rw-r--r-- 1 ana ana  22 Sep 14 22:45 public.txt
-rwxr-xr-x 1 ana ana  34 Sep 14 22:45 script.sh
-rw-r----- 1 ana team 13 Sep 14 22:45 teamonly.txt
bruno@vm:/srv/perm$ cat public.txt
anybody can read this
bruno@vm:/srv/perm$ cat private.txt
cat: private.txt: Permission denied
bruno@vm:/srv/perm$ cat teamonly.txt
for the team
bruno@vm:/srv/perm$ echo 'bruno' >> teamonly.txt
bash: line 11: teamonly.txt: Permission denied
```

Four commands, four different outcomes, and each one is decided by a different set of three
characters. `public.txt` is `r--` for other, so he reads it. `private.txt` is `---` for other, so
he does not. `teamonly.txt` is `r--` for **group**, and he is in `team`, so he reads it and cannot
write it.

**`carla`, in neither:**

```
carla@vm:/srv/perm$ id
uid=1003(carla) gid=1005(carla) groups=1005(carla)
carla@vm:/srv/perm$ cat public.txt
anybody can read this
carla@vm:/srv/perm$ cat teamonly.txt
cat: teamonly.txt: Permission denied
```

Same file, same bits, different answer — because the *group* row did not apply to her and the
*other* row did.

**Notice what changed and what did not.** The file never changed. Nothing was reconfigured
between those two sessions. The only variable is who asked, and which of the three rows their
identity selects.

## The rule people get wrong

**Exactly one of the three sets applies to you, and it is the first one that matches:**

1. Are you the **owner**? Then the user bits apply, and the other two are irrelevant to you.
2. Otherwise, are you in the **group**? Then the group bits apply.
3. Otherwise, the **other** bits apply.

The intuition everybody brings — *I am the owner and I am also in the group, so I get whichever is
more generous* — is wrong, and here is a file built to prove it:

```
ana@vm:/srv/perm$ ls -l trap.txt
-r--rwxrwx 1 ana team 9 Sep 14 22:45 trap.txt
ana@vm:/srv/perm$ id -nG
ana sudo team
ana@vm:/srv/perm$ cat trap.txt
the trap
ana@vm:/srv/perm$ echo 'ana' >> trap.txt
bash: line 7: trap.txt: Permission denied
```

Read that mode: `r--` for the owner, `rwx` for the group, `rwx` for everybody else. **Ana owns it,
ana is in `team`, and ana cannot write it.** Bruno can. Carla can. The owner is the one person
locked out, because her row is checked first and her row says `r--`.

It looks like a bug and it is the design. The owner row exists so that an owner can *deliberately*
give themselves less than everybody else — a file you want to be sure you do not overwrite by
accident is exactly this. And root ignores the whole thing anyway, which is section 11.

## What the three letters mean

| | on a file |
|---|---|
| `r` | read the contents |
| `w` | change the contents |
| `x` | run it as a program |
| `-` | not allowed |

On a **directory** the same three letters mean something different, and that is section 06's
entire subject. Do not carry the file meanings across; they will mislead you.

## Two things that are not in the nine characters

**Deleting a file is not controlled by the file's bits.** It is controlled by the **directory's**
— because removing a file means removing a name from a directory, which is a change to the
directory. That is why you can delete a file you cannot read, and why `/tmp` needs the extra bit
in section 10.

**Nothing here knows about people.** These are user *accounts* and *groups*, matched by number.
Section 08 is where those numbers come from, and lesson 5 is where accounts actually live.
