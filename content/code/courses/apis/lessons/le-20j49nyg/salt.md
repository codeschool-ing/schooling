---
title: Salt
version: 1
---

**A salt is a random value, different for every password, stored next to its hash and mixed in
before hashing.** It makes the same password produce a different hash in every row, and that is the
whole of its job.

The usual mistake is to treat the salt as a secret, and then to worry about where to hide it. It is
not a secret. It sits in the database beside the hash, in plain sight, and the next sections show it
inside the stored string itself. What it has to be is **unique**, and that is all.

Without one, two accounts with the same password have the same hash. `sha256sum` of the same word,
for two users:

```
ana@api:~/shelf$ for user in ana bia; do printf %s sunshine | sha256sum; done
a941a4c4fd0c01cddef61b8be963bf4c1e2b0811c037ce3f1835fddf6ef6c223  -
a941a4c4fd0c01cddef61b8be963bf4c1e2b0811c037ce3f1835fddf6ef6c223  -
```

That line says two things to whoever reads the table. Ana and Bia chose the same password, which is
already a leak. And a table of hashes computed once, in advance, from a list of common passwords
answers both rows by lookup, along with every other row in every other database that stored the same
unsalted hash.

A password hash draws a new salt every time. The same word, hashed twice with bcrypt:

```
ana@api:~/shelf$ python3 -c 'import bcrypt; print(bcrypt.hashpw(b"sunshine", bcrypt.gensalt()).decode())'
$2b$12$vPe9g2i5PwfDp/R1Y3.FVuhpeWirsJXGy.SOIDrvpBoR8I5G6p7Rm
ana@api:~/shelf$ python3 -c 'import bcrypt; print(bcrypt.hashpw(b"sunshine", bcrypt.gensalt()).decode())'
$2b$12$OOIkx1PD0sVFPNws/R5jc.2XyB28n4CgB6mh.d1b7rLQ8/q2zPl.2
```

Two different strings for one password. The 22 characters after `$2b$12$` are the salt, which the
next section takes apart, and they are what makes the two differ. A table computed in advance is now
useless, because it would need an entry for every possible salt, and a guess tested against Ana's row
says nothing about Bia's.

**A salt does not make one guess more expensive.** Salted SHA-256 is still more than a million
guesses a second against a single row; the salt only makes each row its own job. The cost per guess
is the cost factor, and the two work together.

Three rules, and the libraries in this lesson follow all of them for you:

| rule | why |
|---|---|
| a new salt for every password, including a changed one | an old salt reused is two rows with one job |
| random, from the operating system's secure generator | a predictable salt can be computed in advance |
| never the user's name or e-mail | it is the same on every site, and known before any leak |

Writing your own salting is where these rules get broken, so do not: call a password-hashing
function that draws its own salt, as every one in the next three sections does.
