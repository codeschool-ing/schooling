---
title: Finding a secret before it is committed
version: 1
---

A secret in a commit is far cheaper to stop than to clean up, so the first defence is a scanner
that runs **before** the commit exists. **detect-secrets** is one: it reads files and reports
strings that look like credentials, by keyword (`password`, `api_key`, `secret`) and by
randomness, and it ships a hook meant for exactly this moment. Install it:

```
(.venv) ana@vm:~/sc/secrets$ pip install --progress-bar off detect-secrets==1.5.0
Collecting detect-secrets==1.5.0
  Using cached detect_secrets-1.5.0-py3-none-any.whl.metadata (23 kB)
Requirement already satisfied: pyyaml in /home/ana/sc/.venv/lib/python3.13/site-packages (from detect-secrets==1.5.0) (6.0.3)
Requirement already satisfied: requests in /home/ana/sc/.venv/lib/python3.13/site-packages (from detect-secrets==1.5.0) (2.34.2)
Requirement already satisfied: charset_normalizer<4,>=2 in /home/ana/sc/.venv/lib/python3.13/site-packages (from requests->detect-secrets==1.5.0) (3.5.2)
Requirement already satisfied: idna<4,>=2.5 in /home/ana/sc/.venv/lib/python3.13/site-packages (from requests->detect-secrets==1.5.0) (3.20)
Requirement already satisfied: urllib3<3,>=1.26 in /home/ana/sc/.venv/lib/python3.13/site-packages (from requests->detect-secrets==1.5.0) (2.8.0)
Requirement already satisfied: certifi>=2023.5.7 in /home/ana/sc/.venv/lib/python3.13/site-packages (from requests->detect-secrets==1.5.0) (2026.10.23)
Using cached detect_secrets-1.5.0-py3-none-any.whl (120 kB)
Installing collected packages: detect-secrets
Successfully installed detect-secrets-1.5.0
```

Ask it about the file as it stands:

```
(.venv) ana@vm:~/sc/secrets$ detect-secrets-hook app.py
ERROR: Potential secrets about to be committed to git repo!

Secret Type: Secret Keyword
Location:    app.py:5

Secret Type: Secret Keyword
Location:    app.py:6

Possible mitigations:
  - For information about putting your secrets in a safer place, please ask in
    #security
  - Mark false positives with an inline `pragma: allowlist secret` comment

If a secret has already been committed, visit
https://help.github.com/articles/removing-sensitive-data-from-a-repository
```

Both lines are found: the session key and the SMS key, each reported as a *Secret Keyword*, meaning
the name of the variable looks like a credential and the value is a string. The exit status is not
zero, so in a hook the commit stops here. Lesson 19's `check.sh` is where this command belongs,
next to bandit and pip-audit.

### What the scanner can and cannot know

It reports what **looks** like a secret. A random-looking test fixture is reported too, and a real
key stored in a variable called `x` may not be. Two answers, the same as lesson 19's:

- **a false positive** is marked on its own line with `# pragma: allowlist secret`, which the tool's
  own message suggests, and the line says why in words a reviewer can check;
- **a real finding** is fixed by moving the secret, never by adding the pragma.

The test file that comes next in this lesson asks for the same thing from the other side: it fails
if the string `sms_live_` is ever in `app.py` again.
