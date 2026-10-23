---
title: The history remembers
version: 1
---

The new code is clean, and it is tempting to think the problem is solved. Commit the fix and look
at the repository:

```
(.venv) ana@vm:~/sc/secrets$ git add .gitignore app.py
(.venv) ana@vm:~/sc/secrets$ git commit -q -m "Read secrets from the environment"
(.venv) ana@vm:~/sc/secrets$ git log --oneline
0018102 Read secrets from the environment
5b3eb3e Send reminders by SMS
(.venv) ana@vm:~/sc/secrets$ git log -p -S sms_live_ --format='%h %s' -- app.py | grep -E '^[0-9a-f]{7} |sms_live_'
0018102 Read secrets from the environment
-SMS_API_KEY = "sms_live_4f9a1c7e2b8d6a3f"
5b3eb3e Send reminders by SMS
+SMS_API_KEY = "sms_live_4f9a1c7e2b8d6a3f"
```

`git log -S` searches every commit for one that added or removed a string. The key left the code
in the latest commit, and the commit before it still holds it, line for line. Anybody who clones
the repository, today or in five years, has it. **Removing a secret from the code does not remove it
from the history.**

### The fix is rotation

Once a secret has been committed and pushed, assume it has been read. The only reliable fix is
**rotation**: issue a new key at the provider, deploy it through the environment, and revoke the old
one, so that the copy in the history opens nothing. The order matters: deploy the new key before
revoking the old, or the reminders stop for the minutes in between.

Rewriting the history, with tools such as `git filter-repo`, removes the string from the
repository's future clones and is worth doing on a repository the team controls. It is a second
step, never the first: every clone, fork, cache and CI log made before the rewrite still has the old
history, and a rewrite cannot reach them. Rotation can.

### What made the leak possible

Two things, both cheap to prevent. The key was typed into the code because there was nowhere else
to put it on the day; a `required()` function and a `.env` file from the first commit remove that
reason. And nothing looked at the commit before it was made; the scanner of this lesson's second
section, in lesson 19's hook, would have refused it.
