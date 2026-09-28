---
title: Stopping it before the commit
version: 1
---

The best leak is the one that never becomes a commit. Git can run a script before every commit, a
**pre-commit hook**, and refuse the commit if the script says no. Here is a small one:

```schooling-example
{"language": "sh", "file": ".git/hooks/pre-commit", "parts": [{"code": "#!/bin/sh\n# Refuse a commit whose added lines look like a secret being assigned.", "note": "Git runs `.git/hooks/pre-commit` before every commit, if it exists and is executable. If it exits with anything but 0, the commit does not happen."}, {"code": "if git diff --cached -U0 | grep -inE '^\\+.*(password|secret|token|api_?key)[a-z_]*[[:space:]]*[=:][[:space:]]*[\"'\\''][^\"'\\'']{8,}'; then", "note": "`git diff --cached` is what is about to be committed; `-U0` drops the context lines. The pattern looks at added lines for a word like *password* or *token*, an `=` or `:`, and a quoted value of eight characters or more."}, {"code": "  echo 'pre-commit: that looks like a secret. Keep it in the environment, not the repository.' >&2\n  exit 1\nfi", "note": "A sentence that says what to do instead, and a non-zero exit. `grep` has already printed the offending line, so the message does not need to repeat it."}]}
```

And here it is at work, with the same file as before:

```
ana@laptop:~/loanbook$ cat .git/hooks/pre-commit
#!/bin/sh
# Refuse a commit whose added lines look like a secret being assigned.
if git diff --cached -U0 | grep -inE '^\+.*(password|secret|token|api_?key)[a-z_]*[[:space:]]*[=:][[:space:]]*["'\''][^"'\'']{8,}'; then
  echo 'pre-commit: that looks like a secret. Keep it in the environment, not the repository.' >&2
  exit 1
fi
ana@laptop:~/loanbook$ git add notify.py
ana@laptop:~/loanbook$ git commit -q -m 'Send a reminder the day a loan is due'
8:+SMTP_PASSWORD = "mR7vQ2xL9pT4wZ8k"
pre-commit: that looks like a secret. Keep it in the environment, not the repository.
ana@laptop:~/loanbook$ git log --oneline -1
ff1a9d1 Read the database path and port from the environment
```

The commit did not happen: `grep` printed the line it matched, the hook printed its sentence, and `git log`
still shows the commit from before. Rewritten to read the environment, the file goes through:

```
ana@laptop:~/loanbook$ cat notify.py
import os

SMTP_HOST = os.environ["SMTP_HOST"]
SMTP_PASSWORD = os.environ["SMTP_PASSWORD"]
ana@laptop:~/loanbook$ git add notify.py
ana@laptop:~/loanbook$ git commit -q -m 'Send a reminder the day a loan is due'
ana@laptop:~/loanbook$ git log --oneline -1
bfb3fbe Send a reminder the day a loan is due
```

Two honest limits. **A hook lives in `.git/hooks`, which is not part of the repository**, so it protects
your clone and nobody else's. Tools like *pre-commit* share hooks through a committed configuration file,
and hosting sites offer server-side scanning: GitHub's *push protection* refuses a push containing a
known kind of key. And **a pattern catches the shapes it knows**: a key assigned to a variable called
`x` goes straight through. The hook is a net, not a guarantee, and the guarantee is still the habit of
never typing a secret into a file git can see.
