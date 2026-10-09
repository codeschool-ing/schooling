---
title: An identifier that identifies nobody outside
version: 2
---

The first identifier that comes to mind is the one the application already has for everybody: the
e-mail address. Sending it would put a piece of personal data in every request, for a purpose the
provider does not need it for, which is exactly what lesson 12's necessity principle forbids. The
second idea is to hash the address first, and **a hash of an e-mail address can be reversed by
anybody who can guess e-mail addresses**.

`guard enduser` computes both kinds of identifier this section compares: the plain hash, with
`--naive`, and the keyed one it ends with. Save it as `~/guard/tools/enduser.py`; the copy button
gives the whole program, and the notes are for when the section reaches each part:

```schooling-example
{"language": "python", "file": "tools/enduser.py", "parts": [
 {"code": "import argparse\nimport hashlib\nimport hmac\nimport os\n", "note": "Three modules from Python's standard library. `hmac` is the one that matters here."},
 {"code": "\n\ndef end_user_id(account, key):\n    digest = hmac.new(key, account.encode(), hashlib.sha256).hexdigest()\n    return \"eu-\" + digest[:20]\n", "note": "The input is Tarefa's internal account id, not the e-mail, so the id survives a change of address. The key is the secret. Twenty hex characters are 80 bits: no two of millions of accounts will collide, and the id still fits on one line of a log."},
 {"code": "\n\ndef naive_id(email):\n    return hashlib.sha256(email.strip().lower().encode()).hexdigest()\n", "note": "The version this section argues against, kept so that `guard reverse` can show it reversed."},
 {"code": "\n\nif __name__ == \"__main__\":\n    p = argparse.ArgumentParser(prog=\"guard enduser\")\n    p.add_argument(\"account\", nargs=\"?\")\n    p.add_argument(\"--provider\", default=\"provider-a\")\n    p.add_argument(\"--naive\")\n    a = p.parse_args()\n    if a.naive:\n        print(naive_id(a.naive))\n    else:\n        with open(os.path.expanduser(\"~/guard/keys/%s.key\" % a.provider), \"rb\") as f:\n            print(end_user_id(a.account, f.read().strip()))\n", "note": "The command: `--naive` prints the plain hash of an address; otherwise it reads the provider's key from `~/guard/keys/` and prints the keyed id of an account."}
]}
```

The keyed identifiers need a key per provider. These two are fixed text, so that your identifiers
match the ones printed here; the end of the section says what a real one is:

```sh
mkdir -p ~/guard/keys
printf 'lab-key-for-provider-a-not-secret-0001\n' > ~/guard/keys/provider-a.key
printf 'lab-key-for-provider-b-not-secret-0002\n' > ~/guard/keys/provider-b.key
```

Two more programs: one writes a guessing list of 400 addresses, and one tries every address on a
list against an identifier. Save them as `~/guard/tools/emails.py` and `~/guard/tools/reverse.py`:

```python
# emails.py: write a guessing list of e-mail addresses, one per line.
#
#   guard emails > FILE
#
# Every first name below with every surname, at one domain: 400 addresses.
# The names are common in Brazil and the addresses invented; example.com.br
# is a domain nobody receives mail at.
FIRST = ["ana", "bruno", "carla", "diego", "elisa", "fernanda", "gustavo", "helena",
         "igor", "juliana", "karina", "lucas", "marcos", "natalia", "otavio", "paula",
         "rafael", "sofia", "tiago", "vitoria"]
LAST = ["almeida", "barros", "costa", "dias", "ferreira", "gomes", "lima", "moreira",
        "nunes", "oliveira", "prado", "ribeiro", "rocha", "santos", "silva", "souza",
        "teixeira", "vieira", "xavier", "zanetti"]
for f in FIRST:
    for s in LAST:
        print("%s.%s@example.com.br" % (f, s))
```

