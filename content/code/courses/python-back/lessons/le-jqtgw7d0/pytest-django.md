---
title: pytest, and a database for each test
version: 1
---

Every lesson so far checked agenda by hand: curl, a script, a look at the rows. That finds a
problem once. A **test** finds it every time somebody changes the code, which is when problems
arrive. This lesson writes the checks of lessons 3 to 13 down as tests, with **pytest**, the
runner most Python projects use, and **pytest-django**, which teaches it Django.

Lesson 2 promised that the empty `events/tests.py` would give way to a directory. Remove it, add
the two packages for development only, and tell pytest-django where the settings are, in a table at
the end of `pyproject.toml`:

```
ana@vm:~/agenda$ rm events/tests.py
ana@vm:~/agenda$ uv add --dev pytest pytest-django
Resolved 41 packages in 259ms
Downloading pygments (1.2MiB)
 Downloaded pygments
Prepared 5 packages in 145ms
Installed 5 packages in 8ms
 + iniconfig==2.3.1
 + pluggy==1.7.0
 + pygments==2.21.0
 + pytest==9.1.1
 + pytest-django==4.14.0
ana@vm:~/agenda$ sed -n '/^\[tool.pytest/,$p' pyproject.toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings"
```

Tests go in `~/agenda/tests/`. What several tests need goes in `tests/conftest.py`, which pytest
reads first:

```schooling-example
{"language": "python", "file": "tests/conftest.py", "parts": [{"code": "# tests/conftest.py\nfrom datetime import datetime\nfrom zoneinfo import ZoneInfo\n\nimport pytest\nfrom django.contrib.auth.models import Group, Permission, User\n\nfrom events.models import Event\n\nSAO_PAULO = ZoneInfo(\"America/Sao_Paulo\")\n\n\n", "note": "A **fixture** is a function pytest calls to build something a test asks for by name. These make agenda's people and events, fresh for every test."}, {"code": "@pytest.fixture\ndef ana(db):\n    return User.objects.create_superuser(\"ana\", \"ana@example.org\", \"not-a-real-password\")\n\n\n", "note": "**`db` is pytest-django's**: asking for it gives the test database access, inside a transaction that is rolled back afterwards."}, {"code": "@pytest.fixture\ndef bruno(db):\n    organisers = Group.objects.create(name=\"Organisers\")\n    organisers.permissions.add(Permission.objects.get(codename=\"change_event\"))\n    bruno = User.objects.create_user(\"bruno\", \"bruno@example.org\", \"not-a-real-password\", is_staff=True)\n    bruno.groups.add(organisers)\n    return bruno\n\n\n@pytest.fixture\ndef carla(db):\n    return User.objects.create_user(\"carla\", \"carla@example.org\", \"not-a-real-password\")\n\n\n", "note": "Lesson 5's group is a row in the development database, not in the test one, so the fixture makes it again."}, {"code": "@pytest.fixture\ndef workshop(ana):\n    return Event.objects.create(\n        slug=\"async-workshop\",\n        title=\"Async Python workshop\",\n        starts_at=datetime(2026, 11, 19, 14, 0, tzinfo=SAO_PAULO),\n        venue=\"Public Library, lab 2\",\n        capacity=2,\n        organiser=ana,\n    )\n\n\n@pytest.fixture\ndef dojo(bruno):\n    return Event.objects.create(\n        slug=\"testing-dojo\",\n        title=\"Testing dojo\",\n        starts_at=datetime(2026, 11, 26, 19, 0, tzinfo=SAO_PAULO),\n        venue=\"Community Centre, room 3\",\n        capacity=20,\n        organiser=bruno,\n    )\n", "note": "**Fixtures ask for fixtures.** `workshop` needs `ana` as organiser, so asking for the workshop creates her too. Two seats, so that filling it takes two registrations."}]}
```

And the first tests, of lesson 4's `register`, in `tests/test_services.py`:

```python
# tests/test_services.py
import pytest

from events.services import RegistrationRefused, register


def test_register_saves_a_row(workshop):
    registration = register(workshop.pk, "Carla", "carla@example.org")
    assert registration.event == workshop
    assert workshop.registrations.count() == 1


def test_the_same_address_twice_is_refused(workshop):
    register(workshop.pk, "Carla", "carla@example.org")
    with pytest.raises(RegistrationRefused, match="already registered"):
        register(workshop.pk, "Carla again", "carla@example.org")


def test_a_full_event_refuses(workshop):
    register(workshop.pk, "Carla", "carla@example.org")
    register(workshop.pk, "Davi", "davi@example.org")
    with pytest.raises(RegistrationRefused, match="full"):
        register(workshop.pk, "Elisa", "elisa@example.org")
```

A test is a function whose name starts with `test_`; it passes if it returns, and fails if an
`assert` is false or an exception escapes. `pytest.raises` turns "this must fail" into something
that can pass:

```
ana@vm:~/agenda$ uv run pytest tests/test_services.py -v
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0 -- /home/ana/agenda/.venv/bin/python
cachedir: .pytest_cache
django: version: 6.1.2, settings: config.settings (from ini)
rootdir: /home/ana/agenda
configfile: pyproject.toml
plugins: anyio-4.15.1, django-4.14.0
collecting ... collected 3 items

tests/test_services.py::test_register_saves_a_row PASSED                                     [ 33%]
tests/test_services.py::test_the_same_address_twice_is_refused PASSED                        [ 66%]
tests/test_services.py::test_a_full_event_refuses PASSED                                     [100%]

======================================== 3 passed in 1.67s =========================================
```

## Where the rows went

Nothing in the development database changed. **pytest-django creates a database for the run**,
`test_agenda`, migrates it, and destroys it at the end, which is why lesson 4 gave `ana` the right to
create databases. Each test then runs inside a transaction that is rolled back, so the three tests
above each started with no registrations, whatever the one before did.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"Two boxes. In pytest-django, the db fixture opens a transaction before each test and rolls it back after; the test's own atomic blocks become savepoints inside it. In agenda-api, the session fixture begins a transaction on a connection and binds a session with join_transaction_mode create_savepoint, so each session.commit in a route only releases a savepoint, and the outer rollback removes everything.\"> <text x=\"20\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pytest-django: db</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"30\" y=\"54\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BEGIN, before the test</text> <rect x=\"40\" y=\"64\" width=\"280\" height=\"50\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the test: fixtures, requests,</text> <text x=\"180\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">register(), its atomic() as a savepoint</text> <text x=\"30\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ROLLBACK, after it</text> <text x=\"380\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">agenda-api: the session fixture</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"390\" y=\"54\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">connection.begin()</text> <rect x=\"400\" y=\"64\" width=\"280\" height=\"50\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the test: TestClient, routes,</text> <text x=\"540\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">session.commit() as a savepoint</text> <text x=\"390\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">outer.rollback()</text> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Every row a test writes disappears with the outer transaction,</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">so each test starts from the fixtures alone.</text> </svg>", "caption": "The same trick in both frameworks: the test runs inside a transaction that is never committed."}
```

The rollback has one consequence worth knowing now: **nothing in a test ever commits**, so the
`on_commit` that queues the confirmation never fires, and these tests needed no Redis. The section on
tasks deals with that on purpose.
