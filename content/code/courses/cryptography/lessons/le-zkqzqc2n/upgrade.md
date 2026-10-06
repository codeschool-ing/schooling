---
title: Verifying, and raising the cost without a reset
version: 1
---

**The cost of a password hash is chosen for today's hardware, and hardware gets faster.** A store
written with the right parameters five years ago is below policy now. Nobody can recompute it,
because nobody knows the passwords, and asking every user to change their password is a support
crisis. The answer is to upgrade each hash at the one moment the password is known: when its owner
signs in.

## An old store, and a sign-in

This store was written with Argon2id at a third of today's memory and a single pass:

```
ana@lab:~/lab$ vcrypt store argon2id --cost 7168,1,1 data/users.csv > store-old.txt; head -1 store-old.txt
ana.lima:$argon2id$v=19$m=7168,t=1,p=1$FuRufmOK/RUsaLq6VND23g$Xo8ynxvL3NZlvGNODLxk4TRoTY3CFHx62flw4Xl2mQI
```

Ana signs in with the right password. Verification reads the parameters from the stored string,
recomputes with them, compares, and then notices they are below policy:

```
ana@lab:~/lab$ vcrypt verify store-old.txt ana.lima 'Vereda@2026'
ana.lima: password accepted; rehash now: stored m=7168,t=1 is below the policy m=19456,t=2
```

That second clause is the signal for the application to recompute the hash **now**, with the policy
parameters and a fresh salt, and replace the stored line, while it holds the password it just
verified. Users who sign in move to the new cost without noticing. Users who never sign in again
keep the old hash, and after a deadline the usual practice is to disable those accounts and require
a reset, so that no weak hash stays in the store forever.

The same path moves a store from one algorithm to another. A system leaving bcrypt for Argon2id
accepts both on the way in and writes only Argon2id on the way out.

## The answers sign-in must not vary

The other two attempts are a wrong password and an account that does not exist:

```
ana@lab:~/lab$ vcrypt verify store-old.txt ana.lima 'vereda@2026'
ana.lima: wrong password
ana@lab:~/lab$ vcrypt verify store-old.txt ana.lim 'Vereda@2026'
ana.lim: wrong password
```

They answer **identically**. A sign-in form that says "no such user" for one and "wrong password"
for the other tells a stranger which addresses have accounts here, and on a clinic's portal that is
already a fact about somebody's health. The same holds for time: if a missing account is answered
instantly while a real one takes a quarter of a second of Argon2id, the difference is measurable
from outside. Careful implementations verify against a fixed decoy hash when the account does not
exist, so that both paths cost the same.

## The check inside the check

The final comparison of the computed value against the stored one uses a **constant-time**
comparison (`hmac.compare_digest` in Python, `crypto/subtle.ConstantTimeCompare` in Go). An
ordinary string comparison stops at the first differing byte, and that tiny difference in time can
reveal how much of a value matched. For a password hash it matters less than for the HMAC tags of
lesson 6, where the attacker controls the input, but the libraries that verify passwords use it
anyway, and so should anything you write around them.
