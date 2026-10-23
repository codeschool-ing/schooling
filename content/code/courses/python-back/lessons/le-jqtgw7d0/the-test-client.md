---
title: The test client, and a test that counts queries
version: 1
---

`register` is one layer. A **test client** sends a request through all of Django except the
network: URL routing, middleware, the view, the template. pytest-django offers it as the fixture
`client`. `tests/test_pages.py`:

```python
# tests/test_pages.py
def test_the_list_shows_every_event(client, workshop, dojo):
    page = client.get("/events/")
    assert page.status_code == 200
    assert b"Async Python workshop" in page.content
    assert b"2 events." in page.content


def test_the_form_registers_and_redirects(client, dojo):
    page = client.post("/events/testing-dojo/", {"name": "Davi", "email": "davi@example.org"})
    assert page.status_code == 302
    assert page.headers["Location"] == "/events/testing-dojo/"
    assert dojo.registrations.filter(email="davi@example.org").exists()


def test_an_unknown_event_is_a_404(client, db):
    assert client.get("/events/nope/").status_code == 404


def test_the_list_costs_one_query(client, django_assert_num_queries, workshop, dojo):
    with django_assert_num_queries(1):
        client.get("/events/")
```

```
ana@vm:~/agenda$ uv run pytest tests/test_pages.py -v
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0 -- /home/ana/agenda/.venv/bin/python
cachedir: .pytest_cache
django: version: 6.1.2, settings: config.settings (from ini)
rootdir: /home/ana/agenda
configfile: pyproject.toml
plugins: anyio-4.15.1, django-4.14.0
collecting ... collected 4 items

tests/test_pages.py::test_the_list_shows_every_event PASSED                                  [ 25%]
tests/test_pages.py::test_the_form_registers_and_redirects PASSED                            [ 50%]
tests/test_pages.py::test_an_unknown_event_is_a_404 PASSED                                   [ 75%]
tests/test_pages.py::test_the_list_costs_one_query PASSED                                    [100%]

======================================== 4 passed in 2.03s =========================================
```

`test_the_form_registers_and_redirects` posted the form without a CSRF token, and passed: **Django's
test client does not enforce CSRF** unless it is created with `Client(enforce_csrf_checks=True)`, so
a test about the form's logic is not also a test about cookies.

## The test lesson 4 promised

`test_the_list_costs_one_query` is the one that pays for itself. `django_assert_num_queries(1)`
fails if the block runs any number of queries other than one. Suppose somebody adds the number of
registrations to each event in the list, in `events/templates/events/event_list.html`:

```
ana@vm:~/agenda$ grep -n 'registered' events/templates/events/event_list.html
13:    {{ event.starts_at|date:"D j M, H:i" }} at {{ event.venue }}, {{ event.registrations.count }} registered
ana@vm:~/agenda$ uv run pytest tests/test_pages.py -q --tb=line
...F                                                                                         [100%]
============================================= FAILURES =============================================
E   Failed: Expected to perform 1 queries but 3 were done (add -v option to show queries)
/home/ana/agenda/.venv/lib/python3.12/site-packages/pytest_django/fixtures.py:727: Failed: Expected to perform 1 queries but 3 were done (add -v option to show queries)
===================================== short test summary info ======================================
FAILED tests/test_pages.py::test_the_list_costs_one_query - Failed: Expected to perform 1 queries...
1 failed, 3 passed in 2.05s
```

**One query became three**, one for the list and one per event, which is lesson 4's N+1. The page
looked right and nobody would have noticed with two events; the test noticed. `-v` lists the queries.
The fix is lesson 4's too, a count in the same query. In `events/views.py`, annotate the list and
import `Count`; in the template, read `event.taken`:

```
ana@vm:~/agenda$ grep -n 'Count\|annotate' events/views.py
2:from django.db.models import Count
12:    events = Event.objects.filter(title__icontains=q).annotate(taken=Count("registrations"))
ana@vm:~/agenda$ grep -n 'registered' events/templates/events/event_list.html
13:    {{ event.starts_at|date:"D j M, H:i" }} at {{ event.venue }}, {{ event.taken }} registered
ana@vm:~/agenda$ uv run pytest tests/test_pages.py -q
....                                                                                         [100%]
4 passed in 2.05s
```
