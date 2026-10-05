---
title: An identifier that identifies nobody outside
version: 1
---

The first identifier that comes to mind is the one the application already has for everybody: the
e-mail address. Sending it would put a piece of personal data in every request, for a purpose the
provider does not need it for, which is exactly what lesson 22's necessity principle forbids. The
second idea is to hash the address first, and **a hash of an e-mail address can be reversed by
anybody who can guess e-mail addresses**:

```
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
key. The lab's version is ten lines:

```schooling-example
{"language": "python", "file": "guardlab/enduser.py", "parts": [
 {"code": "import hashlib\nimport hmac\n", "note": "Both modules are in Python's standard library. `hmac` is the one that matters here."},
 {"code": "\n\ndef end_user_id(account, key):\n    digest = hmac.new(key, account.encode(), hashlib.sha256).hexdigest()\n    return \"eu-\" + digest[:20]\n", "note": "The input is Tarefa's internal account id, not the e-mail, so the id survives a change of address. The key is the secret. Twenty hex characters are 80 bits: no two of millions of accounts will collide, and the id still fits on one line of a log."},
 {"code": "\n\ndef naive_id(email):\n    return hashlib.sha256(email.strip().lower().encode()).hexdigest()\n", "note": "The version this section argues against, kept so that the lab can reverse it."}
]}
```

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

The keys in the lab are fixed text in `keys/`, so that these captures print the same identifiers
every time. A real key is random, at least 32 bytes, and kept in the same secret store as the API
key itself, never in a file beside the code.

## What the key decides

Two operational consequences follow from the identifier depending on a key.

**Rotating the key changes every identifier.** After a rotation, the provider sees a new set of
users, and any abuse history it attributed to the old identifiers is detached. That is sometimes
what you want, after a key leaked, and usually not. Rotate when the key may be compromised, and
not on a calendar.

**The identifier is still personal data at Tarefa**, by the reasoning of lesson 22: Tarefa holds the
key, so for Tarefa it is pseudonymised. It belongs in the logs of lesson 21 instead of the e-mail. And
once an account is erased, the identifiers the provider holds point at an account that no longer
exists, so they identify nobody, to Tarefa or to anyone else.
