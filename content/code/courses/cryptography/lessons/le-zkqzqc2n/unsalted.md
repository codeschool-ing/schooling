---
title: Why a plain hash is the wrong way to store a password
version: 1
---

**A system never needs to know a user's password, only to recognise it.** So it stores something
derived from the password, and at sign-in it derives the same thing from what was typed and
compares. Lesson 4's hash looks like the obvious tool for that, and it is the start of the right
answer, not the answer. This section shows the three things wrong with storing a plain SHA-256,
using Vereda's eight staff accounts.

## The accounts

The lab's `users.csv` holds eight accounts and the passwords their owners chose. The course wrote
them to be bad in the usual ways; nobody uses them for anything:

```
ana@lab:~/lab$ cat data/users.csv
user,password
ana.lima,Vereda@2026
bruno.reis,fisio123
carla.souza,Vereda@2026
diego.alves,correct horse battery staple
elisa.prado,fisio123
fabio.nunes,Vereda@2026
gabi.torres,m4r3-alta-em-ub@tub@
hugo.matos,Primavera#2026
```

A real system never holds this file. It is here so that you can see what each storage scheme does
to the same passwords.

## Problem one: equal passwords are visible

Stored as plain SHA-256, one value per account:

```
ana@lab:~/lab$ vcrypt store sha256 data/users.csv > store-sha256.txt; head -3 store-sha256.txt
ana.lima:9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21
bruno.reis:3bec5774e1c543e4f58b467da1a227fe3b4c20d9138a43d5735ae73fb1b5d698
carla.souza:9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21
```

Ana and Carla have the same stored value, and so does Fábio further down. Vereda's own audit says
so in one line:

```
ana@lab:~/lab$ vcrypt audit store-sha256.txt
8 accounts, 5 different stored values
  3 accounts share one value: ana.lima, carla.souza, fabio.nunes
  2 accounts share one value: bruno.reis, elisa.prado
```

Nobody reversed anything to learn that three people share a password and two others share
another. Whoever obtains this file knows that guessing one of them gives three accounts, and that
the shared ones are probably the easiest, because people converge on the same easy choices.

## Problem two: the same value everywhere

SHA-256 has no key and no secret, so the digest of a password is the same in every system in the
world:

```
ana@lab:~/lab$ printf 'Vereda@2026' | sha256sum
9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21  -
```

That is Ana's stored value, computed on the command line from the password alone. It means a list
of the digests of common passwords, computed once, matches against **every** unsalted store ever
leaked. Such precomputed lists, and the compressed form of them called *rainbow tables*, have
existed for decades. Against a plain hash, a large share of real passwords is found by a lookup,
not by any computation at all.

## Problem three: it is fast

SHA-256 was designed to be fast, because it hashes downloads and disks. That is exactly wrong here.
A single modern GPU computes **billions** of SHA-256 digests a second, so even a password nobody has
precomputed is tested against billions of candidates per second. A password of eight lowercase
letters has about 200 billion possibilities, which is minutes of work.

The defence has three parts, and they are the rest of this lesson:

| problem | fix | section |
|---|---|---|
| equal passwords visible, precomputed lists work | a unique **salt** per account | 03 |
| billions of guesses a second | a deliberately **slow** function: bcrypt, Argon2id | 04 |
| the store alone is enough to start guessing | a **pepper** kept outside the database | 05 |

None of them makes a weak password strong. What they do is make each guess expensive and force the
attacker to guess every account separately, which turns a leak of the whole store into a slow,
costly attack on a few accounts, and buys the time to reset them.
