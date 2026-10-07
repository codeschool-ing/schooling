---
title: What leaves your machine
version: 2
---

Every request an assistant makes carries some of your files to somebody else's computer. That is
how it works, and for most code it is fine: your employer has an agreement with the provider, or
the code is yours. The problem is the file nobody meant to send. **A secret that reaches a model
provider has left your control**, and it now sits in a request log you cannot read or delete.

## What `.gitignore` does not do

ana's project has the two places a secret usually hides: a `.env` file with a token, which git
ignores, and a `settings.py` with a key typed into the code, which is a mistake but a common one.
Both values are made up and open nothing. Write the three files into `~/shop` to follow along.
`.gitignore`:

```
.env
__pycache__/
scratch/
```

`.env`:

```
SHOP_PAYMENTS_TOKEN=not-a-real-token-7d41
```

`settings.py`:

```python
PAYMENTS_URL = "https://payments.example.com/v1"
PAYMENTS_KEY = "pk_test_4f9a8c7e1d2b3a6f"  # made up for the course; a real key never belongs in code
```

```
ana@dev:~/shop$ git status --short --ignored
```

`!! .env` means git ignores the file. **The editor does not care.** An ignored file is still a file
on disk, and a tab is a tab. ana asks a question with both open:

```
ana@dev:~/shop$ python scratch/assist.py ask "Why might a payment fail?" --open shop/cart.py .env settings.py
```

`assist` refused `.env`, because its content matched the pattern of a secret, and sent
`settings.py`, which did not. The key went with it, and the request `assist` kept has it:

```
ana@dev:~/shop$ grep -c pk_test_4f9a8c7e1d2b3a6f scratch/sent.json
```

The reply itself is the list of reasons any payment fails, and its second paragraph names
`PAYMENTS_KEY` and `PAYMENTS_URL`: the model read `settings.py`, as the count above proves.
Nothing in these files takes a payment at all, which a colleague would have said first.

**A pattern check is a net with holes.** `assist` looks for `token`, `secret`, `password` or
`api_key` followed by a long value. `PAYMENTS_KEY = "pk_test_…"` is a secret by any reading, and
it passed because its name is not on the list. Real tools have better patterns and they still miss
things, because a secret is a fact about a value and a pattern can only see its shape.

## An exclusion list

The second defence is a list of paths the assistant must never read. Real assistants call it
different things (a setting, or a file at the root of the project) and it does the same job as
`assist`'s `.assistignore`:

```
ana@dev:~/shop$ printf "settings.py\n*.pem\nsecrets/\n" > .assistignore
ana@dev:~/shop$ python scratch/assist.py ask "Why might a payment fail?" --open shop/cart.py .env settings.py 2>&1 >/dev/null
```

`skipped settings.py: listed in .assistignore`. **The list is written by a person who knows where
the secrets are**, which is why it works where a pattern does not, and why it only works for the
places somebody thought of.

## The rules that actually protect you

- **Keep secrets out of files the editor opens.** Environment variables, a secret manager, a file
  outside the project. The key in `settings.py` was the mistake; the assistant only made it
  visible. Lesson 10 is about handling the provider's own key the same way.
- **Exclude what you can name**: `.env`, certificates and keys, the directory where credentials
  live. Commit the exclusion list, so it protects everybody who clones the project.
- **Know what your organisation allows.** Some companies forbid sending their code to a third
  party at all, some allow only an approved tool with a contract that says the code is not kept
  or used for training. That is a policy question with a real answer, and it is answered before
  you install the extension, not after.
- **If a secret did leave, rotate it.** There is no way to call a request back. Revoke the key,
  issue a new one, and treat the old one as public.
