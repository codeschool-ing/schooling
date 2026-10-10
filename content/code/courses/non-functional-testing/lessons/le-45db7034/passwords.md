---
title: Passwords and sign-in
version: 1
---

The tester's questions about passwords are about what happens around the moment of sign-in, and
about what would be left if the database were copied. **A password must never be stored as itself,
nor in any form that turns back into it**, and the sign-in must not help somebody who is guessing.

## What the database holds

Ask SQLite what `account.py` keeps, and compare the start of a stored session with the start of a
token a customer holds:

```
ana@nft:~/boxoffice$ sqlite3 data/account.db 'SELECT name, length(salt), substr(hash, 1, 24), role FROM accounts'
ana|16|409147250a1e50b227c1e821|customer
bia|16|09f1fbaae8cb6617cf2e1015|customer
sam|16|a066945e2660c2d0de413a6a|staff
ana@nft:~/boxoffice$ sqlite3 data/account.db 'SELECT substr(token, 1, 24), account FROM sessions'
e07f45fb60fb4966363504ff|2
d9102f314629b2256602253a|3
62c9328612a3135a8b72145b|2
ana@nft:~/boxoffice$ cut -c1-24 ~/bia.token
Ivd5VrccSr9Ce2M53_is6HMw
```

Each account has a salt of 16 random bytes and a hash: scrypt run over the password and the salt.
`ana`, `bia` and `sam` all chose `correct horse battery`, and the three hashes have nothing in
common, **because each salt is different.** Without the salt, two people with the same password
would have the same hash, and one cracked password would open every account that shares it.
scrypt is slow on purpose and uses memory on purpose, so that trying millions of guesses against a
copied table costs real time and real money. `apis` lesson 10 compares it with bcrypt and Argon2,
and how to choose their parameters.

The sessions table holds the SHA-256 of each token, and nothing in it begins `Ivd5Vrcc`, the start
of the token in `~/bia.token`. A plain hash is enough here, where a password needs scrypt, because
a token is 32 random bytes from `secrets` that nobody chose: there is nothing to guess.

## Two wrong answers that look the same

A sign-in form can leak who has an account. If a wrong password says "wrong password" and an
unknown name says "no such user", the form becomes a way to ask whether a particular person is a
customer. Compare the two:

```
ana@nft:~/boxoffice$ curl -s -w ' %{http_code} %{time_total}\n' -X POST localhost:8001/login -d '{"name": "bia", "password": "wrong password"}'
{"error": "wrong name or password"}
 401 0.044698
ana@nft:~/boxoffice$ curl -s -w ' %{http_code} %{time_total}\n' -X POST localhost:8001/login -d '{"name": "nobody", "password": "wrong password"}'
{"error": "wrong name or password"}
 401 0.048837
```

The same status and the same sentence. The times are close too, 0.044698 and 0.048837 seconds,
**because an unknown name is checked against `DECOY`**, a hash nobody has, with the same slow
scrypt a real account gets. Without it the unknown name would come back in a fraction of a
millisecond, and the clock would say what the words do not. Two single requests on a shared machine
are not a measurement; a test that wanted to hold the timing would compare the medians of many.

## Too many guesses

A password guessed online is guessed one sign-in at a time, so the defence is to make the attempts
run out. `account.py` refuses a name for five minutes after five failures within five minutes,
**and then refuses the right password too**, because otherwise the guesser would simply learn
which attempt worked:

```
ana@nft:~/boxoffice$ for i in 1 2 3 4 5; do curl -s -o /dev/null -w '%{http_code} ' -X POST localhost:8001/login -d '{"name": "sam", "password": "a guess"}'; done; echo
401 401 401 401 401 
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' -X POST localhost:8001/login -d '{"name": "sam", "password": "correct horse battery"}'
{"error": "too many attempts, try again in a few minutes"}
429
```

This rate limit is the simplest one that works, and a real one has to answer more questions: a
limit per name lets one person lock out somebody else by guessing badly on purpose, so services
also limit per address, slow down rather than stop, or ask for a second factor once the count
rises. `security-fundamentals` lesson 9 covers multi-factor authentication, which is what makes a
guessed password not enough on its own.

The service's own terminal shows every one of those attempts:

```
ana@nft:~/boxoffice$ python3 account.py
account on http://127.0.0.1:8001
2026-10-10 16:35:38,308 WARNING refused GET /bookings/1 to account 2: no such booking
2026-10-10 16:35:38,364 WARNING refused GET /staff/bookings to account 1: staff only
2026-10-10 16:35:38,786 WARNING failed sign-in for 'bia'
2026-10-10 16:35:38,860 WARNING failed sign-in for 'nobody'
2026-10-10 16:35:38,952 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,004 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,057 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,112 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,160 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,193 WARNING sign-in for 'sam' refused: 5 failures in a row
```

**Every failure has a line, and none of them carries the password that was tried.** A log that
recorded rejected passwords would be a list of near-misses of real ones, kept in a file with far
less protection than the database.
