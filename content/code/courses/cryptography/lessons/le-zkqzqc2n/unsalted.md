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

Vereda's portal has eight staff accounts, and this lesson's first file is them with the passwords
their owners chose. The course wrote them to be bad in the usual ways; nobody uses them for anything.
The same commands make the **pepper** that section 05 uses, 32 bytes from `vcrypt derive`:

```sh
cd ~/lab
cat > data/users.csv <<'EOF'
user,password
ana.lima,Vereda@2026
bruno.reis,fisio123
carla.souza,Vereda@2026
diego.alves,correct horse battery staple
elisa.prado,fisio123
fabio.nunes,Vereda@2026
gabi.torres,m4r3-alta-em-ub@tub@
hugo.matos,Primavera#2026
EOF
vcrypt derive pepper 32 > keys/pepper.hex
```

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

## Five ways to store them

Every scheme in this lesson is one function in one file, from the worst to the one to use. Only the
first, `sha256`, matters for this section; the others are the subject of the next three, and each
section points back at the lines it uses:

```py
# ~/lab/tools/passwords.py
"""Five ways to store a password, from the worst to the one to use, and the
check that goes with each. Every salt here comes from drbg.py so that your
stores match the lesson's; a real system draws each salt from os.urandom at
the moment it stores the password."""
import base64
import hashlib
import hmac

import bcrypt
from cryptography.hazmat.primitives.kdf.argon2 import Argon2id

import drbg

POLICY = {"pbkdf2": 600_000, "bcrypt": 12, "argon2id": (19456, 2, 1)}
BCRYPT_ALPHABET = "./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"


def b64(b):
    return base64.b64encode(b).decode().rstrip("=")


def unb64(s):
    return base64.b64decode(s + "=" * (-len(s) % 4))


def salt(scheme, user):
    return drbg.stream(f"salt/{scheme}/{user}", 16)


def peppered(password, pepper):
    """With a pepper, the password is first run through an HMAC under it."""
    if pepper is None:
        return password.encode()
    return hmac.new(pepper, password.encode(), hashlib.sha256).hexdigest().encode()


def store(scheme, user, password, pepper=None, cost=None):
    pw = peppered(password, pepper)
    if scheme == "sha256":
        return hashlib.sha256(pw).hexdigest()
    if scheme == "salted-sha256":
        s = salt(scheme, user)
        return f"sha256${b64(s)}${hashlib.sha256(s + pw).hexdigest()}"
    if scheme == "pbkdf2":
        n, s = cost or POLICY["pbkdf2"], salt(scheme, user)
        return f"pbkdf2-sha256${n}${b64(s)}${b64(hashlib.pbkdf2_hmac('sha256', pw, s, n))}"
    if scheme == "bcrypt":
        c = cost or POLICY["bcrypt"]
        raw = drbg.stream(f"salt/bcrypt/{user}", 22)
        s = "".join(BCRYPT_ALPHABET[x % 64] for x in raw[:21]) + "u"
        return bcrypt.hashpw(pw, f"$2b${c:02d}${s}".encode()).decode()
    if scheme == "argon2id":
        m, t, p = cost or POLICY["argon2id"]
        return Argon2id(salt=salt(scheme, user), length=32, iterations=t, lanes=p,
                        memory_cost=m).derive_phc_encoded(pw)
    raise ValueError(scheme)


def verify(stored, password, pepper=None):
    """(the password is right, why the stored value needs redoing or None)"""
    pw = peppered(password, pepper)
    if stored.startswith("$argon2id$"):
        try:
            Argon2id.verify_phc_encoded(pw, stored)
            ok = True
        except Exception:  # the library's answer to a wrong password
            ok = False
        params = dict(kv.split("=") for kv in stored.split("$")[3].split(","))
        m, t, p = POLICY["argon2id"]
        weak = int(params["m"]) < m or int(params["t"]) < t
        return ok, (f"stored m={params['m']},t={params['t']} is below the policy m={m},t={t}" if weak else None)
    if stored.startswith("$2b$"):
        c = int(stored.split("$")[2])
        return bcrypt.checkpw(pw, stored.encode()), (
            f"stored cost {c} is below the policy {POLICY['bcrypt']}" if c < POLICY["bcrypt"] else None)
    if stored.startswith("pbkdf2-sha256$"):
        _, n, s, h = stored.split("$")
        ok = hmac.compare_digest(b64(hashlib.pbkdf2_hmac("sha256", pw, unb64(s), int(n))), h)
        return ok, (f"stored {n} iterations is below the policy {POLICY['pbkdf2']}"
                    if int(n) < POLICY["pbkdf2"] else None)
    if stored.startswith("sha256$"):
        _, s, h = stored.split("$")
        return hmac.compare_digest(hashlib.sha256(unb64(s) + pw).hexdigest(), h), "a fast hash is below every policy"
    return hmac.compare_digest(hashlib.sha256(pw).hexdigest(), stored), "a fast hash is below every policy"
```

`vcrypt store` runs one of those schemes over every account in the file, and prints what a system
would keep:

```py
# ~/lab/tools/store.py
"""vcrypt store SCHEME USERS.csv [--pepper KEYFILE] [--cost C]: print one line
user:stored-value for every account, stored with SCHEME (sha256,
salted-sha256, pbkdf2, bcrypt or argon2id). --cost is the iterations for
pbkdf2, the cost for bcrypt, and m,t,p for argon2id."""
import argparse

import passwords

p = argparse.ArgumentParser(prog="vcrypt store")
p.add_argument("scheme", choices=("sha256", "salted-sha256", "pbkdf2", "bcrypt", "argon2id"))
p.add_argument("users")
p.add_argument("--pepper")
p.add_argument("--cost")
a = p.parse_args()

pepper = bytes.fromhex(open(a.pepper).read().strip()) if a.pepper else None
cost = None
if a.cost:
    cost = tuple(int(x) for x in a.cost.split(",")) if a.scheme == "argon2id" else int(a.cost)
for line in open(a.users):
    user, password = line.rstrip("\n").split(",", 1)
    if user != "user":  # the header line
        print(f"{user}:{passwords.store(a.scheme, user, password, pepper, cost)}")
```

## Problem one: equal passwords are visible

Stored as plain SHA-256, one value per account:

```
ana@lab:~/lab$ vcrypt store sha256 data/users.csv > store-sha256.txt; head -3 store-sha256.txt
ana.lima:9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21
bruno.reis:3bec5774e1c543e4f58b467da1a227fe3b4c20d9138a43d5735ae73fb1b5d698
carla.souza:9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21
```

Ana and Carla have the same stored value, and so does Fábio further down. An audit that reads only
the store, as anybody who copied it could, says so in one line. This is all of it:

```py
# ~/lab/tools/audit.py
"""vcrypt audit STORE: how many accounts share one stored value. It reads
only the store, as anybody who copied it could."""
import sys

groups = {}
for line in open(sys.argv[1]):
    user, stored = line.rstrip("\n").split(":", 1)
    groups.setdefault(stored, []).append(user)
shared = [users for users in groups.values() if len(users) > 1]
print(f"{sum(len(u) for u in groups.values())} accounts, {len(groups)} different stored values")
for users in shared:
    print(f"  {len(users)} accounts share one value: {', '.join(users)}")
if not shared:
    print("  no two accounts share a stored value")
```


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
