---
title: Where the password went
version: 1
---

**Authentication** answers who is asking; whether they may do what they ask is lesson 12. Every way
of answering it in this lesson starts from a password, so the first question is what the server
keeps of one. Lesson 5 promised the answer. `passwords.py`, run in Django's shell from `~/agenda`:

```python
# passwords.py
import time

from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.models import User

stored = User.objects.get(username="bruno").password
print(stored)

started = time.perf_counter()
print(check_password("m4-orchard-copper-17", stored))
print(check_password("m4-orchard-copper-18", stored))
print(f"{(time.perf_counter() - started) / 2:.2f} s per check")

print(make_password("m4-orchard-copper-17"))
print(make_password("m4-orchard-copper-17"))
```

```
ana@vm:~/agenda$ uv run python manage.py shell -v 0 < passwords.py
pbkdf2_sha256$1500000$ThSmE6yd8BxIxoEfR8ik8s$st1kRGk9p3uHVvw7MhoUatBSCVQ9lzker2DNeaX0v9M=
True
False
0.29 s per check
pbkdf2_sha256$1500000$XGYh6aIiIU2KSIPxVW3AD0$027TmNXqBceQo7xBDBt8WhKlgqQGbd2+Tq040rul+VU=
pbkdf2_sha256$1500000$M3BZbzP1pqT7nrdWUXaJx6$5jVKnqY+kSBVNeDn0Qoq4kFn7kDJjFMY3A2fZ4+XXZg=
```

The first line is what the `auth_user` table holds for Bruno. **It is not his password**, and the
password cannot be computed back from it. It has four fields, separated by `$`:

| field | value | meaning |
|---|---|---|
| algorithm | `pbkdf2_sha256` | how the hash was made |
| iterations | `1500000` | SHA-256 applied one and a half million times |
| salt | `ThSmE6yd8BxIxoEfR8ik8s` | random, different for every hash |
| hash | the rest | the result |

`check_password` hashes what was typed with the same algorithm, iterations and salt, and compares.
**The two last lines hashed the same password twice and got two different strings**: that is the
salt, and it means two people with the same password have different rows, and a table of
precomputed hashes is useless against them.

**And 0.3 seconds per check is on purpose.** A hash for passwords is made slow so that somebody who
steals the table pays that price for every guess, while a person logging in pays it once. A fast hash
such as a single SHA-256 is the wrong tool here for exactly that reason, and storing the password
itself is the wrong tool for every reason.

Django's default is PBKDF2. **Argon2** won the Password Hashing Competition in 2015 and is also
expensive in memory, which makes guessing on graphics cards costly; Django uses it if `argon2-cffi`
is installed and `Argon2PasswordHasher` is first in `PASSWORD_HASHERS`, and agenda-api uses it from
the start later in this lesson. The prefix of each hash says which algorithm made it, so a site can
change the default and keep checking old hashes, upgrading each at the user's next login.
