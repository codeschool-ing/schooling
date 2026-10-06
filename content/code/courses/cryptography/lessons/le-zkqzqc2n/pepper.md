---
title: A pepper, the secret kept outside the database
version: 1
---

**A pepper is a secret key, one for the whole system, mixed into every password before it is
hashed, and stored somewhere other than the database.** Salt and cost assume the attacker has the
store and make guessing slow. A pepper aims at a narrower and common case: an attacker who has the
store and **nothing else**, which is what a leaked backup or a database injection usually gives.
Without the pepper they cannot test a single guess.

## Adding one

The lab's pepper is `keys/pepper.hex`, 32 random bytes. `vcrypt store --pepper` first computes an
HMAC of the password with the pepper as key, then hands that to Argon2id exactly as before:

```
ana@lab:~/lab$ vcrypt store argon2id --pepper keys/pepper.hex data/users.csv > store-peppered.txt; head -1 store-peppered.txt
ana.lima:$argon2id$v=19$m=19456,t=2,p=1$FuRufmOK/RUsaLq6VND23g$0bKIIWlMFo4QB835pvClZQ3MfzfJrRD46zCFpP6W/Rw
```

The stored string looks like any other Argon2id hash. It even has the same salt as Ana's line in the
previous section, because the lab derives salts per user; the result differs because the input to
Argon2id was the peppered value. With the pepper, Ana's password is accepted:

```
ana@lab:~/lab$ vcrypt verify --pepper keys/pepper.hex store-peppered.txt ana.lima 'Vereda@2026'
ana.lima: password accepted
```

Without it, the same password is refused, and that is the whole point: somebody holding only
`store-peppered.txt` cannot even check a correct guess.

```
ana@lab:~/lab$ vcrypt verify store-peppered.txt ana.lima 'Vereda@2026'
ana.lima: wrong password
```

## Where the pepper lives

A pepper is only worth something if it is **not** where the store is:

- in a secrets manager or a hardware security module the application reads at start-up, not in a
  table of the same database;
- not in the application's repository, for the reasons of lesson 17;
- the same for every account, because it is a key, not a salt.

The strongest arrangement keeps it inside an HSM and asks the HSM to compute the HMAC, so the pepper
never exists in the application's memory at all.

## What it costs

A pepper adds a key to manage, and keys must be rotatable. Rotating a pepper cannot recompute the
stored hashes, because nobody knows the passwords. The usual answer is a pepper **identifier** in
each stored record: new passwords use the new pepper, old records keep naming the old one, and each
user moves to the new pepper the next time they sign in, by the same mechanism as the next section.
Lose the pepper and every password in the store is lost with it, so it is backed up with the care
of the database itself, separately.

A pepper is optional and a salt is not. OWASP lists it as an additional defence, worth having where
the infrastructure to keep a key apart already exists.
