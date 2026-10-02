---
title: A package that does not exist
version: 1
---

A model writes the names of libraries the way it writes everything else: **the name that fits the
sentence, whether or not anybody published it**. Most of the time the name is real. Sometimes it is
plausible and invented, and the next step a developer takes is `pip install`.

This lesson is about what goes wrong when a model's output reaches the real world, and about what
stops it. Every mistake the model makes here was written by the course, as rules in `scripted-1`, to
show what the defences have to withstand. The defences are real.

## An answer that names a package

```
ana@dev:~/shop$ python ask.py "Which library gives me a money type for the cart?"
Use the cartmoney package, which handles cents and rounding for you:

    pip install cartmoney

Then `from cartmoney import Money` and write `Money("39.90")` wherever the cart holds a price.
```

The answer reads well: a name that says what it does, an install command, an import, an example.
**Nothing in it says whether `cartmoney` exists.** Checking takes one request to the index, which
reads and installs nothing:

```python
"""Look a package name up on PyPI before anyone installs it. Reads only; installs nothing."""
import json
import sys
import urllib.error
import urllib.request

name = sys.argv[1]
try:
    with urllib.request.urlopen(f"https://pypi.org/pypi/{name}/json") as r:
        info = json.load(r)
except urllib.error.HTTPError as e:
    if e.code != 404:
        raise
    print(f"{name}: not on PyPI. Do not install it, and do not register it to make the error go away.")
    sys.exit(1)
uploads = [f["upload_time"] for files in info["releases"].values() for f in files]
print(f"{name}: on PyPI since {min(uploads)[:10]}, \"{info['info']['summary']}\"")
```

```
ana@dev:~/shop$ python check_package.py cartmoney
cartmoney: not on PyPI. Do not install it, and do not register it to make the error go away.
ana@dev:~/shop$ python check_package.py requests
requests: on PyPI since 2011-02-14, "Python HTTP for Humans."
```

**`cartmoney` is not on PyPI**, at least not on the day this was recorded. `requests` is, and has
been since 2011, which is the second thing worth knowing about a package before trusting it.

## Why an invented name is a risk and not only an error

An install that fails is an inconvenience. The danger is the day it succeeds: **anyone can register
an unused name on a public index**, and a name that models suggest repeatedly is a name somebody
can register and fill with code of their own. The developer who copies the install command then
runs that code, with their own permissions, on their own machine.

So the check that matters is not "does it install". It is **"is this the package I meant, and do
I trust who publishes it"**:

- **Look the name up before installing**, as above, and read what you find: who publishes it, since
  when, how many people depend on it, where its source lives.
- **Prefer what the project already depends on.** The shop already has a rule for money, integer
  cents, from lesson 1; a new dependency for it is a new risk for nothing.
- **Pin and lock what you install**, so a name that changes hands later does not change your build
  without a diff somebody reads.
- **Never register a name a model invented** to make an error go away. It turns a mistake into a
  package somebody else will install.
