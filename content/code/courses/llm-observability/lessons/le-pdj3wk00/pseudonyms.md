---
title: A name for the user that is not their id
version: 1
---

Lessons 3 and 5 count per user: the heaviest users, the people who gave a thumbs down twice. That
needs the same value on every request from one person. It does not need to be their account id, and
it should not be, because the account id leads anywhere the account does.

The usual answer is a **pseudonym**: a value derived from the id, the same every time, from which the
id cannot be read. The obvious way to derive it, a hash, does not work:

```python
"""pseudo.py: why a user id is hashed with a key, and never without one."""
import hashlib
import time

import redact

guesses = [f"u{i:03d}" for i in range(1000)]          # the shape anyone can see the ids have
unkeyed = hashlib.sha256(b"u021").hexdigest()[:16]
t = time.perf_counter()
back = [g for g in guesses if hashlib.sha256(g.encode()).hexdigest()[:16] == unkeyed]
print(f"unkeyed {unkeyed}: {len(guesses)} guesses in {(time.perf_counter() - t) * 1000:.1f} ms find {back}")
keyed = redact.pseudonym("u021")
back = [g for g in guesses if hashlib.sha256(g.encode()).hexdigest()[:16] == keyed]
print(f"keyed   {keyed}: the same {len(guesses)} guesses find {back}")
```

```
ana@lab:~/obs$ python pseudo.py
unkeyed cc5487e17071feac: 1000 guesses in 0.5 ms find ['u021']
keyed   d6aad8d0fb204820: the same 1000 guesses find []
```

**A hash of something guessable is the thing itself, with one step in between.** User ids have a
shape, `u` and three digits here, an e-mail address or a sequential number elsewhere, and anyone with
the trace can hash every candidate and compare. A thousand guesses took less than a millisecond.
E-mail addresses take longer and fall the same way, because the guessing works from lists of real
addresses.

`redact.pseudonym()` uses **HMAC**: a hash mixed with a secret key. Without the key, guessing gets
nowhere, as the second line shows; with it, the same user always gets the same value, so counting per
user still works. The key lives with the application's other secrets, never in the trace store and
never in the code.

## What the key buys, and what it does not

The pseudonym can be reversed by whoever holds the key, by hashing every user id until one matches,
so in the LGPD's terms this is still personal data: **pseudonymised, not anonymised**. Treat the trace
store accordingly. What the key does buy is that the people who read traces, and anyone who gets a
copy of them, cannot go from a row to a person without asking someone who has the key.

It also buys an exit. **Throw the key away, and every pseudonym already written becomes
meaningless**, which is how old traces can be cut loose from the people in them without rewriting a
single span. Rotate it every month, and each month's pseudonyms join among themselves and not with
the next month's: per-user counts within a month still work, and a person cannot be followed across
a year. Whether that is the right trade depends on what the counts are for; the point is that it is a
setting, decided once, rather than a property of every trace ever written.

And no key, no pseudonym:

```
ana@lab:~/obs$ PSEUDONYM_KEY= python assistant.py --user u021 "How long is a gift card valid?"
Traceback (most recent call last):
  File "/home/ana/obs/assistant.py", line 149, in <module>
    reply, sources, trace_id = ask(a.question, user=a.user, feature=a.feature)
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/obs/assistant.py", line 115, in ask
    "user.hash": redact.pseudonym(user), "session.id": session or "",
                 ^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/obs/redact.py", line 38, in pseudonym
    raise RuntimeError("PSEUDONYM_KEY is not set: refusing to record a user id unkeyed")
RuntimeError: PSEUDONYM_KEY is not set: refusing to record a user id unkeyed
```

The function refuses rather than fall back to an unkeyed hash. A fallback here would work, pass every
test that does not look at the values, and write a reversible id onto every span from that moment
on, silently. A request that fails loudly is the better outcome.
