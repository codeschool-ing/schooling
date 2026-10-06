---
title: Taking it out before it is written
version: 1
---

The safest place to remove something is **before it is recorded at all**: once a value is on a span,
it is in memory, in an export queue, and then in every place the span is copied to. So the assistant
never puts a customer's words on a span directly. It passes them through `redact()` first, from
`redact.py`:

```schooling-example
{
  "language": "python",
  "file": "redact.py",
  "parts": [
    {
      "code": "import hashlib\nimport hmac\nimport os\nimport re\n\nPATTERNS = [\n    (\"email\", re.compile(r\"[\\w.+-]+@[\\w-]+(?:\\.[\\w-]+)+\")),\n    (\"phone\", re.compile(r\"\\+\\d{1,3}(?:[\\s-]?\\d){8,12}\")),\n    (\"card\", re.compile(r\"\\b(?:\\d[ -]?){13,19}\\b\")),\n    (\"order\", re.compile(r\"\\bMG-\\d{8}\\b\")),\n]",
      "note": "Four patterns, each with the name that replaces it. Their order matters: an e-mail address is taken out before anything inside it can look like a number."
    },
    {
      "code": "def redact(text):\n    \"\"\"TEXT with every match of PATTERNS replaced by its name in brackets.\"\"\"\n    for name, pattern in PATTERNS:\n        text = pattern.sub(f\"[{name}]\", text)\n    return text\n\n\ndef found(text):\n    \"\"\"{name: count} of what redact() would take out of TEXT.\"\"\"\n    return {name: len(p.findall(text)) for name, p in PATTERNS if p.search(text)}",
      "note": "`redact()` replaces; `found()` only counts, which is what `scan.py` used. Both read the same list, so what is counted is what would be removed."
    },
    {
      "code": "KEY = os.environ.get(\"PSEUDONYM_KEY\", \"\").encode()\n\n\ndef pseudonym(user):\n    \"\"\"A keyed hash of USER: the same person gets the same value, and without the key nobody can\n    go from the value back to the person by trying every user id.\"\"\"\n    if not KEY:\n        raise RuntimeError(\"PSEUDONYM_KEY is not set: refusing to record a user id unkeyed\")\n    return hmac.new(KEY, user.encode(), hashlib.sha256).hexdigest()[:16]",
      "note": "The pseudonym, which a later section explains. The key comes from the environment, and with no key the function refuses rather than falling back to an unkeyed hash."
    }
  ]
}
```

And in `assistant.py`, the two attributes that carry text are written through it:

```python
    with span("ask", **{"app.feature": feature, "app.release": release, "gen_ai.request.model": cfg["model"],
                        "user.hash": redact.pseudonym(user), "session.id": session or "",
                        "app.question": redact.redact(question)}) as root:
```

```python
        root.set_attribute("app.reply", redact.redact(reply))
```

One of the week's order questions, asked by hand:

```
ana@lab:~/obs$ python assistant.py --feature order --user u021 "Hi, I am Joana Prado (joana.prado@example.com). My order MG-20481937 has not arrived after 12 working days. Is it lost?"
I could not find that in our documents.
trace 31b9488c6865b9bd1722d976e1ce6a0c
ana@lab:~/obs$ python tree.py --attrs | grep -E "app.question|app.reply|user.hash"
                     user.hash = "d6aad8d0fb204820"
                     app.question = "Hi, I am Joana Prado ([email]). My order [order] has not arrived after 12 working days. Is it lost?"
                     app.reply = "I could not find that in our documents."
```

The address and the order number are gone from the question, replaced by the name of what was there.
The reply is a refusal, so it had nothing to remove. And the user is `d6aad8d0fb204820` rather than
`u021`, which is the pseudonym the last section of this lesson explains.

**A placeholder that says what it replaced is worth more than a blank.** `[email]` keeps the sentence
readable and keeps a fact that matters for debugging: the customer gave an address, so the assistant
had a way to contact them and still refused. A blank, or a row of asterisks, keeps neither.

## Checking that it worked

Writing a redaction is not the same as knowing it ran. The check is to search the stored spans for a
value that was sent:

```
ana@lab:~/obs$ grep -c "joana.prado@example.com" spans.jsonl
0
ana@lab:~/obs$ grep -c "Joana Prado" spans.jsonl
1
```

The address appears nowhere. The name appears once, in the question, and that is not a bug in the
patterns: there is no pattern for a name, which is the subject of a later section.

Make the check permanent. A test that sends a request carrying a known address, which exists only
for the test, and then fails if that address appears anywhere in the exported spans, runs in a
second and catches the day somebody adds a new attribute and forgets the function. **A canary is a
value that should never come out the other side**, and its absence is the only evidence that
redaction is on.

## Why not redact in one place, later

It is tempting to write the text as it is and clean it in the tracing backend, or in a job that runs
overnight. Three things go wrong. Every copy made before the cleaning holds the original: the
export queue, the backend's ingestion buffer, a backup taken at midnight. The backend has to be told
which fields to clean, and it will not know about the attribute added next month. And a person
asking what is held about them is owed an answer that includes the unclean copies.

So the first line is in the code that sets the attribute, and the second, in the next section, is in
the process, before the span leaves it. Neither is in the backend.
