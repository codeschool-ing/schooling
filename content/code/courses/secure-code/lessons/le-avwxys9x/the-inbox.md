---
title: The staff inbox, and five tests
version: 1
---

Patients send messages to their clinic, and receptionists read them in an inbox in the staff
console. The inbox can be searched, and a link to it can say whom the receptionist is replying to:
`/inbox#reply=lucia` puts "Replying to lucia" in the heading. This lesson's folder is
`~/sc/messages`:

```
(.venv) ana@vm:~/sc$ mkdir messages
(.venv) ana@vm:~/sc$ cd messages
(.venv) ana@vm:~/sc/messages$ git init -b main
Initialized empty Git repository in /home/ana/sc/messages/.git/
```

Here is the inbox. lucia's message came from an e-mail editor, and the bold around `much` came with
it. Save this as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nfrom flask import Flask, render_template_string, request\n\napp = Flask(__name__)\nMESSAGES = [\n    {\"patient\": \"lucia\", \"text\": \"Knee <b>much</b> better since Monday.\\nSee you Thursday.\"},\n    {\"patient\": \"rafael\", \"text\": \"Can I move Tuesday's session?\"},\n]\n", "note": "Two messages, held in memory. lucia's has a line break and, from the e-mail editor she copied it from, a pair of bold tags."}, {"code": "INBOX = \"\"\"<!doctype html>\n<html lang=\"en\">\n<head><meta charset=\"utf-8\"><title>Inbox</title></head>\n<body>\n<h1 id=\"reply\">Inbox</h1>\n<form action=\"/search\"><input name=\"q\"><button>Search</button></form>\n{% for m in messages %}\n<p class=\"message\"><strong>{{ m.patient }}</strong>: {{ m.text|replace(\"\\\\n\", \"<br>\")|safe }}</p>\n{% endfor %}\n<script src=\"/static/inbox.js\"></script>\n</body>\n</html>\n\"\"\"\n\n", "note": "The inbox page. Each message's line breaks become `<br>`, and the result is marked `safe` so the `<br>` tags survive. Read what else survives with them."}, {"code": "@app.get(\"/inbox\")\ndef inbox():\n    return render_template_string(INBOX, messages=MESSAGES)\n\n", "note": "The inbox, rendered from the template, with the messages as a variable."}, {"code": "@app.get(\"/search\")\ndef search():\n    term = request.args.get(\"q\", \"\")\n    found = [m for m in MESSAGES if term.lower() in m[\"text\"].lower()]\n    if not found:\n        return f\"<p>No messages match {term}.</p>\"\n    return render_template_string(INBOX, messages=found)", "note": "The search shows the matching messages in the same template, and a sentence when nothing matches. Look at how that sentence is built."}]}
```

The heading is written by a small script the page loads. Create the folder for it and save it as
`static/inbox.js`:

```
(.venv) ana@vm:~/sc/messages$ mkdir static
```

```javascript
// static/inbox.js
const replyTo = new URLSearchParams(location.hash.slice(1)).get("reply");
if (replyTo) {
  document.getElementById("reply").innerHTML = "Replying to " + replyTo;
}
```

### The tests

Four tests read what the server sends, and one reads the script, because the DOM-based kind never
reaches the server. Save them as `test_app.py`:

```python
# test_app.py
from pathlib import Path

import pytest

import app as portal


@pytest.fixture
def client():
    return portal.app.test_client()


def test_the_inbox_lists_messages(client):
    assert "rafael" in client.get("/inbox").get_data(as_text=True)


def test_a_stored_message_is_shown_as_text(client):
    page = client.get("/inbox").get_data(as_text=True)
    assert "Knee &lt;b&gt;much&lt;/b&gt; better" in page


def test_line_breaks_are_kept_by_css(client):
    assert "white-space: pre-line" in client.get("/inbox").get_data(as_text=True)


def test_a_search_term_is_shown_as_text(client):
    page = client.get("/search", query_string={"q": "<i>knee</i>"}).get_data(as_text=True)
    assert "No messages match &lt;i&gt;knee&lt;/i&gt;." in page


def test_the_script_writes_text_not_markup():
    script = Path("static/inbox.js").read_text()
    assert "innerHTML" not in script
    assert "textContent" in script
```

`&lt;b&gt;` is how a page writes `<b>` as text: the browser shows the characters, and builds nothing.

### Red

```
(.venv) ana@vm:~/sc/messages$ pytest -q --tb=no
.FFFF                                                                    [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_stored_message_is_shown_as_text - assert 'Knee &lt...
FAILED test_app.py::test_line_breaks_are_kept_by_css - assert 'white-space: p...
FAILED test_app.py::test_a_search_term_is_shown_as_text - AssertionError: ass...
FAILED test_app.py::test_the_script_writes_text_not_markup - assert 'innerHTM...
4 failed, 1 passed in 0.15s
```

**Four of five fail**, and the fifth only checks that the inbox has messages in it. Commit the flawed
version:

```
(.venv) ana@vm:~/sc/messages$ git add app.py static/inbox.js test_app.py look.py
(.venv) ana@vm:~/sc/messages$ git commit -q -m "Staff inbox, search and reply heading"
```

### What a browser builds

The tests read the HTML. To see what that HTML becomes, the lesson drives a browser with Playwright,
as lesson 8 does; if you have done lesson 8, it is already installed, and if not, its third section
shows the two commands. `look.py` opens the inbox with a reply in the address, wrapped in `<b>` as
a name could arrive from another system, and prints the heading, the first message and how many bold
elements the browser built:

```python
# look.py
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto("http://127.0.0.1:5000/inbox#reply=lucia <b>D'Ávila</b>")
    print("heading:", page.inner_text("#reply"))
    print("first message:", page.inner_text("p.message"))
    print("bold elements:", page.locator("b").count())
    browser.close()
```

Start the portal with `flask --app app run`, and from a second terminal:

```
(.venv) ana@vm:~/sc/messages$ python3 look.py
heading: Replying to lucia D'Ávila
first message: lucia: Knee much better since Monday.
See you Thursday.
bold elements: 2
```

**Two bold elements**, and neither appears as tags: one built from lucia's message, which the server
sent, and one built from the address, which the server never saw. That is two of the three kinds
already, in one page. The third is in the search.
