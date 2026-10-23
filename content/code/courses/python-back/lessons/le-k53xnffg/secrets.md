---
title: Keeping secrets out of git
version: 1
---

A secret in a repository is a secret in every clone, every fork and every backup of it, and deleting
it later leaves it in the history. So the rule is mechanical: **the file that holds secrets is never
added**. agenda is not a git repository yet. Before making it one, remove the throwaway files earlier
lessons left behind:

```
ana@vm:~/agenda$ rm -f before-logout.txt drf-token.txt jar.txt doors.py owners.py passwords.py seed.py
ana@vm:~/agenda$ git init -q
```

Then a `.gitignore`, which names what git should not offer to add:

```sh
# .gitignore
.venv/
__pycache__/
.pytest_cache/
celerybeat-schedule*
.env
```

And a `.env.example`, which **is** committed: the names the project needs, and no values, so that the
next person knows what to fill in:

```ini
# .env.example
# Copy to .env and fill in the blanks. .env itself is never committed.
DJANGO_SECRET_KEY=
DJANGO_DEBUG=1
DJANGO_ALLOWED_HOSTS=
DATABASE_USER=agenda_app
DATABASE_PASSWORD=
DATABASE_HOST=localhost
CELERY_BROKER_URL=redis://127.0.0.1:6379/0
```

```
ana@vm:~/agenda$ git status --short
?? .env.example
?? .gitignore
?? config/
?? events/
?? manage.py
?? pyproject.toml
?? templates/
?? tests/
?? uv.lock
ana@vm:~/agenda$ git check-ignore -v .env
.gitignore:6:.env	.env
```

`.env` is not in the list, and `check-ignore` says which line excluded it. Do the same in
`~/agenda-api`, with its own two names.

## When one leaks anyway

A secret that reached a repository, a chat or a screenshot is **rotated**, not deleted: generate a new
one, deploy it, and let the old one stop working, as the JWT key just did. For Django's
`SECRET_KEY`, rotating ends every session and invalidates password-reset links; Django's
`SECRET_KEY_FALLBACKS` setting keeps the old key valid for checking, but not for signing, while
sessions move over. For a database password, it is `ALTER ROLE ... PASSWORD` and a restart.

An environment is not a vault either. A process's environment can be read by the same user, appears
in some error reports, and is inherited by every child process. Lesson 16 keeps the file readable by
the service alone; a team with many servers uses a secret manager, which hands out values the same
way, through the environment or a file, and records who read them.
