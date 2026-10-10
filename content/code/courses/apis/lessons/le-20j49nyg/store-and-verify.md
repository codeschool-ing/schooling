---
title: Accounts for the shelf
version: 1
---

**The shelf gets a `users` table with one column for the hash and none for the password, and two
commands: one to register, one to log in.** Logging in also does the thing the last section asked
for: when the parameters in the code have changed since a hash was made, it replaces that hash while
the correct password is in hand.

Save it as `~/shelf/passwords.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/passwords.py",
  "parts": [
    {
      "code": "# shelf/passwords.py\n\"\"\"The bookshop's accounts: a password is stored as an Argon2id hash and checked at login.\n\n    python3 passwords.py register NAME    asks for a password and stores its hash\n    python3 passwords.py login NAME       asks for a password and checks it\n\"\"\"\nimport getpass\nimport secrets\nimport sqlite3\nimport sys\n\nfrom argon2 import PasswordHasher\nfrom argon2.exceptions import VerifyMismatchError\n\nimport db",
      "note": "The standard library, `argon2` from `python3-argon2`, and lesson 1's `db.py`, so the accounts live in the same `shelf.db` as the books."
    },
    {
      "code": "\nHASHER = PasswordHasher(memory_cost=19456, time_cost=2, parallelism=1)\nDECOY = HASHER.hash(secrets.token_urlsafe(16))\nSHORTEST = 15",
      "note": "`HASHER` holds the parameters, OWASP's minimum for Argon2id, in the one place an edit changes them. `DECOY` is the hash of a random string nobody knows, made once when the program starts. `SHORTEST` is NIST's minimum length for a password that is the only factor."
    },
    {
      "code": "\n\ndef accounts():\n    conn = db.connect()\n    conn.execute(\"CREATE TABLE IF NOT EXISTS users (\"\n                 \" id INTEGER PRIMARY KEY,\"\n                 \" name TEXT NOT NULL UNIQUE,\"\n                 \" password_hash TEXT NOT NULL)\")\n    return conn",
      "note": "The table has a column for the hash and none for the password. `CREATE TABLE IF NOT EXISTS` adds it to `shelf.db` the first time and leaves `db.py` as it was."
    },
    {
      "code": "\n\ndef register(name, password):\n    if len(password) < SHORTEST:\n        raise ValueError(f\"a password needs at least {SHORTEST} characters\")\n    with accounts() as conn:\n        conn.execute(\"INSERT INTO users (name, password_hash) VALUES (?, ?)\",\n                     (name, HASHER.hash(password)))",
      "note": "`HASHER.hash` draws a fresh 16-byte salt and returns one string holding the algorithm, the parameters, the salt and the hash. That string is all the row keeps."
    },
    {
      "code": "\n\ndef login(name, password):\n    \"\"\"True if the password is right, with the same work whether or not the name exists.\"\"\"\n    with accounts() as conn:\n        row = conn.execute(\"SELECT id, password_hash FROM users WHERE name = ?\",\n                           (name,)).fetchone()\n        stored = row[\"password_hash\"] if row else DECOY\n        try:\n            HASHER.verify(stored, password)\n        except VerifyMismatchError:\n            return False\n        if row is None:\n            return False\n        if HASHER.check_needs_rehash(stored):\n            conn.execute(\"UPDATE users SET password_hash = ? WHERE id = ?\",\n                         (HASHER.hash(password), row[\"id\"]))\n        return True",
      "note": "A name that does not exist is checked against `DECOY`, so it costs the same hash as a wrong password. `verify` reads the parameters out of the stored string, not out of `HASHER`, which is why an old hash still verifies after they change. `check_needs_rehash` compares the two, and a hash made with old parameters is replaced while the password is in hand."
    },
    {
      "code": "\n\ndef ask():\n    \"\"\"Typed without echo at a terminal; one line when it comes through a pipe.\"\"\"\n    if sys.stdin.isatty():\n        return getpass.getpass(\"password: \")\n    return sys.stdin.readline().rstrip(\"\\n\")",
      "note": "At a terminal the password is typed without echo. Through a pipe, as in the transcripts below, it is one line of standard input. It is never an argument, because the arguments of a running command are visible to every user of the machine."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    if len(sys.argv) != 3 or sys.argv[1] not in (\"register\", \"login\"):\n        sys.exit(__doc__)\n    command, name = sys.argv[1:]\n    password = ask()\n    if command == \"register\":\n        try:\n            register(name, password)\n        except (ValueError, sqlite3.IntegrityError) as e:\n            sys.exit(f\"not registered: {e}\")\n        print(f\"registered {name}\")\n    elif login(name, password):\n        print(f\"welcome, {name}\")\n    else:\n        sys.exit(\"wrong name or password\")",
      "note": "Two commands. A wrong name and a wrong password get the same sentence, for the reason the last section of this lesson gives."
    }
  ]
}
```

