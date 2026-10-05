---
title: A key is money
version: 1
---

Every API in lessons 6 to 20 asked for the same thing before it answered: a key. **Whoever holds
the key spends the money**, and nothing in the request says who that is. A key is not a password
that protects ana's data; it is a card number that charges her account.

The lab keeps its keys where a program finds them and a file does not: in the environment, loaded
from one file outside the project. Its names, without their values:

```
ana@desk:~/desk$ grep -oE "^[A-Z_]+(KEY|TOKEN)=" /etc/aimodels.env
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GEMINI_API_KEY=
MISTRAL_API_KEY=
CO_API_KEY=
HF_TOKEN=
OPENROUTER_API_KEY=
```

A week of real work leaves keys in other places. ana pasted one into a note while debugging, and
started a support widget for the shop's website that sorts a customer's message in the browser.
`lab/keyscan.py` looks for anything shaped like the keys this course has used:

```python
import pathlib
import re

# the shapes of the keys this course has used: OpenRouter's sk-or-, Hugging Face's hf_, the lab's own
SHAPES = re.compile(r"\b(sk-or-[\w-]{6,}|sk-[\w-]{16,}|hf_\w{8,}|lab-[a-z]+-key-\d+)")
for path in sorted(pathlib.Path(".").rglob("*")):
    if not path.is_file() or "node_modules" in path.parts:
        continue
    for n, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
        for key in SHAPES.findall(line):
            print(f"{path}:{n}: {key[:6]}{'*' * (len(key) - 6)}")
```

```
ana@desk:~/desk$ python lab/keyscan.py
notes.txt:2: sk-or-************
page/widget.js:2: sk-or-************
```

Two findings, and the second is the serious one. `page/widget.js` is meant to be served to every
visitor of the shop's website: **a key in a page is a key published**, readable by anybody who opens
the browser's developer tools, and spendable from anywhere. Lesson 13's model ran in the page
because it needed no key; a model behind an API does, so the call belongs on a server ana controls,
and the page talks to that.

The rules that follow cost nothing to keep:

- **The environment, not the code.** A key in a file reaches every copy of the file: a commit, a
  backup, a pasted snippet. The scan above is worth running before every commit; secret scanners in
  code hosts do the same on push.
- **One key per program and per place it runs.** Sorting and drafting, test and production, each
  with its own. A key that leaks can then be revoked alone, and the provider's usage page says which
  program spent what.
- **Revoke, then replace.** A key that appeared somewhere it should not is revoked at the provider
  at once, before anybody works out whether it was used. Deleting the file does not un-publish it.
- **Logs print the start of a key, never the whole.** The scan masks what it finds, and the lab's
  `wire` printed `lab-anthropi…` in lesson 17 for the same reason.
