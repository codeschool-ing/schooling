---
title: An app is a folder Django knows about
version: 1
---

A Django **project** is the configuration. The code lives in **apps**: packages with their own
models, views, URLs and templates, which the project switches on in `INSTALLED_APPS`. The admin, the
users and the sessions you migrated are apps too, written by Django and switched on by
`startproject`. agenda gets one of its own, `events`:

```
ana@vm:~/agenda$ uv run python manage.py startapp events
ana@vm:~/agenda$ find events -type f | sort
events/__init__.py
events/admin.py
events/apps.py
events/migrations/__init__.py
events/models.py
events/tests.py
events/views.py
```

| file | what it is for |
|---|---|
| `models.py` | the tables, as classes (lesson 4) |
| `views.py` | the functions that answer requests (this lesson) |
| `admin.py` | how the models appear in the admin (lesson 5) |
| `apps.py` | the app's configuration: its name and label |
| `migrations/` | the history of its tables (lesson 4) |
| `tests.py` | its tests; lesson 14 replaces it with a `tests/` directory |

There is no `urls.py`, because not every app answers URLs; the next section adds one.

## Switching it on

An app Django does not know about is a folder like any other: its models get no tables and its
templates are not found. Add it to the end of `INSTALLED_APPS` in `config/settings.py`:

```
ana@vm:~/agenda$ sed -n '/^INSTALLED_APPS/,/^]/p' config/settings.py
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'events',
]
ana@vm:~/agenda$ uv run python manage.py check
System check identified no issues (0 silenced).
```

`check` passing is the confirmation that the name resolves to a package Django could import.

## Where the events come from, for now

The events will live in PostgreSQL from lesson 4. Until then, a list of dictionaries stands in for
the table, so the URLs and views can be built first. Save it as `events/data.py`:

```python
# events/data.py
EVENTS = [
    {
        "slug": "django-night",
        "title": "Django Night",
        "starts_at": "2026-11-12T19:00",
        "venue": "Community Centre, room 3",
        "capacity": 40,
    },
    {
        "slug": "async-workshop",
        "title": "Async Python workshop",
        "starts_at": "2026-11-19T14:00",
        "venue": "Public Library, lab 2",
        "capacity": 12,
    },
    {
        "slug": "testing-dojo",
        "title": "Testing dojo",
        "starts_at": "2026-11-26T19:00",
        "venue": "Community Centre, room 3",
        "capacity": 20,
    },
]
```

**The dates are written as strings and carry no zone.** That is a shortcut this file can afford
because nothing compares or formats them yet; lesson 3 turns them into real date and time values,
and lesson 4 stores them in UTC.

## One app or several

The question comes up the first week of every Django project. An app is worth splitting off when it
has **a job you can name in one sentence** and its own tables: events, and later perhaps payments.
agenda stays one app for the whole course, because everything in it is about events and the people
who register for them. Splitting too early costs imports between apps that know too much about
each other; splitting late costs a migration that moves tables, which is lesson 4's subject and not
a small one.
