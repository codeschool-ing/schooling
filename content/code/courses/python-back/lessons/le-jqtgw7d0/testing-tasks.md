---
title: Testing tasks without a broker
version: 1
---

A Celery task is a function with a `.delay()` attached. That splits its tests in two: **that the
right task is queued at the right moment**, and **that the function does the right thing** when it
runs. Neither needs Redis or a worker. `tests/test_tasks.py`:

```schooling-example
{"language": "python", "file": "tests/test_tasks.py", "parts": [{"code": "# tests/test_tasks.py\nfrom events.models import Registration\nfrom events.services import register\nfrom events.tasks import send_confirmation\n\n\n"}, {"code": "def test_registering_queues_the_confirmation_after_commit(\n    workshop, monkeypatch, django_capture_on_commit_callbacks\n):\n    queued = []\n    monkeypatch.setattr(send_confirmation, \"delay\", queued.append)\n", "note": "**No Redis in a test.** `monkeypatch` replaces `delay` for this test only, with a list's `append`, and puts the original back afterwards."}, {"code": "    with django_capture_on_commit_callbacks(execute=True):\n        registration = register(workshop.pk, \"Carla\", \"carla@example.org\")\n        assert queued == []\n    assert queued == [registration.pk]\n\n\n", "note": "Inside the test's transaction nothing ever commits, so `on_commit` would never fire. This fixture collects the callbacks and, with `execute=True`, runs them when the block ends: **nothing queued before, one id after**."}, {"code": "def test_the_confirmation_is_sent_once(workshop, mailoutbox):\n    registration = Registration.objects.create(event=workshop, name=\"Carla\", email=\"carla@example.org\")\n    assert send_confirmation(registration.pk) == \"sent\"\n    assert send_confirmation(registration.pk) == \"already sent\"\n    assert len(mailoutbox) == 1\n    assert mailoutbox[0].to == [\"carla@example.org\"]\n    assert mailoutbox[0].subject == \"You are registered for Async Python workshop\"\n", "note": "The task is a function; calling it runs it here, synchronously. `mailoutbox` is the list Django's test mail backend fills instead of sending."}]}
```

```
ana@vm:~/agenda$ uv run pytest tests/test_tasks.py -v
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0 -- /home/ana/agenda/.venv/bin/python
cachedir: .pytest_cache
django: version: 6.1.2, settings: config.settings (from ini)
rootdir: /home/ana/agenda
configfile: pyproject.toml
plugins: anyio-4.15.1, django-4.14.0
collecting ... collected 2 items

tests/test_tasks.py::test_registering_queues_the_confirmation_after_commit PASSED            [ 50%]
tests/test_tasks.py::test_the_confirmation_is_sent_once PASSED                               [100%]

======================================== 2 passed in 1.07s =========================================
```

The first test is the reason `register` uses `on_commit`, written down: the id is queued after the
commit and not before it. The second is lesson 13's idempotency: two calls, one message in the
outbox, addressed to Carla, with the event's title in the subject. **Django's test setup swaps
whatever `MAILERS` says for an in-memory backend** for the whole run, so no test can send a real
e-mail by accident.

With that, agenda has seventeen tests, and the whole suite takes a few seconds:

```
ana@vm:~/agenda$ uv run pytest
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0
django: version: 6.1.2, settings: config.settings (from ini)
rootdir: /home/ana/agenda
configfile: pyproject.toml
plugins: anyio-4.15.1, django-4.14.0
collected 17 items

tests/test_api.py ........                                                                   [ 47%]
tests/test_pages.py ....                                                                     [ 70%]
tests/test_services.py ...                                                                   [ 88%]
tests/test_tasks.py ..                                                                       [100%]

======================================== 17 passed in 8.65s ========================================
```

## What these tests do not check

They check agenda's code against agenda's decisions. They do not check that Redis is running, that a
worker is subscribed to the right queue, or that the mail server accepts the messages: those are
facts about a deployment, and lesson 16's checks of a running server are where they belong. A
`CELERY_TASK_ALWAYS_EAGER` setting exists that runs every `.delay()` in place; it hides when a task
is queued, which is exactly what the first test above is there to check.
