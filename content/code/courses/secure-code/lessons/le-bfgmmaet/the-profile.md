---
title: The profile page, built with f-strings
version: 1
---

The application is the patient's profile page: a heading with their name, an input holding their
nickname, a link to their own website, a link to their bookings, and a clinical note that the
page's JavaScript uses. The data lives in a file of its own so the page can change without it.
Save it as `profiles.py`:

```python
# profiles.py
PROFILES = {
    "lucia": {
        "name": "Lucia & Bia <3",
        "nickname": 'Lu "the fast"',
        "website": "https://lucia.example/blog?a=1&b=2",
        "note": "back pain </script> again",
    },
}
```

Every value there is something a patient could type into a form, and each one carries a character
that matters in the place it will be written. Here is the page as ana first wrote it, with Python's
f-strings and no template. Save it as `app.py`:

```python
# app.py
from flask import Flask

from profiles import PROFILES

app = Flask(__name__)


@app.get("/patients/<user>")
def profile(user):
    p = PROFILES[user]
    return f"""<h1>{p['name']}</h1>
<input name="nickname" value="{p['nickname']}">
<a href="{p['website']}">website</a>
<a href="/search?q={p['name']}">bookings of {p['name']}</a>
<script>const note = "{p['note']}";</script>
"""


@app.get("/search")
def search():
    return ""
```

An f-string pastes text into text. It does not know it is writing HTML, so it encodes nothing,
anywhere. Ask for the page with `curl` while the application runs, and every row of the first
section's figure has gone wrong at once:

```
(.venv) ana@vm:~/sc/profile$ curl -s http://127.0.0.1:5000/patients/lucia
<h1>Lucia & Bia <3</h1>
<input name="nickname" value="Lu "the fast"">
<a href="https://lucia.example/blog?a=1&b=2">website</a>
<a href="/search?q=Lucia & Bia <3">bookings of Lucia & Bia <3</a>
<script>const note = "back pain </script> again";</script>
```

Read it as a browser would. The heading contains a `<3` that the HTML parser will try to read as
the start of a tag. The input's value ends at the second `"`, after `Lu `, and `the fast""` is left
over as something that is not an attribute. The search link's query ends at the `&`, so the search
receives `Lucia ` and a stray parameter. And the script ends at `</script>`, in the middle of the
string, leaving ` again";` printed on the page as text.

### The tests, one per context

Each test asks for the page and looks for the exact encoding its context needs. Save them as
`test_app.py`:

```python
# test_app.py
import pytest

import app as portal


@pytest.fixture
def page():
    return portal.app.test_client().get("/patients/lucia").get_data(as_text=True)


def test_text_is_html_escaped(page):
    assert "<h1>Lucia &amp; Bia &lt;3</h1>" in page


def test_a_quoted_attribute_keeps_its_value(page):
    assert 'value="Lu &#34;the fast&#34;"' in page


def test_an_address_in_an_attribute_is_escaped_too(page):
    assert 'href="https://lucia.example/blog?a=1&amp;b=2"' in page


def test_a_query_value_is_url_encoded(page):
    assert 'href="/search?q=Lucia+%26+Bia+%3C3"' in page


def test_a_script_cannot_be_closed_from_inside_a_string(page):
    assert "</script> again" not in page
    assert r'const note = "back pain \u003c/script\u003e again";' in page


def test_only_web_addresses_become_links(monkeypatch):
    monkeypatch.setitem(portal.PROFILES["lucia"], "website", "data:text/html,hello")
    html = portal.app.test_client().get("/patients/lucia").get_data(as_text=True)
    assert "data:" not in html
```

The last test is about a different property, and the next sections come back to it: **escaping
makes a link's text harmless and says nothing about where the link goes.** A `data:` or `file:`
address in `href` is perfectly escaped and still not a web page.

### Red

The curl output already showed why each one fails, so `--tb=no` asks pytest for the verdicts and
nothing else:

```
(.venv) ana@vm:~/sc/profile$ pytest -q --tb=no
FFFFFF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_text_is_html_escaped - assert '<h1>Lucia &amp; Bia &...
FAILED test_app.py::test_a_quoted_attribute_keeps_its_value - assert 'value="...
FAILED test_app.py::test_an_address_in_an_attribute_is_escaped_too - assert '...
FAILED test_app.py::test_a_query_value_is_url_encoded - assert 'href="/search...
FAILED test_app.py::test_a_script_cannot_be_closed_from_inside_a_string - ass...
FAILED test_app.py::test_only_web_addresses_become_links - assert 'data:' not...
6 failed in 0.15s
```

All six fail. Commit the f-string version before replacing it:

```
(.venv) ana@vm:~/sc/profile$ git add contexts.py profiles.py app.py test_app.py
(.venv) ana@vm:~/sc/profile$ git commit -m "Show the patient profile"
[main (root-commit) e13eff4] Show the patient profile
 4 files changed, 79 insertions(+)
 create mode 100644 app.py
 create mode 100644 contexts.py
 create mode 100644 profiles.py
 create mode 100644 test_app.py
```
