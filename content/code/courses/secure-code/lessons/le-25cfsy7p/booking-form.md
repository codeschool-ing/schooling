---
title: The booking form, as ana found it
version: 1
---

This lesson's application is the endpoint behind the booking form: a `POST` to `/bookings` with a
JSON body of four fields. Make its folder a repository the way lesson 1 did for `cancel`; if you
saved `digits.py` in the previous section, it is already there:

```
(.venv) ana@vm:~/sc$ mkdir booking
(.venv) ana@vm:~/sc$ cd booking
(.venv) ana@vm:~/sc/booking$ git init -b main
Initialized empty Git repository in /home/ana/sc/booking/.git/
```

Here is the version ana inherited, with the denylist from the first section. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "from flask import Flask, jsonify, request\n\napp = Flask(__name__)\nBOOKINGS = []\n\nFORBIDDEN = (\"<\", \">\", \";\", \"--\")\n\n\ndef looks_safe(value):\n    return not any(bad in value for bad in FORBIDDEN)\n\n", "note": "A list of characters somebody once decided were dangerous. Everything else is welcome."}, {"code": "@app.post(\"/bookings\")\ndef create():\n    data = request.get_json()\n    for field in (\"clinic\", \"date\", \"time\", \"phone\"):\n        if not looks_safe(str(data.get(field, \"\"))):\n            return jsonify(error=f\"invalid {field}\"), 400\n    BOOKINGS.append(data)\n    return jsonify(data), 201", "note": "Each field is checked against the list and stored exactly as it arrived. A missing field becomes an empty string, which contains nothing forbidden."}]}
```

### The tests state the allowlist

The tests describe a good booking once, in `GOOD`, and then change one field at a time to a value
that must be refused. `parametrize` runs the same test function once per pair, so one function
covers seven cases and each one is reported on its own line. Save them as `test_app.py`:

```python
# test_app.py
import pytest

import app as portal

FULL_WIDTH = "".join(chr(0xFF10 + int(d)) for d in "11987654321")
GOOD = {"clinic": "moema", "date": "2026-11-10", "time": "09:00", "phone": "11987654321"}


@pytest.fixture
def client():
    portal.BOOKINGS.clear()
    return portal.app.test_client()


def test_a_good_booking_is_stored(client):
    assert client.post("/bookings", json=GOOD).status_code == 201
    assert len(portal.BOOKINGS) == 1


@pytest.mark.parametrize("field, value", [
    ("clinic", "Moema"),
    ("clinic", "paulista"),
    ("date", "2026-11-31"),
    ("time", "23:00"),
    ("phone", "1198765"),
    ("phone", FULL_WIDTH),
    ("phone", None),
])
def test_a_value_outside_the_allowlist_is_refused(client, field, value):
    response = client.post("/bookings", json=dict(GOOD, **{field: value}))
    assert response.status_code == 400
    assert response.get_json() == {"error": f"invalid {field}"}
    assert portal.BOOKINGS == []


def test_a_missing_field_is_refused(client):
    body = {k: v for k, v in GOOD.items() if k != "phone"}
    assert client.post("/bookings", json=body).status_code == 400
```

Each test checks three things where it can: the status, **the field the error names**, and that
nothing was stored. A refusal that names the wrong field passes a status check and still sends the
patient looking for the wrong mistake.

### Red

Eight tests fail, and a full report for each would fill several screens. `--tb=line` shortens
every failure to the one line that says what was expected:

```
(.venv) ana@vm:~/sc/booking$ pytest --tb=line
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/booking
collected 9 items

test_app.py .FFFFFFFF                                                    [100%]

=================================== FAILURES ===================================
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/booking/test_app.py:32: assert 201 == 400
E   AssertionError: assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
     +    where <WrapperTestResponse streamed [201 CREATED]> = post('/bookings', json={'clinic': 'moema', 'date': '2026-11-10', 'time': '09:00'})
     +      where post = <FlaskClient <Flask 'app'>>.post
/home/ana/sc/booking/test_app.py:39: AssertionError: assert 201 == 400
=========================== short test summary info ============================
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[clinic-Moema]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[clinic-paulista]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[date-2026-11-31]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[time-23:00]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[phone-1198765]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[phone-\uff11\uff11\uff19\uff18\uff17\uff16\uff15\uff14\uff13\uff12\uff11]
FAILED test_app.py::test_a_value_outside_the_allowlist_is_refused[phone-None]
FAILED test_app.py::test_a_missing_field_is_refused - AssertionError: assert ...
========================= 8 failed, 1 passed in 0.13s ==========================
```

**Every value in the first section's table was accepted with a `201` and stored.** The good
booking passes, which is the trap of a denylist in one line: it never gets in the way of correct
data, so nobody using the form notices it is not checking anything. Commit this version before
changing it:

```
(.venv) ana@vm:~/sc/booking$ git add app.py test_app.py digits.py
(.venv) ana@vm:~/sc/booking$ git commit -m "Book a session from the form"
[main (root-commit) f356038] Book a session from the form
 3 files changed, 69 insertions(+)
 create mode 100644 app.py
 create mode 100644 digits.py
 create mode 100644 test_app.py
```
