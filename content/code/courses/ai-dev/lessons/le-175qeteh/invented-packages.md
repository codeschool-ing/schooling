---
title: A package that does not exist
version: 2
---

A model writes the names of libraries the way it writes everything else: **the name that fits the
sentence, whether or not anybody published it**. Most of the time the name is real. Sometimes it is
plausible and invented, and the next step a developer takes is `pip install`.

This lesson is about what goes wrong when a model's output reaches the real world, and about what
stops it. Every mistake in it is `llama3.2:3b`'s, made on the recording machine; none was arranged.

## An answer that names a package

`ask.py` is the smallest program that asks the model anything, at temperature 0:

```python
import sys

import anthropic

r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=300, extra_body={"temperature": 0},
                                          messages=[{"role": "user", "content": sys.argv[1]}])
print(r.content[0].text)
```

The reply has a block of code in it, so it goes to a file and `cat -n` shows it with its lines
numbered:

```
ana@dev:~/shop$ python ask.py "Which Python library gives me a money type for the cart? Name one and the pip command to install it." > reply.txt; cat -n reply.txt
     1	One popular Python library for working with money is `pymoney`. It provides a `Money` class that allows you to perform arithmetic operations on monetary values.
     2	
     3	To install `pymoney`, you can use the following pip command:
     4	
     5	```bash
     6	pip install pymoney
     7	```
     8	
     9	This library is well-maintained and widely used, making it a great choice for working with money in Python.
```

The answer reads well: a name that says what it does, an install command, and a reassurance, *well
maintained and widely used*. **Nothing in it says whether any of that is true.** Checking takes one
request to the index, which reads and installs nothing:

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
uploads = sorted(f["upload_time"] for files in info["releases"].values() for f in files)
print(f"{name}: on PyPI, first release {uploads[0][:10]}, last {uploads[-1][:10]}, \"{info['info']['summary']}\"")
```

```
ana@dev:~/shop$ python check_package.py pymoney
pymoney: on PyPI, first release 2011-03-05, last 2011-03-05, "An implementation of a money type for Python 2.2 >"
ana@dev:~/shop$ python check_package.py money
money: on PyPI, first release 2013-11-16, last 2016-04-17, "Python Money Class"
ana@dev:~/shop$ python check_package.py cartmoney
cartmoney: not on PyPI. Do not install it, and do not register it to make the error go away.
```

**`pymoney` exists, and it is the wrong package.** One release, on 5 March 2011, for Python 2.2,
and nothing since: the "well maintained" in the reply is the model's, and the index says the
opposite. `money` is a little better and stopped in 2016. Neither was invented, and the check found
the problem anyway, because it reads dates and a description where the reply had adjectives.

`cartmoney` is the other answer the check gives, for a name ana typed to see it: **not on PyPI**, at
least not on the day this was recorded. A model asked a question like this one sometimes writes a
name of that kind, plausible and invented, and the next step a developer takes is `pip install`.

## Why an invented name is a risk and not only an error

An install that fails is an inconvenience. The danger is the day it succeeds: **anyone can register
an unused name on a public index**, and a name that models suggest repeatedly is a name somebody
can register and fill with code of their own. The developer who copies the install command then
runs that code, with their own permissions, on their own machine.

So the check that matters is not "does it install". It is **"is this the package I meant, and do
I trust who publishes it"**:

- **Look the name up before installing**, as above, and read what you find: who publishes it, since
  when, when it last changed, how many people depend on it, where its source lives.
- **Prefer what the project already depends on.** The shop already has a rule for money, integer
  cents, from lesson 1; a new dependency for it is a new risk for nothing.
- **Pin and lock what you install**, so a name that changes hands later does not change your build
  without a diff somebody reads.
- **Never register a name a model invented** to make an error go away. It turns a mistake into a
  package somebody else will install.
