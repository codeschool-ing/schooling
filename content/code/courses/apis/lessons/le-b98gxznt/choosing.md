---
title: Choosing between them
version: 1
---

**The three are not rivals; each answers a different question about who is calling.** A real API
often takes two of them, as `keys.py` takes all three: people sign in and get tokens, programs get
keys, and Basic is kept, if at all, for scripts and tests.

| | identifies | where it fits | its weakness |
|---|---|---|---|
| **Basic** | a person, by name and password | scripts and internal tools, always over HTTPS | the password travels and is checked on every request, and access ends only when the password changes |
| **bearer token** | a person, after one login | anything a person signs in to: a site, an app | whoever holds it is that person until it expires or is revoked |
| **API key** | an application | one program calling another, unattended | it lives until somebody revokes it, so a leaked one stays useful until somebody notices |

Three questions settle most cases:

1. **Is somebody there?** A person who signs in once and works for an hour wants a token. A program
   that runs at three in the morning wants a key.
2. **Who should the log name?** If the answer is "the partner", it is a key, because a person's
   password in a partner's configuration names the wrong party and leaves with the person.
3. **How fast must access end?** A token ends on its own and on logout; a key ends when it is revoked;
   Basic ends when the password changes, everywhere at once.

What all three need, whatever is chosen, is what the earlier sections in this lesson showed:
HTTPS on the way (lesson 13), a header and never a URL, a hash and never the secret in storage, a
comparison that takes the same time, and a refusal that says nothing.

## Cleaning up

Three files in `~/shelf` hold credentials that are still live, and a lab is a good place to practise
not leaving them about. Log out, revoke the remaining key, and delete the files:

```
ana@api:~/shelf$ curl -s -X POST -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/logout
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 -X DELETE localhost:8000/v1/keys/$(jq -r .prefix partner-new.json)
ana@api:~/shelf$ rm login.json partner.json partner-new.json
ana@api:~/shelf$ ls
__pycache__
db.py
keys.py
rest.py
shelf.db
```

Then stop `keys.py` with `Ctrl+C` in the second terminal. The next lessons start from `rest.py` again,
and the users and the tables `keys.py` added to `shelf.db` sit there unused by it.
