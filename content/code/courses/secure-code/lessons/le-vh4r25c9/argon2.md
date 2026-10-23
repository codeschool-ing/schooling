---
title: Argon2id, and the same answer for a stranger
version: 1
---

The library is `argon2-cffi`, which wraps the reference implementation of Argon2. Install it in the
course's environment:

```
(.venv) ana@vm:~/sc/passwords$ pip install --progress-bar off argon2-cffi==25.1.0
Collecting argon2-cffi==25.1.0
  Downloading argon2_cffi-25.1.0-py3-none-any.whl.metadata (4.1 kB)
Collecting argon2-cffi-bindings (from argon2-cffi==25.1.0)
  Downloading argon2_cffi_bindings-26.1.0-cp310-abi3-manylinux_2_26_x86_64.manylinux_2_28_x86_64.whl.metadata (7.5 kB)
Collecting cffi>=1.0.1 (from argon2-cffi-bindings->argon2-cffi==25.1.0)
  Downloading cffi-2.1.1-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.whl.metadata (2.5 kB)
Collecting pycparser (from cffi>=1.0.1->argon2-cffi-bindings->argon2-cffi==25.1.0)
  Downloading pycparser-3.12-py3-none-any.whl.metadata (9.7 kB)
Downloading argon2_cffi-25.1.0-py3-none-any.whl (14 kB)
Downloading argon2_cffi_bindings-26.1.0-cp310-abi3-manylinux_2_26_x86_64.manylinux_2_28_x86_64.whl (26 kB)
Downloading cffi-2.1.1-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.whl (221 kB)
Downloading pycparser-3.12-py3-none-any.whl (62 kB)
Installing collected packages: pycparser, cffi, argon2-cffi-bindings, argon2-cffi
Successfully installed argon2-cffi-25.1.0 argon2-cffi-bindings-26.1.0 cffi-2.1.1 pycparser-3.12
```

Before changing the portal, look at what it produces. A hash, verified twice, once with the right
password and once with a wrong one:

```
(.venv) ana@vm:~/sc/passwords$ python3 -c 'from argon2 import PasswordHasher; ph = PasswordHasher(); h = ph.hash("lilac river morning tea"); print(h); print(ph.verify(h, "lilac river morning tea")); ph.verify(h, "lilac river morning coffee")'
$argon2id$v=19$m=65536,t=3,p=4$4HJC9CeSC34a0n2vdU4Flg$QIVRFS2aU3S1j5Has7CprxeqHmlo0ik6m27ampYeSw0
True
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    from argon2 import PasswordHasher; ph = PasswordHasher(); h = ph.hash("lilac river morning tea"); print(h); print(ph.verify(h, "lilac river morning tea")); ph.verify(h, "lilac river morning coffee")
                                                                                                                                                                ~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/argon2/_password_hasher.py", line 258, in verify
    return verify_secret(
        hash, _ensure_bytes(password, self.encoding), hash_type
    )
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/argon2/low_level.py", line 204, in verify_secret
    raise VerifyMismatchError(error_to_str(rv))
argon2.exceptions.VerifyMismatchError: The password does not match the supplied hash
```

The stored value is one string, and it carries everything needed to check a password later:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 140\" role=\"img\" data-fig=\"l11-phc\" aria-label=\"An Argon2id hash in the PHC string format, split into its parts. argon2id is the algorithm. v=19 is the version of Argon2. m=65536 is the memory in KiB, 64 MiB. t=3 is the number of passes over that memory. p=4 is the number of lanes run in parallel. Then the salt, random and different for every hash, and last the hash itself. Everything needed to check a password is in the string.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">$argon2id$v=19$m=65536,t=3,p=4$&lt;salt&gt;$&lt;hash&gt;</text><rect x=\"20\" y=\"60\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"66.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">argon2id</text><text x=\"66.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">algorithm</text><rect x=\"120\" y=\"60\" width=\"62\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"151.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">v=19</text><text x=\"151.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">version</text><rect x=\"190\" y=\"60\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"236.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">m=65536</text><text x=\"236.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memory, KiB</text><rect x=\"290\" y=\"60\" width=\"52\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"316.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">t=3</text><text x=\"316.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passes</text><rect x=\"350\" y=\"60\" width=\"52\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"376.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">p=4</text><text x=\"376.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lanes</text><rect x=\"410\" y=\"60\" width=\"142\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"481.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">salt</text><text x=\"481.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">random, per hash</text><rect x=\"560\" y=\"60\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">hash</text><text x=\"630.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the result</text></svg>", "caption": "The parameters travel with the hash, so the cost can be raised later without breaking a single stored password."}
```

This is the **PHC string format**. Because the algorithm, the parameters and the salt are written
beside each hash, **raising the cost later breaks nothing**: old hashes still verify with the
parameters they were made with, and each is upgraded the next time its owner signs in. A cost
kept as a constant in the code instead means raising it invalidates every password ever stored,
which in practice means nobody ever raises it.

A wrong password is not `False`: it is an exception, `VerifyMismatchError`. The code that checks
passwords catches exactly that one, so a corrupted hash or a bug raises loudly instead of reading
as a wrong password.

### How much slower

```
(.venv) ana@vm:~/sc/passwords$ python3 -m timeit -s 'import hashlib' 'hashlib.sha256(b"lilac river morning tea").hexdigest()'
1000000 loops, best of 5: 380 nsec per loop
(.venv) ana@vm:~/sc/passwords$ python3 -m timeit -s 'from argon2 import PasswordHasher; ph = PasswordHasher()' 'ph.hash("lilac river morning tea")'
5 loops, best of 5: 62 msec per loop
```

The same password, hashed both ways, on the machine that recorded this lesson: 380 nanoseconds
for SHA-256, 62 milliseconds for Argon2id, about 160,000 times as long. Those two lines are the
whole argument of the first section, measured: what is a nuisance for one sign-in
is a wall for somebody trying candidates one after another.

### The same answer for a stranger

The first version answered `404 no such patient` for a name it did not know and `401 wrong
password` for a known name. That turns the sign-in form into a way to ask whether somebody is a
patient of Vereda, which on a physiotherapy portal is a question about their health. **The fix
answers both cases with the same status and the same words.**

Answering the same is half of it. The other half is **taking the same time**. If the portal skipped
the hash for an unknown name, it would answer a stranger in a fraction of a millisecond and a known
patient in tens of milliseconds, and the difference is easy to measure from outside. So an unknown
name is checked against a **decoy**, a hash of a password nobody has, made once at start-up. Both
paths do one Argon2 verification.

### The fix

Replace the SHA-256 with a `PasswordHasher`, check against the decoy when the name is unknown,
rehash when the parameters have moved, and give one answer for both failures:

```
(.venv) ana@vm:~/sc/passwords$ git diff
diff --git a/app.py b/app.py
index 353ae1a..b8ce3c5 100644
--- a/app.py
+++ b/app.py
@@ -1,20 +1,31 @@
 # app.py
