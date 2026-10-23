---
title: The API client, and lesson 12's doors as a test
version: 1
---

DRF has its own client, `APIClient`, which encodes JSON and can **skip authentication**:
`force_authenticate(user)` makes every request that user's, without tokens or passwords. Lesson 12's
`doors.py` needed a running server, three passwords and a token for each person; as a test, it is a
table. `tests/test_api.py`:

```python
# tests/test_api.py
import pytest
from rest_framework.test import APIClient

DOORS = [
    (None, "get", "/api/events/testing-dojo/", 200),
    (None, "patch", "/api/events/testing-dojo/", 401),
    ("carla", "patch", "/api/events/testing-dojo/", 403),
    ("bruno", "patch", "/api/events/testing-dojo/", 200),
    ("bruno", "patch", "/api/events/async-workshop/", 403),
    ("ana", "patch", "/api/events/async-workshop/", 200),
    ("bruno", "post", "/api/events/", 403),
    ("ana", "post", "/api/events/", 400),
]


@pytest.mark.parametrize("who, method, path, expected", DOORS)
def test_doors(request, workshop, dojo, who, method, path, expected):
    client = APIClient()
    if who is not None:
        client.force_authenticate(request.getfixturevalue(who))
    answer = getattr(client, method)(path, {}, format="json")
    assert answer.status_code == expected
```

`@pytest.mark.parametrize` runs the test once per row, each with its own fixtures and its own
rollback. `request.getfixturevalue(who)` turns the name in the row into the fixture of that name:

```
ana@vm:~/agenda$ uv run pytest tests/test_api.py -v
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0 -- /home/ana/agenda/.venv/bin/python
cachedir: .pytest_cache
django: version: 6.1.2, settings: config.settings (from ini)
rootdir: /home/ana/agenda
configfile: pyproject.toml
plugins: anyio-4.15.1, django-4.14.0
collecting ... collected 8 items

tests/test_api.py::test_doors[None-get-/api/events/testing-dojo/-200] PASSED                 [ 12%]
tests/test_api.py::test_doors[None-patch-/api/events/testing-dojo/-401] PASSED               [ 25%]
tests/test_api.py::test_doors[carla-patch-/api/events/testing-dojo/-403] PASSED              [ 37%]
tests/test_api.py::test_doors[bruno-patch-/api/events/testing-dojo/-200] PASSED              [ 50%]
tests/test_api.py::test_doors[bruno-patch-/api/events/async-workshop/-403] PASSED            [ 62%]
tests/test_api.py::test_doors[ana-patch-/api/events/async-workshop/-200] PASSED              [ 75%]
tests/test_api.py::test_doors[bruno-post-/api/events/-403] PASSED                            [ 87%]
tests/test_api.py::test_doors[ana-post-/api/events/-400] PASSED                              [100%]

======================================== 8 passed in 5.75s =========================================
```

**Each door is a test of its own**, named after its row, so a failure says which person, which method
and which path. The difference from `doors.py` is where it runs: on every change, before anything
reaches a server, which is lesson 12's point about a forgotten permission. The last section of this
lesson shows the table catching one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 254\" role=\"img\" aria-label=\"Five kinds of request drawn against the layers they pass through: HTTP over a socket, middleware and routing, view or route, service, database. test_services.py calls register directly and covers the service and the database. Django's test client, DRF's APIClient and Starlette's TestClient start at middleware and routing and go down to the database. doors.py from lesson 12 also crosses a real socket to a running server.\"> <text x=\"220\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTP over</text> <text x=\"220\" y=\"43\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a socket</text> <text x=\"330\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">middleware</text> <text x=\"330\" y=\"43\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and routing</text> <text x=\"440\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">view</text> <text x=\"440\" y=\"43\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">or route</text> <text x=\"550\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">service</text> <text x=\"660\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">database</text> <text x=\"160\" y=\"77\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">test_services.py</text> <rect x=\"500\" y=\"60\" width=\"210\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"508\" y=\"76\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">register() called directly</text> <text x=\"160\" y=\"111\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">test_pages.py</text> <rect x=\"280\" y=\"94\" width=\"430\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"288\" y=\"110\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Django's test client</text> <text x=\"160\" y=\"145\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">test_api.py, Django</text> <rect x=\"280\" y=\"128\" width=\"430\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"288\" y=\"144\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">DRF's APIClient</text> <text x=\"160\" y=\"179\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">test_api.py, FastAPI</text> <rect x=\"280\" y=\"162\" width=\"430\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"288\" y=\"178\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Starlette's TestClient</text> <text x=\"160\" y=\"213\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">doors.py, lesson 12</text> <rect x=\"170\" y=\"196\" width=\"540\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.18\" stroke=\"var(--amber)\"></rect> <text x=\"178\" y=\"212\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a running server</text> <text x=\"360\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Every test here but the last runs in one process, against a test database.</text> </svg>", "caption": "How much of the application each kind of test exercises. Only the network is skipped by the clients, which is why they are fast."}
```
