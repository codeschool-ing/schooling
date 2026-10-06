---
title: Keys in the code
version: 1
---

**A key written into source code is readable by everybody who can read the repository, on every
machine that ever cloned it, for as long as any copy exists. Deleting the line later removes it from
one file and from none of the copies.** It is the commonest cryptographic mistake there is, and the
one lesson 14 promised to start from.

## Five weeks in the portal

On 4 May, Bruno added webhook verification to Vereda's portal: the HMAC of lesson 6, with the key the
payment provider issued. To get it working he wrote the key into `settings.py`. On 10 June, after a
review, he replaced it with a read from the environment. Today's file is clean:

```
ana@lab:~/lab$ git -C portal log --oneline
d9cfbcd Read the webhook key from the environment
761abf7 Verify the payment provider's webhooks
ana@lab:~/lab$ grep -n WEBHOOK portal/settings.py
4:WEBHOOK_KEY = bytes.fromhex(os.environ["VEREDA_WEBHOOK_KEY"])
```

The history is not. The key is in the diff that added it and in the diff that removed it, and a
search for 64 hexadecimal digits finds both:

```
ana@lab:~/lab$ git -C portal log -p | grep -nE '[0-9a-f]{64}'
15:-WEBHOOK_KEY = bytes.fromhex("5c6e1f566813609ed2f6eea08c669f64aa8c3235959b5f59b78b280d94a4111a")
31:+WEBHOOK_KEY = bytes.fromhex("5c6e1f566813609ed2f6eea08c669f64aa8c3235959b5f59b78b280d94a4111a")
```

`git log -S` lists every commit that added or removed a given string, which is how a reviewer asks
"since when, and until when":

```
ana@lab:~/lab$ git -C portal log --oneline -S "$(cat keys/webhook.hex)"
d9cfbcd Read the webhook key from the environment
761abf7 Verify the payment provider's webhooks
```

For five weeks, every clone of the portal took the key with it: the laptops of three developers, the
CI runners, the contractor who fixed the booking page, and the nightly backup of the git server. All
of those copies still have it. **Removing the line did not revoke anything.** Rewriting the history
with `git filter-repo` cleans the copies Vereda controls and none of the others.

## The only fix is a new key

A key that reached a repository is treated as published. The response is the one section 05 sets
out: issue a new key at the provider, deploy it, revoke the old one, and look in the provider's logs
for use of the old key from anywhere unexpected. The work is the same whether the repository was
public or private, because "private" only says who was supposed to have access.

## Keeping keys out

The key belongs in the environment the code runs in, put there by a secret manager or the platform's
own mechanism, never in the code that is deployed to it:

```py
import os

WEBHOOK_KEY = bytes.fromhex(os.environ["VEREDA_WEBHOOK_KEY"])
```

That line fails loudly when the variable is missing, and the loud failure is deliberate.
`os.environ.get("VEREDA_WEBHOOK_KEY", "dev-key")` would run, verify webhooks with a key that is now
in the code again, and give no sign that anything was wrong.

Two automated checks catch what review misses:

- **A scanner before the commit.** Tools such as gitleaks and TruffleHog run as a pre-commit hook and
  refuse a commit containing something shaped like a key: a PEM private key header, a cloud provider's
  key prefix, a long high-entropy string.
- **The same scanner in CI, over the whole history**, plus the hosting platform's own secret scanning
  where it exists. GitHub, for example, recognises many providers' key formats and can block a push
  that contains one.

The same rule covers every place code travels: container images, mobile apps and JavaScript sent to
the browser are all delivered to people who can read them. Lesson 11 showed why hiding a key inside
them, with Base64 or a homemade scramble, changes nothing. A key that the client needs to hold is not
a secret, and the design has to accept that.
