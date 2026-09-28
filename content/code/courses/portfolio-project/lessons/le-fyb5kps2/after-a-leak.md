---
title: The day it happens
version: 1
---

If a secret reached a repository that anybody else can read, the order of what you do matters more than
anything else in this lesson.

1. **Revoke it, first.** Change the password, delete the key, issue a new token, in the service that
   issued it. This is the only step that makes the leaked value useless, and every minute before it is a
   minute somebody may be using it. Do it before touching git.
2. **Check whether it was used.** The service's logs, its billing page, its list of recent sessions. A
   cloud key used overnight shows up as a bill; an e-mail password used shows up as sent mail you did not
   send.
3. **Put the new secret where it belongs**: the environment, as in this lesson's second section, and
   never a file in the repository.
4. **Then, if you want, clean the history.** Tools such as `git filter-repo` rewrite every commit to remove
   a file or a string, and a force-push replaces the branch. This step is optional and it is last, because
   it cannot recall copies that were already cloned, forked or cached by the scanners. It makes the history
   tidy; it does not make the secret secret again.

People get the order backwards because the history is what feels embarrassing. But a cleaned history with
an unrevoked key is still an open door, and a revoked key in an untidy history is harmless.

For a portfolio there is one more step worth taking: **say so**, in the pull request or the retrospective.
*A key was committed on 3 June, revoked within the hour, and the history cleaned* is evidence of exactly the
judgement a reviewer is looking for.
