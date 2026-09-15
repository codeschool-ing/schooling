---
title: `/etc/shadow`, and what a stored password is
version: 1
---

The account `demo` was made for this section, and its password is the string
`example-password`. Here is what the machine kept:

```
root@vm:~# grep '^demo:' /etc/shadow
demo:$y$j9T$iladG9xXy9DklFOvrTOFd0$wisSqn5Qt6jQDW3xy9KJLj3qV2CE7IEoUIfRcRg2l.1:20710:0:99999:7:::
```

**The password is not in there.** What is in there is a hash: a value computed from the password
that cannot be run backwards. When `demo` types something at a login prompt, the system hashes what
was typed and compares the two hashes. It has no way to tell anybody what the password is, because
it does not know.

That is why *"we have reset your password"* is normal and *"your password is …"* in an email is a
red flag about the system that sent it.

## Reading the hash field

```
$y$j9T$iladG9xXy9DklFOvrTOFd0$wisSqn5Qt6jQDW3xy9KJLj3qV2CE7IEoUIfRcRg2l.1
 ─┬─ ─┬─ ───────────┬───────── ─────────────────┬──────────────────────
  │   │             │                           └── the hash
  │   │             └── the salt
  │   └── parameters: how much work the hash costs
  └── the algorithm
```

| `$` prefix | algorithm |
|---|---|
| `$y$` | yescrypt — the default on Debian and Ubuntu since 2021 |
| `$6$` | SHA-512 — the previous default, still everywhere |
| `$2b$` | bcrypt |
| `$1$` | MD5 — obsolete, and a finding in an audit |

**The salt is the interesting part.** It is random, it is different for every account, and it is
stored in the clear beside the hash. Two people with the same password get different hashes, so an
attacker who steals the file cannot crack them all at once — and a precomputed table of common
passwords is worthless, because it would have to be recomputed per salt.

**And the parameters are why it is slow on purpose.** Hashing a password should take a
meaningful fraction of a second. You notice it once at login; an attacker trying a billion guesses
notices it a billion times.

## The other eight fields

```
demo:HASH:20710:0:99999:7:::
```

| | is | here |
|---|---|---|
| 1 | name | `demo` |
| 2 | hash | above |
| 3 | last change, in **days since 1970** | `20710` |
| 4 | minimum days before it may change again | `0` |
| 5 | maximum days before it must | `99999` |
| 6 | days of warning before that | `7` |
| 7 | days of grace after expiry | empty |
| 8 | account expiry date | empty |
| 9 | reserved | empty |

Nobody reads that by eye. `chage -l` reads it for you:

```
root@vm:~# chage -l demo
Last password change                                    : Sep 14, 2026
Password expires                                        : never
Password inactive                                       : never
Account expires                                         : never
Minimum number of days between password change          : 0
Maximum number of days between password change          : 99999
Number of days of warning before password expires       : 7
```

`99999` days is about 273 years, which is how "never" is spelled in a field that has to hold a
number.

## Ageing, set and read back

```
root@vm:~# chage -M 90 -W 14 demo
root@vm:~# chage -l demo
Last password change                                    : Sep 14, 2026
Password expires                                        : Dec 13, 2026
Password inactive                                       : never
Account expires                                         : never
Minimum number of days between password change          : 0
Maximum number of days between password change          : 90
Number of days of warning before password expires       : 14
```

`-M 90` sets the maximum age and `-W 14` the warning. `chage` computed the date; the file still
holds day numbers.

| | |
|---|---|
| `chage -l user` | read the ageing settings |
| `chage -M 90 user` | must change within 90 days |
| `chage -E 2026-12-31 user` | the **account** expires on that date — for a contractor |
| `chage -d 0 user` | force a change at the next login |

**`chage -d 0` is the one to know.** It sets "last changed" to the epoch, so the password is
immediately overdue and the user is made to set a new one when they log in. That is how you hand
somebody an account with a temporary password honestly.

## Locking, and what `passwd -S` tells you

```
root@vm:~# passwd -S demo
demo P 2026-09-14 0 90 14 -1
root@vm:~# passwd -l demo
passwd: password changed.
root@vm:~# passwd -S demo
demo L 2026-09-14 0 90 14 -1
root@vm:~# passwd -u demo
passwd: password changed.
root@vm:~# passwd -S demo
demo P 2026-09-14 0 90 14 -1
```

The second field is the state:

| | |
|---|---|
| `P` | a usable password is set |
| `L` | **locked** |
| `NP` | no password at all — anybody may log in |

`passwd -l` locks by putting a `!` in front of the hash, so no typed password can ever hash to it.
`passwd -u` takes the `!` away again — which is why the hash has to stay there, and why locking is
reversible.

**Locking the password does not stop an ssh key from working.** That surprises people the day
somebody leaves: `passwd -l` and the account still logs in over ssh, because keys never touched
`/etc/shadow`. Section 75 is where that lives; the belt-and-braces version is
`usermod -L -e 1 user`, which expires the account itself.

Note also that `passwd -l` prints `password changed.` — the one confusing message in this section,
and it is telling the truth in an unhelpful way. The stored field did change.

## What you will actually do with all of this

Almost nothing, most days. Set a password with `passwd`, force a change with `chage -d 0`, lock an
account when somebody leaves.

What is worth keeping is the shape: **a password is stored as something that cannot be reversed, in
a file nobody but root reads, with a per-account salt** — and every system you build for other
people should do the same. Lesson 4's `-rw-r-----` on that file is not decoration.
