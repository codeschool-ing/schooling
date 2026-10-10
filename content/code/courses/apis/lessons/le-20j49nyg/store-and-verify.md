---
title: x
version: 1
---

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
