---
title: Django's settings from the environment
version: 1
---

Replace the top of `config/settings.py`, from `from pathlib import Path` to `ALLOWED_HOSTS`, with:

```python
import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
DEBUG = os.environ.get("DJANGO_DEBUG") == "1"
ALLOWED_HOSTS = [host for host in os.environ.get("DJANGO_ALLOWED_HOSTS", "").split(",") if host]
```

Each line chooses what happens when the value is missing, and the choice is deliberate:

| setting | when missing | why |
|---|---|---|
| `SECRET_KEY` | **the application refuses to start** | no default is safe: a key in the code is a key everybody with the code has |
| `DEBUG` | **off** | a missing variable on a server must not turn on the page that shows settings and tracebacks |
| `ALLOWED_HOSTS` | empty | with `DEBUG` on, Django then allows `localhost`; with it off, nothing, which fails safe |

`DATABASES` reads its parts the same way, falling back to lesson 4's local socket when nothing is
set:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DATABASE_NAME', 'agenda'),
        'USER': os.environ.get('DATABASE_USER', ''),
        'PASSWORD': os.environ.get('DATABASE_PASSWORD', ''),
        'HOST': os.environ.get('DATABASE_HOST', ''),
    }
}
```

And `CELERY_BROKER_URL` becomes `os.environ.get("CELERY_BROKER_URL", "redis://127.0.0.1:6379/0")`,
so a hosted Redis, from lesson 13's table, is a value and not an edit:

```
ana@vm:~/agenda$ grep -n 'os.environ' config/settings.py
19:SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
20:DEBUG = os.environ.get("DJANGO_DEBUG") == "1"
21:ALLOWED_HOSTS = [host for host in os.environ.get("DJANGO_ALLOWED_HOSTS", "").split(",") if host]
75:        'NAME': os.environ.get('DATABASE_NAME', 'agenda'),
76:        'USER': os.environ.get('DATABASE_USER', ''),
77:        'PASSWORD': os.environ.get('DATABASE_PASSWORD', ''),
78:        'HOST': os.environ.get('DATABASE_HOST', ''),
143:CELERY_BROKER_URL = os.environ.get("CELERY_BROKER_URL", "redis://127.0.0.1:6379/0")
ana@vm:~/agenda$ uv run python manage.py check 2>&1 | tail -1
KeyError: 'DJANGO_SECRET_KEY'
```

**The application refuses to start**, which is the point: a server with no key fails at once, in a
log, instead of running with a key anybody could know.

## A .env file for this machine

Typing the variables before every command does not last. A **`.env` file** holds them, one
`NAME=value` per line, and `uv run --env-file .env` puts them in the environment of the command it
runs. Generate the key instead of inventing one, and write it straight into the file, so it is never
on the screen:

```
ana@vm:~/agenda$ printf 'DJANGO_SECRET_KEY=%s\nDJANGO_DEBUG=1\n' "$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')" > .env
ana@vm:~/agenda$ uv run --env-file .env python manage.py check
System check identified no issues (0 silenced).
```

From now on every Django command in this course runs as `uv run --env-file .env ...`. A variable set
in the shell wins over the file, which the last section uses.