-import hashlib
 import secrets
 
+from argon2 import PasswordHasher
+from argon2.exceptions import VerifyMismatchError
 from flask import Flask, abort, jsonify, request
 
 app = Flask(__name__)
 USERS = {}
 SESSIONS = {}
+HASHER = PasswordHasher()
+DECOY = HASHER.hash("a password nobody has")
 
 
 def set_password(name, password):
-    USERS[name] = hashlib.sha256(password.encode()).hexdigest()
+    USERS[name] = HASHER.hash(password)
 
 
 def password_is_right(name, password):
-    return USERS[name] == hashlib.sha256(password.encode()).hexdigest()
+    try:
+        HASHER.verify(USERS.get(name, DECOY), password)
+    except VerifyMismatchError:
+        return False
+    if name not in USERS:
+        return False
+    if HASHER.check_needs_rehash(USERS[name]):
+        set_password(name, password)
+    return True
 
 
 def policy_problem(password):
@@ -39,10 +50,8 @@ def current_patient():
 @app.post("/sign-in")
 def sign_in():
     name = request.form.get("name", "")
-    if name not in USERS:
-        return jsonify(error="no such patient"), 404
     if not password_is_right(name, request.form.get("password", "")):
-        return jsonify(error="wrong password"), 401
+        return jsonify(error="wrong name or password"), 401
     sid = secrets.token_urlsafe(32)
     SESSIONS[sid] = name
     response = jsonify(patient=name)
```

```
(.venv) ana@vm:~/sc/passwords$ pytest -q --tb=no
....FFF.F                                                                [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_password_policy[lilac river morning tea-True] - ...
FAILED test_app.py::test_the_password_policy[Vereda2026!-False] - AssertionEr...
FAILED test_app.py::test_the_password_policy[Vereda@2026Vereda!-False] - Asse...
FAILED test_app.py::test_changing_the_password_ends_the_other_sessions - asse...
4 failed, 5 passed in 1.32s
(.venv) ana@vm:~/sc/passwords$ git commit -qam "Store passwords with Argon2id, and answer a stranger as a wrong password"
```

**Three fewer failures**: the two about storage and the one about the answer. `check_needs_rehash`
does not show in a test yet, because every hash here was made with today's parameters. It is the line
that lets you raise them next year.

### And bcrypt

bcrypt is older, everywhere, and still a sound choice. Two things about it are worth knowing before
you meet it in another codebase. Its cost is one number, the logarithm of the work: `12` means
2¹² rounds. And **it reads only the first 72 bytes of a password**. Older versions of the Python
package quietly ignored the rest; version 5.0.0 refuses:

```
(.venv) ana@vm:~/sc/passwords$ pip install --progress-bar off bcrypt==5.0.0
Collecting bcrypt==5.0.0
  Downloading bcrypt-5.0.0-cp39-abi3-manylinux_2_34_x86_64.whl.metadata (10 kB)
Downloading bcrypt-5.0.0-cp39-abi3-manylinux_2_34_x86_64.whl (278 kB)
Installing collected packages: bcrypt
Successfully installed bcrypt-5.0.0
(.venv) ana@vm:~/sc/passwords$ python3 -c 'import bcrypt; print(bcrypt.hashpw(b"lilac river morning tea", bcrypt.gensalt())); bcrypt.hashpw(b"x" * 73, bcrypt.gensalt())'
b'$2b$12$FkXAJ8bOJ45R2gCB0i3GoOltQRUuksGObKznc0RuJ5.qP90AYWiJ2'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import bcrypt; print(bcrypt.hashpw(b"lilac river morning tea", bcrypt.gensalt())); bcrypt.hashpw(b"x" * 73, bcrypt.gensalt())
                                                                                       ~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
ValueError: password cannot be longer than 72 bytes, truncate manually if necessary (e.g. my_password[:72])
```

Seventy-two bytes is fewer characters than it sounds when a passphrase has accents, because `ç` and
`ã` take two bytes each in UTF-8. Argon2 has no such limit, which is one reason this lesson uses it.
