---
title: A project is a settings module and a manage.py
version: 1
---

From this lesson to the end of the course you build **agenda**, the events site lesson 1 described.
It starts the way the hello project did, in its own directory, with Django from PyPI:

```
ana@vm:~$ mkdir agenda && cd agenda && uv init --bare && uv add django
Initialized project `agenda`
Using CPython 3.12.3 interpreter at: /usr/bin/python3
Creating virtual environment at: .venv
Resolved 5 packages in 147ms
Installed 3 packages in 527ms
 + asgiref==3.12.1
 + django==6.1.2
 + sqlparse==0.6.0
ana@vm:~/agenda$ uv run django-admin startproject config .
```

**The project package is called `config`**, not `agenda`. `startproject` names the package after its
first argument, and with the directory already called `agenda`, a second `agenda` inside it would
make every import ambiguous to read: `agenda.settings` or the directory? `config` says what the
package holds. The `.` at the end puts `manage.py` in the current directory rather than in a new
one.

What `startproject` wrote is the same set lesson 1 listed, under the new name:

| file | what it is |
|---|---|
| `manage.py` | the command-line entry point; it sets `DJANGO_SETTINGS_MODULE` to `config.settings` and runs a command |
| `config/settings.py` | **every setting of the project**, as ordinary Python variables |
| `config/urls.py` | the project's table of URLs, the first one Django reads for every request |
| `config/wsgi.py`, `config/asgi.py` | the application object a WSGI or ASGI server imports (lesson 1, and lesson 16) |
| `config/__init__.py` | empty; it makes `config` a package |

## The first migration

Lesson 1 warned about 18 unapplied migrations. They are the tables of the apps `startproject`
switched on, and applying them creates the database, which for now is a single SQLite file:

```
ana@vm:~/agenda$ uv run python manage.py migrate
Operations to perform:
  Apply all migrations: admin, auth, contenttypes, sessions
Running migrations:
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  Applying admin.0001_initial... OK
  Applying admin.0002_logentry_remove_auto_add... OK
  Applying admin.0003_logentry_add_action_flag_choices... OK
  Applying contenttypes.0002_remove_content_type_name... OK
  Applying auth.0002_alter_permission_name_max_length... OK
  Applying auth.0003_alter_user_email_max_length... OK
  Applying auth.0004_alter_user_username_opts... OK
  Applying auth.0005_alter_user_last_login_null... OK
  Applying auth.0006_require_contenttypes_0002... OK
  Applying auth.0007_alter_validators_add_error_messages... OK
  Applying auth.0008_alter_user_username_max_length... OK
  Applying auth.0009_alter_user_last_name_max_length... OK
  Applying auth.0010_alter_group_name_max_length... OK
  Applying auth.0011_update_proxy_permissions... OK
  Applying auth.0012_alter_user_first_name_max_length... OK
  Applying sessions.0001_initial... OK
ana@vm:~/agenda$ ls
config
db.sqlite3
manage.py
pyproject.toml
uv.lock
```

Each line is one change to the schema, in the order its app declared them, and each runs once:
Django records in a table of its own which migrations have been applied, so running `migrate` again
does nothing. **`db.sqlite3` is the whole database.** SQLite needs no server, which is why Django
starts with it; lesson 4 moves agenda to PostgreSQL, and nothing written before then has to change.

## The development server, and the page that says it worked

Start it with `uv run python manage.py runserver`, with no port this time, so it takes the default,
8000. A project with no URLs of its own answers `/` with a page of Django's:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/ | grep -o "<title>.*</title>"
<title>The install worked successfully! Congratulations!</title>
<title>Django</title>
```

Two titles, because the page has an SVG with a title of its own. **That page only exists while
`DEBUG` is on and the project has no URLs**, and it disappears the moment the next section's first
URL is added.

## `manage.py` is a list of commands

Every command in this lesson goes through `manage.py`. Django's own come first in its help, and the
apps you install add theirs below:

```
ana@vm:~/agenda$ uv run python manage.py help | sed -n "/\[django\]/,/^$/p" | head -12
[django]
    check
    compilemessages
    createcachetable
    dbshell
    diffsettings
    dumpdata
    flush
    inspectdb
    loaddata
    makemessages
    makemigrations
```

`check` inspects the project without running it, `diffsettings` prints what differs from the
defaults, `shell` opens Python with the project loaded, and `migrate` and `makemigrations` are
lesson 4. **Run `check` after any change that might not have worked**: it takes a second and finds
a misspelled app or a broken URL before a request does.
