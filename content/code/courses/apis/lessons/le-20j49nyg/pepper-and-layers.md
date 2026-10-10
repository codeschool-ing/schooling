---
title: A pepper, and the rules for the password itself
version: 1
---

Two more layers sit around the hash. A **pepper** protects the stored hashes when the database leaks
alone. And the **rules for the password** decide how long the guess list has to be before it reaches
it, which no hash can do anything about.

## A pepper is a key the database does not have

A pepper is one secret value, the same for every password, kept **outside** the database: in a file
only the server can read, or in a secrets manager. Before hashing, the password goes through an HMAC
with the pepper as its key, so what Argon2id hashes is a value nobody can compute without the key.

The wrong idea is that it is a second salt. A salt is public, stored in the row, and different in
every row; a pepper is secret, stored somewhere else, and the same for every row. It earns its place
only in one case, the one where the database leaks and the server's secrets do not: a backup of
`shelf.db`, a query that returned too much. In that case every guess against every row needs the key
first, and the table on its own is useless.

A key, kept where only its owner can read it, and the HMAC it produces:

```
ana@api:~$ openssl rand -base64 32 > pepper.key && chmod 600 pepper.key && ls -l pepper.key
-rw------- 1 ana ana 45 Oct 10 01:23 pepper.key
ana@api:~$ printf %s 'correct horse battery staple' | openssl dgst -sha256 -hmac "$(cat pepper.key)"
SHA2-256(stdin)= 4d9e379010370ed56865994f32938e97ab0b2e7a49cfebd5be0979e774b39431
```

The same password with a different key gives an unrelated value, which is the whole property:

```
ana@api:~$ printf %s 'correct horse battery staple' | openssl dgst -sha256 -hmac 'a different key'
SHA2-256(stdin)= bc4c043da0c136b6bfc363de1b0b9ad1ca9ba6a7537834a76f7c7896d6f125c7
```

In `passwords.py` that would be one function, `hmac.digest(key, password.encode(), "sha256")`,
called before `HASHER.hash` and before `HASHER.verify`. It is not in the file in this lesson,
because it brings a cost the file does not need yet: **a pepper cannot be changed**. Every stored
hash depends on it, so a new pepper means every user setting a new password. OWASP's sheet calls it
defence in depth, and says plainly that on its own it adds nothing.

## Passwords that have leaked before

A long password is no help if it is on every list. NIST's SP 800-63B requires a new password to be
compared with a list of passwords known to be common or already breached, and refused if it is on it.

A well-known list of breached passwords belongs to a public service, Have I Been Pwned, and it is
queried with **k-anonymity**: the server never learns the password, or even its full hash. You
compute the SHA-1 of the password yourself:

```
ana@api:~$ printf %s sunshine | sha1sum
8d6e34f987851aa599257d3831a1af040886842f  -
```

and send only the first five characters, `8d6e3`, to `https://api.pwnedpasswords.com/range/8d6e3`
(not run here: the machine this lesson was recorded on has no network). The answer is every hash
suffix that starts with those five characters, hundreds of them, each with a count, and your server
looks for the remaining 35 characters in that list itself. The service sees a prefix shared by
hundreds of passwords and cannot tell which one you asked about.

## What NIST asks of the password itself

NIST SP 800-63B, in its fourth revision, sets rules that surprise people who remember the old ones:

| rule | what it says |
|---|---|
| length | at least 15 characters when the password is the only factor; 8 when it is one of two |
| maximum | allow at least 64 characters |
| composition | do not demand mixtures of upper case, digits and symbols |
| expiry | do not force periodic changes; force one when there is evidence of compromise |
| blocklist | refuse passwords that are common or known to be breached |
| characters | accept every printable character and spaces, and Unicode |

**Length is what makes a guess list long, and composition rules mostly teach everybody the same
few patterns**, which is why they went. `passwords.py` enforces the first rule and
nothing more; a real registration would also check the blocklist. And the second rule meets bcrypt's
limit head on: 64 characters with accents can run past 72 bytes, which is one more reason the shelf
uses Argon2id.