```python
# reverse.py: a dictionary attack on an end-user id, to show which ids resist one.
#
#   guard reverse ID --list FILE
#
# It hashes every address in FILE the way naive_id() does and compares. Exit
# status 0 if it found the address, 1 if not.
import argparse
import sys

from enduser import naive_id

p = argparse.ArgumentParser(prog="guard reverse")
p.add_argument("id")
p.add_argument("--list", required=True)
a = p.parse_args()

with open(a.list, encoding="utf-8") as f:
    guesses = [line.strip() for line in f if line.strip()]
for n, guess in enumerate(guesses, 1):
    if naive_id(guess) == a.id:
        print("found after %d guesses: %s" % (n, guess))
        sys.exit(0)
print("not found in %d guesses" % len(guesses))
sys.exit(1)
```

Now hash one client's address the plain way, and try to get it back:

```
ana@lab:~/guard$ guard emails > data/emails.txt
ana@lab:~/guard$ guard enduser --naive marcos.teixeira@example.com.br
e99036a63befa4e2995bd6ba388d0586cfbc78dd4eb31af863f558d7fd630894
ana@lab:~/guard$ head -3 data/emails.txt; wc -l data/emails.txt
ana.almeida@example.com.br
ana.barros@example.com.br
ana.costa@example.com.br
400 data/emails.txt
ana@lab:~/guard$ guard reverse e99036a63befa4e2995bd6ba388d0586cfbc78dd4eb31af863f558d7fd630894 --list data/emails.txt
found after 257 guesses: marcos.teixeira@example.com.br
```

A SHA-256 cannot be run backwards, and it does not have to be. `guard reverse` hashes every address
on a list and compares, and the list here is only every common first name with every common
surname at one domain. The address was the 257th guess. Real attackers use lists of millions of
addresses from earlier leaks, and a modern computer computes millions of SHA-256 hashes a second. The
hash adds a step, and no secret.

## A keyed hash

The fix is to make the hash depend on something the attacker does not have. An **HMAC** is a hash
computed with a secret key mixed in, so that computing it, and therefore checking a guess, needs the
key. That is `end_user_id` in the program above: one call to `hmac.new`, with the provider's key.

Three runs of it show the properties that matter:

```
ana@lab:~/guard$ guard enduser ac-7Q2M
eu-fe47aa8e7cd5e1b6f8bc
ana@lab:~/guard$ guard enduser ac-9D4H
eu-ac8948151bbc5139ccb1
ana@lab:~/guard$ guard enduser ac-7Q2M --provider provider-b
eu-4805e698e5809587d84d
ana@lab:~/guard$ guard reverse eu-fe47aa8e7cd5e1b6f8bc --list data/emails.txt; echo "exit $?"
not found in 400 guesses
exit 1
```

- **Stable.** `ac-7Q2M` gives `eu-fe47aa8e7cd5e1b6f8bc` on every call, so the provider can see that
  forty bad requests came from one person, and Tarefa can map the identifier back to the account
  by computing it again.
- **Different per provider.** With the key for `provider-b`, the same account becomes
  `eu-4805e698e5809587d84d`. If Tarefa uses two providers and both leak, or both are asked for their
  records, the two sets of identifiers cannot be joined to each other.
- **Not reversible without the key.** The dictionary that found the plain hash finds nothing.

The keys you saved are fixed text, so that these captures print the same identifiers every time. A real key is random, at least 32 bytes, and kept in the same secret store as the API
key itself, never in a file beside the code.

## What the key decides

Two operational consequences follow from the identifier depending on a key.

**Rotating the key changes every identifier.** After a rotation, the provider sees a new set of
users, and any abuse history it attributed to the old identifiers is detached. That is sometimes
what you want, after a key leaked, and usually not. Rotate when the key may be compromised, and
not on a calendar.

**The identifier is still personal data at Tarefa**, by the reasoning of lesson 12: Tarefa holds the
key, so for Tarefa it is pseudonymised. It belongs in the logs of lesson 11 instead of the e-mail. And
once an account is erased, the identifiers the provider holds point at an account that no longer
exists, so they identify nobody, to Tarefa or to anyone else.
