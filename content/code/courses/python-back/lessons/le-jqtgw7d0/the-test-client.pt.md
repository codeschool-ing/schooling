---
title: O cliente de testes, e um teste que conta consultas
version: 1
---

O `register` é uma camada. Um **cliente de testes** manda uma requisição por todo o Django, menos a
rede: o roteamento de URLs, os middlewares, a view, o template. O pytest-django o oferece como a
fixture `client`. O `tests/test_pages.py`:

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

O `test_the_form_registers_and_redirects` enviou o formulário sem token de CSRF, e passou: **o cliente
de testes do Django não exige CSRF** a menos que seja criado com `Client(enforce_csrf_checks=True)`,
para que um teste sobre a lógica do formulário não seja também um teste sobre cookies.

## O teste que a aula 4 prometeu

O `test_the_list_costs_one_query` é o que se paga. O `django_assert_num_queries(1)` falha se o bloco
rodar qualquer número de consultas diferente de um. Suponha que alguém acrescente o número de
inscrições a cada evento da lista, em `events/templates/events/event_list.html`:

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

**Uma consulta virou três**, uma para a lista e uma por evento, que é o N+1 da aula 4. A página parecia
certa e ninguém teria notado com dois eventos; o teste notou. O `-v` lista as consultas. O conserto é
da aula 4 também, uma contagem na mesma consulta. Em `events/views.py`, anote a lista e importe
`Count`; no template, leia `event.taken`:

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
