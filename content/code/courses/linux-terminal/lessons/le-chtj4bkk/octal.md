---
title: 755 and 644, and where the numbers come from
version: 1
---

Nine bits. Three per audience. **A three-bit number runs from 0 to 7**, which is why permissions
are written in base 8 and not in anything more familiar.

| | value |
|---|---|
| `r` | **4** |
| `w` | **2** |
| `x` | **1** |

Add up the ones that are on, for each group of three, and you have the digit:

| characters | arithmetic | digit |
|---|---|---|
| `rwx` | 4 + 2 + 1 | **7** |
| `rw-` | 4 + 2 | **6** |
| `r-x` | 4 + 1 | **5** |
| `r--` | 4 | **4** |
| `-wx` | 2 + 1 | 3 |
| `-w-` | 2 | 2 |
| `--x` | 1 | 1 |
| `---` | | **0** |

Three digits — owner, group, other — and the whole mode is a number.

## The four you should know without counting

```
-rw-r--r--   644
-rw-------   600
-rwxr-xr-x   755
drwxr-xr-x   755
```

`644` and `755` cover most of a Linux filesystem. Say them as **"six four four"** rather than "six
hundred and forty-four" — they are three separate digits, and pronouncing them as one number is
how people end up thinking 700 is bigger than 644 in some meaningful way.

`stat` will do the conversion for you, in both directions:

```
ana@vm:~/perm$ stat -c '%a %A %n' public.txt private.txt script.sh locked
644 -rw-r--r-- public.txt
600 -rw------- private.txt
755 -rwxr-xr-x script.sh
755 drwxr-xr-x locked
```

`%a` is the octal, `%A` is the characters. **Keep that command.** It is the fastest way to check
your own arithmetic while you are learning it, and the fastest way to read twenty files at once
after you have.

## Reading a number back into characters

Split into three digits, and turn each into three characters:

**640** → `6` is `rw-`, `4` is `r--`, `0` is `---` → `-rw-r-----`. The owner edits, the group
reads, everybody else is shut out. That is `teamonly.txt` from section 55.

**775** → `rwx`, `rwx`, `r-x` → a directory a whole group can add to and everybody can look in.

**700** → `rwx`, `---`, `---` → yours and nobody else's, which is the mode of `~/.ssh`.

## Why 4, 2, 1 and not 1, 2, 3

Because they are **bits**, not ranks. Each is a separate yes-or-no, and the values are powers of
two so that every combination adds up to a different number. With 1, 2 and 3, a 3 would be
ambiguous — write plus execute, or read on its own?

That also explains a question people ask once: *why is `w` worth more than `x`?* It is not worth
more. The order is `r`, `w`, `x` and the values are `4`, `2`, `1`, and nothing about 2 makes
writing more important than executing. They are labels for positions.

## The fourth digit

Modes sometimes have four:

```
root@vm:~# stat -c '%a %A %n' /usr/bin/passwd /tmp /srv/team
4755 -rwsr-xr-x /usr/bin/passwd
1777 drwxrwxrwt /tmp
2775 drwxrwsr-x /srv/team
```

The leading digit is the special bits — **4** setuid, **2** setgid, **1** sticky — and they add up
the same way. Section 63. When you see a mode with four digits, the first one is not part of the
nine.

And note what that implies: **`chmod 755` on a file that was `4755` turns the setuid bit off**,
because a three-digit number means the fourth digit is zero. That has broken working programs, and
it is why section 58 recommends the symbolic form for a change you want to be surgical.

## 777 is almost never the answer

`chmod 777` means *anybody on this machine may read, change and run this*. It appears constantly in
forum answers because it makes the immediate error go away.

**It works by removing the check rather than by fixing the problem.** The thing that was actually
wrong — the wrong owner, a missing `x` on a directory two levels up, a group nobody was in — is
still wrong; it just no longer matters, and neither does anything else.

Two things to do instead, in this order: work out **which bit** was missing, with `namei -l` from
section 56; and if the answer really is "these two accounts need to share this", that is what
groups are for (section 61) and what ACLs are for (section 66).

There is one place `777` is correct, and it is `/tmp` — which is `1777`, and the leading `1` is the
entire reason it is safe. Section 63.
