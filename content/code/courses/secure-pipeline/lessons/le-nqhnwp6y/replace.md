---
title: The third move, replacing a dependency
version: 1
---

Updating assumes there is something to update to. Sometimes there is not: the advisory has no fixed
version and the maintainers say there will be none. Lesson 7 met exactly that case, a branch that
added `ecdsa==0.19.2` and an advisory with no fix, and the gate warned instead of breaking, because
nobody could act on it that day. **A warning that can never clear is a decision postponed**, and the
decision is the third move.

### What PyPI says about ecdsa

The release history, and the advisories PyPI's own vulnerability data lists for the version lesson 7
used:

@@CAPTURE ecdsa@@

One advisory under three names, CVE, GHSA and PYSEC, with nothing in `fixed_in`. The text explains
why: a timing side channel in signing, and **"The python-ecdsa project considers side channel attacks
out of scope for the project and there is no planned fix."** That is an honest statement and a
legitimate position for a pure-Python library, and it tells you exactly what the project will and will
not do for you.

The repository's recent history answers the second health question, who maintains it:

@@CAPTURE ecdsa-repo@@

A merge in June, and in the last year one person wrote most of the non-merge commits. That is a
maintained project, by a small group, with a stated scope. **Nothing here says the package is
abandoned; it says that the fix you need is outside what it promises.**

### Deciding

The advisory's text is precise about where the risk is, and that decides the move:

| what the service does with ECDSA | does the advisory apply? | the move |
|---|---|---|
| only verifies signatures somebody else made | no: the text says verification is unaffected | keep it, pinned, with the reason written in the gate's exceptions |
| signs with a key it holds | yes | replace it |
| signs only to check its own messages later | yes | replace it, and ask whether a signature is needed at all |

The last row is common and worth a moment. If one service signs a message only so that the same
service can trust it later, nobody else verifies it, and what it needs is a **message authentication
code**: `hmac` from the standard library, with `hmac.compare_digest` to compare, which lesson 3 already
used for linkbox's token. No dependency at all is the best replacement there is.

When a real signature is needed, the replacement is the `cryptography` package, maintained by the
Python Cryptographic Authority, whose elliptic-curve code runs in OpenSSL rather than in Python. The
same operation linkbox would have done with `ecdsa`, as `~/scratch/sign.py`:

```python
"""ECDSA on P-256, the curve python-ecdsa offered, from the `cryptography`
package: sign a message, verify it, and refuse it once a byte has changed."""
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec

key = ec.generate_private_key(ec.SECP256R1())
message = b"https://example.org/docs/handbook/onboarding"
signature = key.sign(message, ec.ECDSA(hashes.SHA256()))

public = key.public_key()
public.verify(signature, message, ec.ECDSA(hashes.SHA256()))
print("verified:", message.decode())
try:
    public.verify(signature, message + b"?", ec.ECDSA(hashes.SHA256()))
except InvalidSignature:
    print("refused: the message changed after it was signed")
```

Run in a throwaway environment, so nothing is added to linkbox:

@@CAPTURE replace@@

### What a replacement costs

**Replacing is the most expensive of the three moves**, which is why it comes last. It touches code,
not only a lock: every call site changes, the tests that covered the old library have to cover the
new one, and the new dependency brings its own health questions, its own advisories and, for
`cryptography`, compiled wheels for every platform you deploy on. Its release history on PyPI is
the same check this lesson ran for gunicorn, and it is worth running before the first import.

So the order holds. **Pin always, update by default, and replace when the project has told you, in
writing, that it will not fix what matters to you.** linkbox did not need `ecdsa` on `main`, and the
branch that added it never merged; the argument above is what a team would write in the pull request
that removes it.