Each command asks for the password. At a terminal you type it and nothing is shown. In the
transcripts below it arrives through a pipe from `echo`, so that you can see what was sent. Doing the
same yourself leaves the password in your shell's history, which is fine for a password made up for
this lesson and for nothing else.

The directory holds lesson 1's two files and this lesson's two, and `shelf.db` as well if you ran
`rest.py` before:

```
ana@api:~/shelf$ ls
db.py
hashrate.py
passwords.py
rest.py
```

A password that is too short is refused before anything is hashed. Then Ana registers, and a second
registration under the same name is refused by the table's `UNIQUE`:

```
ana@api:~/shelf$ echo 'sunshine' | python3 passwords.py register ana
not registered: a password needs at least 15 characters
ana@api:~/shelf$ echo 'correct horse battery staple' | python3 passwords.py register ana
registered ana
ana@api:~/shelf$ echo 'correct horse battery staple' | python3 passwords.py register ana
not registered: UNIQUE constraint failed: users.name
```

Logging in with the right password, and with one that differs in its last letter:

```
ana@api:~/shelf$ echo 'correct horse battery staple' | python3 passwords.py login ana
welcome, ana
ana@api:~/shelf$ echo 'correct horse battery stapler' | python3 passwords.py login ana
wrong name or password
```

And the row itself. This is everything a leak of `shelf.db` would show about Ana's password:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM users'
1|ana|$argon2id$v=19$m=19456,t=2,p=1$rZXEcBow2YskINKytiXaLg$uqN7XiHe8l1STpFKzRYDTg
```

## Changing the parameters

Say the measurement of the last section convinced you to give each login 46 MiB instead of 19. The
change is one number in `HASHER`:

```
ana@api:~/shelf$ sed -i 's/memory_cost=19456/memory_cost=47104/' passwords.py && grep -n 'HASHER =' passwords.py
17:HASHER = PasswordHasher(memory_cost=47104, time_cost=2, parallelism=1)
```

Nothing else changes, and nobody is locked out. Ana logs in as before, and the row is different
afterwards:

```
ana@api:~/shelf$ echo 'correct horse battery staple' | python3 passwords.py login ana
welcome, ana
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM users'
1|ana|$argon2id$v=19$m=47104,t=2,p=1$HqHQJDbw//7YwobzMSn2sg$wpRteeWTjxZbETvb019qAA
```

`verify` checked her password against the old string, using the parameters written in it, `m=19456`.
It matched, so `check_needs_rehash` compared those with `HASHER`'s, found `m=47104` there, and
`login` stored a new hash, with a new salt, while it still had the password. Nobody else's row moved,
and nobody else's will until they log in.

**That is the weakness of upgrading on login: an account nobody uses keeps its old hash forever.**
OWASP's sheet names the remedy for when that matters, such as after moving away from a weak scheme:
after a while, remove the old hashes and ask those users to set a new password.

From here on, the rest of this lesson uses the edited `passwords.py`, at `m=47104`.
