---
title: The portal's page, and six tests
version: 1
---

This lesson's folder is `~/sc/csp`:

```
(.venv) ana@vm:~/sc$ mkdir csp
(.venv) ana@vm:~/sc$ cd csp
(.venv) ana@vm:~/sc/csp$ git init -b main
Initialized empty Git repository in /home/ana/sc/csp/.git/
```

The page that greets a patient with her next session is small, and it has the two habits a policy
is about to break: an inline `<script>` that sets the page title, and an `onclick` attribute on a
button. Both are the portal's own code, written by ana, and both are harmless. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport logging\n\nfrom flask import Flask, render_template_string\n\napp = Flask(__name__)\nlog = logging.getLogger(\"portal\")\n", "note": "A logger named `portal`, as in lesson 15. Nothing writes to it yet; the reports of the third section will."}, {"code": "PAGE = \"\"\"<!doctype html>\n<html lang=\"en\">\n<head><meta charset=\"utf-8\"><title>Vereda</title></head>\n<body>\n<h1>Your next session</h1>\n<p id=\"when\">Monday 16 November, 09:00, with carla</p>", "note": "The page's title in the HTML is just `Vereda`. Watch what sets the rest of it."}, {"code": "<button onclick=\"document.getElementById('when').classList.toggle('large')\">Larger text</button>", "note": "An inline event handler: JavaScript inside an attribute, run when the button is clicked. A policy that refuses inline script refuses this too."}, {"code": "<script>\n  document.title = \"Vereda: \" + document.getElementById(\"when\").textContent;\n</script>\n</body>\n</html>\n\"\"\"\n\n", "note": "An inline script, the portal's own, which puts the next session in the browser tab's title."}, {"code": "@app.get(\"/\")\ndef home():\n    return render_template_string(PAGE)", "note": "One page. In the real portal the session comes from the database; here it is written into the page."}]}
```

### The tests

The tests below read the header the way a browser does. `policy()` splits it into its directives, so a
test can say exactly which value each one must have. The fifth test reads the page itself: no
`<script>` without a `src`, and no `on…=` attribute, because the policy would refuse both. Save them as
`test_app.py`:

```python
# test_app.py
import logging
import re

import pytest

import app as portal


@pytest.fixture
def client():
    return portal.app.test_client()


def policy(response):
    header = response.headers.get("Content-Security-Policy", "")
    return dict(
        (part.split()[0], " ".join(part.split()[1:]))
        for part in header.split(";")
        if part.strip()
    )


def test_the_page_shows_the_next_session(client):
    assert "with carla" in client.get("/").get_data(as_text=True)


def test_every_page_sends_an_enforced_policy(client):
    assert "Content-Security-Policy" in client.get("/").headers


def test_scripts_come_only_from_the_portal(client):
    directives = policy(client.get("/"))
    assert directives.get("script-src") == "'self'"
    assert directives.get("object-src") == "'none'"
    assert directives.get("base-uri") == "'none'"
    assert directives.get("frame-ancestors") == "'none'"


def test_no_page_carries_inline_script(client):
    page = client.get("/").get_data(as_text=True)
    assert not re.search(r"<script(?![^>]*\ssrc=)[^>]*>", page)
    assert not re.search(r"\son[a-z]+=", page)


def test_the_script_file_is_served(client):
    assert client.get("/static/portal.js").status_code == 200


def test_a_violation_report_is_logged(client, caplog):
    caplog.set_level(logging.WARNING, logger="portal")
    report = {"csp-report": {"violated-directive": "script-src-elem", "blocked-uri": "inline"}}
    assert client.post("/csp-report", json=report).status_code == 204
    assert "csp violation" in caplog.text
```

### Red

```
(.venv) ana@vm:~/sc/csp$ pytest -q --tb=no
.FFFFF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_every_page_sends_an_enforced_policy - AssertionError...
FAILED test_app.py::test_scripts_come_only_from_the_portal - assert None == "...
FAILED test_app.py::test_no_page_carries_inline_script - assert not <re.Match...
FAILED test_app.py::test_the_script_file_is_served - AssertionError: assert 4...
FAILED test_app.py::test_a_violation_report_is_logged - AssertionError: asser...
5 failed, 1 passed in 0.15s
```

**Five of six fail**: the page works, and nothing about it is ready for a policy. Commit it as it is:

```
(.venv) ana@vm:~/sc/csp$ git add app.py test_app.py
(.venv) ana@vm:~/sc/csp$ git commit -q -m "Greet the patient with her next session"
```

### A browser to watch

The tests check what the server sends. What the policy is **for** happens in the browser, so this
lesson also drives a real one. **Playwright** is a library that starts a browser and controls it from
Python. Install it in the course's environment, and then the browser it drives:

```
(.venv) ana@vm:~/sc/csp$ pip install --progress-bar off playwright==1.56.0
Collecting playwright==1.56.0
  Downloading playwright-1.56.0-py3-none-manylinux1_x86_64.whl.metadata (3.5 kB)
Collecting pyee<14,>=13 (from playwright==1.56.0)
  Downloading pyee-13.0.1-py3-none-any.whl.metadata (3.0 kB)
Collecting greenlet<4.0.0,>=3.1.1 (from playwright==1.56.0)
  Downloading greenlet-3.5.6-cp313-cp313-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl.metadata (3.8 kB)
Collecting typing-extensions (from pyee<14,>=13->playwright==1.56.0)
  Downloading typing_extensions-4.16.0-py3-none-any.whl.metadata (3.3 kB)
Downloading playwright-1.56.0-py3-none-manylinux1_x86_64.whl (46.3 MB)
Downloading greenlet-3.5.6-cp313-cp313-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl (623 kB)
Downloading pyee-13.0.1-py3-none-any.whl (15 kB)
Downloading typing_extensions-4.16.0-py3-none-any.whl (45 kB)
Installing collected packages: typing-extensions, greenlet, pyee, playwright
Successfully installed greenlet-3.5.6 playwright-1.56.0 pyee-13.0.1 typing-extensions-4.16.0
```

```
$ playwright install chromium
```

The second command downloads Playwright's own build of Chromium into your home folder.
It was **not run** in the recording of this lesson: the recording machine already had a Chromium build
installed, version 153, which is what the transcripts below come from. Your messages may be worded a
little differently in another version; what they say will not.

`look.py` opens the page, clicks the button, and prints the page's title, whether the click worked,
and every message the browser writes to its console. Save it beside `app.py`:

```python
# look.py
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.on("console", lambda message: print("console:", message.text))
    page.goto("http://127.0.0.1:5000/")
    page.click("button")
    print("title:", page.title())
    print("larger text:", page.eval_on_selector("#when", "e => e.classList.contains('large')"))
    browser.close()
```

Start the portal with `flask --app app run`, and in a second terminal:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
title: Vereda: Monday 16 November, 09:00, with carla
larger text: True
```

No policy, no messages: the inline script set the title and the `onclick` handler enlarged the text.
