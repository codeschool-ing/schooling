---
title: The test that sends what the browser would not
version: 1
---

The `curl` request in the previous section is the evidence; the tests make it permanent. They send
the form fields the way Flask's test client sends them, with no browser anywhere, which is the
point: **a server test is the first client that ignores the HTML**. Save them as `test_app.py`:

```python
# test_app.py
import pytest

import app as portal

GOOD = {"name": "Lucia Prado", "email": "lucia@mail.example", "birth": "1988-04-12"}


@pytest.fixture
def client():
    portal.PATIENTS.clear()
    return portal.app.test_client()


def test_a_good_signup_is_stored(client):
    assert client.post("/signup", data=GOOD).status_code == 201
    assert portal.PATIENTS == [GOOD]


@pytest.mark.parametrize("field, value", [
    ("name", ""),
    ("name", "x" * 61),
    ("email", "lucia"),
    ("birth", "2031-01-01"),
    ("birth", "yesterday"),
])
def test_what_the_browser_refuses_the_server_refuses_too(client, field, value):
    response = client.post("/signup", data=dict(GOOD, **{field: value}))
    assert response.status_code == 400
    assert portal.PATIENTS == []


def test_a_field_the_form_never_had_is_not_stored(client):
    client.post("/signup", data=dict(GOOD, role="staff"))
    assert "role" not in portal.PATIENTS[0]


def test_the_form_states_the_servers_limits(client):
    page = client.get("/signup").get_data(as_text=True)
    for f in portal.FIELDS.values():
        if "maxlength" in f:
            assert f'maxlength="{f["maxlength"]}"' in page
```

Two of these tests are about flaws the first section did not name, and both come from trusting the
form:

- **A field the form never had.** The old code stores `dict(request.form)`, every field that
  arrived. A form with three inputs does not stop a request from carrying a fourth, `role=staff`,
  and code further on that reads `patient.get("role")` will believe it. Building the stored record
  from a list of known fields, and nothing else, closes this whole class at once. It is often
  called **mass assignment**, and it is the same mistake in every framework that can fill an
  object from a request.
- **Two copies of one limit.** The last test asks the server for its limits and checks the page
  states the same ones. A limit written once in the HTML and once in Python is two numbers that
  will drift; the test fails the day they do.

### Red

```
(.venv) ana@vm:~/sc/signup$ pytest --tb=line
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/signup
collected 8 items

test_app.py .FFFFFFF                                                     [100%]

=================================== FAILURES ===================================
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   AssertionError: assert 'role' not in {'name': 'Lucia Prado', 'email': 'lucia@mail.example', 'birth': '1988-04-12', 'role': 'staff'}
/home/ana/sc/signup/test_app.py:35: AssertionError: assert 'role' not in {'name': 'Lucia Prado', 'email': 'lucia@mail.example', 'birth': '1988-04-12', 'role': 'staff'}
E   AttributeError: module 'app' has no attribute 'FIELDS'
/home/ana/sc/signup/test_app.py:40: AttributeError: module 'app' has no attribute 'FIELDS'
=========================== short test summary info ============================
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[name-]
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[name-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx]
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[email-lucia]
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[birth-2031-01-01]
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[birth-yesterday]
FAILED test_app.py::test_a_field_the_form_never_had_is_not_stored - Assertion...
FAILED test_app.py::test_the_form_states_the_servers_limits - AttributeError:...
========================= 7 failed, 1 passed in 0.11s ==========================
```

Seven failures. The five refusals fail because the old server accepted everything, the extra
field fails because `role` was stored, and the last test cannot even start: **`FIELDS` does not
exist**, because in the old code the limits exist only as HTML text. Commit it as it is:

```
(.venv) ana@vm:~/sc/signup$ git add app.py test_app.py
(.venv) ana@vm:~/sc/signup$ git commit -m "Sign up from the form"
[main (root-commit) d67a375] Sign up from the form
 2 files changed, 64 insertions(+)
 create mode 100644 app.py
 create mode 100644 test_app.py
```
