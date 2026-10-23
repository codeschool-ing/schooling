---
title: settings.py is Python, and DEBUG is the setting to respect
version: 1
---

`config/settings.py` is a plain Python module. Django imports it once, at start-up, and every
setting is a variable in capitals. The ones this course touches are at these lines:

```
ana@vm:~/agenda$ grep -nE '^(DEBUG|ALLOWED_HOSTS|ROOT_URLCONF|WSGI_APPLICATION|LANGUAGE_CODE|TIME_ZONE|USE_TZ|STATIC_URL) ' config/settings.py
26:DEBUG = True
28:ALLOWED_HOSTS = []
52:ROOT_URLCONF = 'config.urls'
69:WSGI_APPLICATION = 'config.wsgi.application'
105:LANGUAGE_CODE = 'en-us'
107:TIME_ZONE = 'UTC'
111:USE_TZ = True
117:STATIC_URL = 'static/'
```

| setting | what it decides |
|---|---|
| `DEBUG` | detailed error pages, and a few safety checks switched off. **Never on in production** |
| `ALLOWED_HOSTS` | the host names this site answers to; empty is only allowed while `DEBUG` is on |
| `ROOT_URLCONF` | which module holds the first table of URLs |
| `WSGI_APPLICATION` | the object `runserver` and a WSGI server load |
| `LANGUAGE_CODE` | the language of Django's own messages |
| `TIME_ZONE`, `USE_TZ` | the zone dates are shown in; with `USE_TZ`, they are stored in UTC |
| `STATIC_URL` | where CSS and images are served from (lesson 3) |

## A change, and how to see it took

agenda's events happen in São Paulo, so its dates should be shown in that zone. Change one line in an
editor:

```python
TIME_ZONE = 'America/Sao_Paulo'
```

`diffsettings` prints every setting that differs from Django's defaults, so it is the quickest way to
ask what the project is actually running with:

```
ana@vm:~/agenda$ uv run python manage.py diffsettings | grep -E "^(TIME_ZONE|DEBUG|ROOT_URLCONF)"
DEBUG = True
ROOT_URLCONF = 'config.urls'  ###
TIME_ZONE = 'America/Sao_Paulo'
```

`###` marks a setting Django has no default for at all. With `USE_TZ = True`, still on, **dates are
stored in UTC and converted to `TIME_ZONE` only when they are shown**. That is the right
arrangement, and it is why the change is safe to make at any time: nothing stored moves.

## What `DEBUG` protects you from, and exposes

With `DEBUG = True`, an error in a view produces a page with the traceback, the local variables of
every frame and most of the settings. That is what you want on your own machine and exactly what
nobody else should see. Turn it off and Django immediately insists on something it let slide:

```
ana@vm:~/agenda$ uv run python manage.py runserver --settings config.settings_nodebug
CommandError: You must set settings.ALLOWED_HOSTS if DEBUG is False.
```

That run used a copy of `settings.py` with `DEBUG = False` and nothing else changed. **With debugging
off, Django refuses to serve until `ALLOWED_HOSTS` names the host names it should answer to**, so a
request carrying a forged `Host` header is turned away rather than used to build links. Lesson 15
moves `DEBUG`, `ALLOWED_HOSTS` and the `SECRET_KEY` out of this file and into the environment,
which is where values that differ between your machine and production belong. Until then, leave
`DEBUG = True` and `ALLOWED_HOSTS = []`.

The `SECRET_KEY` at the top of the file starts with `django-insecure-`, which is Django's way of
saying the same thing about a key that was written into a file and will be read by everybody who
reads the file.
