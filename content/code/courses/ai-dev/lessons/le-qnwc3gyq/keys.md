---
title: Keys stay out of the code
version: 1
---

An API key is a password that spends money. **Whoever holds it can make requests on your account**,
up to your limits, and the bill comes to you. Every SDK in this course reads its key from the
environment, which is where it belongs.

## Where the keys are

```
ana@dev:~/shop$ env | grep _API_KEY | cut -d= -f1
ANTHROPIC_API_KEY
GEMINI_API_KEY
OPENAI_API_KEY
```

Three variables, one per provider, set by the lab. The SDKs read `ANTHROPIC_API_KEY`,
`OPENAI_API_KEY` and `GEMINI_API_KEY` without being told to, so the code in this lesson never
mentions a key. **A key written in a source file is a key in every copy of that file**: in the
repository, in its history, in every fork, and in whatever an assistant reads from the project, as
lesson 3 showed.

## Without one, and with a wrong one

```
ana@dev:~/shop$ env -u ANTHROPIC_API_KEY python -c 'import anthropic; anthropic.Anthropic().messages.create(model="scripted-1", max_tokens=10, messages=[{"role": "user", "content": "hi"}])' 2>&1 | tail -n 1
TypeError: "Could not resolve authentication method. Expected one of api_key, auth_token, or credentials to be set. Or for one of the `X-Api-Key` or `Authorization` headers to be explicitly omitted"
ana@dev:~/shop$ ANTHROPIC_API_KEY=lab-anthropic-key-9999 python -c 'import anthropic; anthropic.Anthropic().messages.create(model="scripted-1", max_tokens=10, messages=[{"role": "user", "content": "hi"}])' 2>&1 | tail -n 1
anthropic.AuthenticationError: Error code: 401 - {'type': 'error', 'error': {'type': 'authentication_error', 'message': 'invalid x-api-key'}, 'request_id': 'req_lab_0004'}
```

**The first fails before any request is made.** The SDK found no key and refused to build the
request. The second made the request with a key labllm does not know, and the provider answered
401. Both are loud, which is good; the dangerous case is a key that works and should not be there.

## Keeping a local key out of git

On a laptop, keys usually live in a file called `.env` that a script loads. The file must never be
committed:

```
ana@dev:~/shop$ printf '.env\n' > .gitignore; git check-ignore -v .env
.gitignore:1:.env	.env
```

`git check-ignore -v` says which rule ignores the file, and that the rule exists before the file
does. **Add the rule first.** A `.env` committed once is in the history even after it is deleted,
and the only fix is to revoke the key.

## What to do with keys

- **One key per environment and per application.** A leak then costs one revocation, and the
  provider's usage page tells you which application spent what.
- **Set a spending limit on each key** where the provider offers one. A limit turns a leaked key
  from an unbounded bill into a bounded one.
- **Revoke on suspicion, not on proof.** A new key costs a deploy. An old key in the wrong hands
  costs whatever its limit allows.
- **In production, a secret manager**, not a file on the server. It keeps who read the key, and
  rotating the key does not mean editing every machine.
