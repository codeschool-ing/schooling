---
title: A key is money
version: 1
---

Every API in lessons 6 to 20 asked for the same thing before it answered: a key. **Whoever holds
the key spends the money**, and nothing in the request says who that is. A key is not a password
that protects ana's data; it is a card number that charges ana's account.

Lesson 1 section 04 put the course's keys where a program finds them and a file of code does not:
in the environment, loaded from `desk.env`. They are placeholders, because Ollama ignores the key:

```
ana@desk:~/desk$ grep -E "_KEY|_TOKEN" desk.env
export OPENAI_API_KEY=ollama
export ANTHROPIC_API_KEY=ollama
```

A real key goes in the same kind of place, and a week of real work leaves keys in other places
too. To see what that looks like, make the two files such a week might leave behind: a note pasted
while debugging, `notes.txt`:

```
2026-09-30 OpenRouter test - works with the key below, move it to the env file later
  sk-or-v1-example-0001
```

and the start of a support widget for the shop's website, `page/widget.js`, which sorts a
customer's message in the browser:

```javascript
// Sort the customer's message in the browser before it is sent to us.
const OPENROUTER_KEY = "sk-or-v1-example-0001";
export async function sortMessage(text) {
  const r = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: { Authorization: `Bearer ${OPENROUTER_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: "meta-llama/llama-3.3-70b-instruct", messages: [{ role: "user", content: text }] }),
  });
  return (await r.json()).choices[0].message.content;
}
```

The key in them is made up, and shaped like OpenRouter's. `keyscan.py` looks for anything shaped
like the keys this course has used, and prints only the start of what it finds:

```python
import pathlib
import re

# the shapes of the keys this course has used: OpenRouter's sk-or-, Anthropic's sk-ant-, OpenAI's sk-,
# Hugging Face's hf_
SHAPES = re.compile(r"\b(sk-or-[\w-]{6,}|sk-ant-[\w-]{6,}|sk-[\w-]{16,}|hf_\w{8,})")
for path in sorted(pathlib.Path(".").rglob("*")):
    if not path.is_file() or ".venv" in path.parts or "node_modules" in path.parts:
        continue
    for n, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
        for key in SHAPES.findall(line):
            print(f"{path}:{n}: {key[:6]}{'*' * (len(key) - 6)}")
```

```
ana@desk:~/desk$ python keyscan.py
notes.txt:2: sk-or-***************
page/widget.js:2: sk-or-***************
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
- **Logs print the start of a key, never the whole.** The scan masks what it finds, and the relay
  printed `ollama…` in lesson 17 for the same reason.
