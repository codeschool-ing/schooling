---
title: What goes wrong when a password is stored
version: 1
---

**Assume the users table will leak, and ask what the leak gives away.** That is the threat this
lesson defends against. It is not an attacker guessing at your login form, which lesson 12 deals
with; it is somebody holding a copy of the table, on their own computer, with all the time they
want. A backup in the wrong bucket, a query that returns one column too many, an old disk: every
one of them has happened to somebody, and none of them asks your login code for permission.

The common belief is that the database is protected, so what sits inside it does not matter much.
The database is protected until the day it is not, and that day is when what you stored decides
the damage. There are three ways to store a password badly, and each fails differently.

**Plaintext.** The column holds the password itself. Whoever reads the table can sign in as
everybody, at once, and the damage does not stop at your API: people reuse passwords, so the same
pair of address and password opens their e-mail and their bank. You never learn which of your users
were affected elsewhere.

**Encryption.** The column holds the password encrypted with a key. It feels safer, and it is the
same thing with one more step, because encryption is built to be reversed. Here is a password
encrypted with a key, and decrypted again with the same key:

```
ana@api:~$ printf %s sunshine | openssl enc -aes-256-cbc -pbkdf2 -pass pass:the-server-key -base64 > stored.txt && cat stored.txt
U2FsdGVkX18t4aosowNRR+TCnkoNAoicUlZ/l5pFzjE=
ana@api:~$ openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:the-server-key -base64 -in stored.txt; echo
sunshine
```

The program that checks logins needs that key to compare, so the key lives where the program
lives: in a configuration file, an environment variable, the same backup. A leak that takes the
server's files takes the key with them, and then every password comes back in clear.

**A fast hash.** The column holds SHA-256 of the password. A hash cannot be reversed, which is the
right idea, and it still fails. SHA-256 is built to be fast, so somebody holding the table can hash a
list of likely passwords and compare each result. On the lab machine of the next section, a million
of those guesses took under a second.

| what the column holds | what a leaked table gives |
|---|---|
| the password | every password, immediately |
| the password, encrypted | every password, as soon as the key leaks too |
| a fast hash such as SHA-256 | every password that is on a list of likely ones, cheaply |
| a slow, salted password hash | each password only at a cost per guess, per account |

**A login never needs the password back.** It needs to know whether what somebody typed is the same
password that was set, and a one-way function answers that: hash what was typed, compare with what
was stored. The rest of the lesson is about making that function expensive to run, unique for every
account, and readable later when its settings change.
