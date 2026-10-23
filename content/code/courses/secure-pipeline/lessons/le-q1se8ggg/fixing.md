---
title: Two fixes, each with the test that proves it
version: 1
---

A finding is closed by a change to the code, and **a change to the code is proved by a test.**
Without the test, the fix is a claim: the scanner stops complaining, which says the shape is gone,
not that the behaviour is right. And without a test, the next person to touch the search can put
the defect back in a form the rule does not match. So each fix here goes in the same order: a test
that fails because of the defect, then the change, then the same test passing.

### The injection, as a failing test

The search should find a link whose address has a quote in it. Nothing exotic: `it's` is an
ordinary word, and somebody will search for it. Add one test to the end of the file. Save the
tests as `tests/test_app.py`:

```python
import pytest

from app import app
from settings import ADMIN_TOKEN


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.setattr("app.DATABASE", str(tmp_path / "test.db"))
    return app.test_client()


def test_create_needs_the_token(client):
    assert client.post("/links", data={"url": "https://example.org"}).status_code == 401


def test_a_link_redirects(client):
    made = client.post("/links", data={"url": "https://example.org/a"},
                       headers={"X-Token": ADMIN_TOKEN})
    assert made.status_code == 201
    code = made.get_json()["code"]
    followed = client.get(f"/{code}")
    assert followed.status_code == 302
    assert followed.headers["Location"] == "https://example.org/a"


def test_search_finds_a_link(client):
    client.post("/links", data={"url": "https://example.org/docs"},
                headers={"X-Token": ADMIN_TOKEN})
    page = client.get("/search?q=docs")
    assert page.status_code == 200
    assert b"https://example.org/docs" in page.data


def test_search_survives_a_quote(client):
    client.post("/links", data={"url": "https://example.org/it's-here"},
                headers={"X-Token": ADMIN_TOKEN})
    page = client.get("/search?q=it's")
    assert page.status_code == 200
    assert b"it&#39;s-here" in page.data
```

Run them against the code as it is:

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q --tb=short
...F                                                                     [100%]
=================================== FAILURES ===================================
_________________________ test_search_survives_a_quote _________________________
tests/test_app.py:39: in test_search_survives_a_quote
    assert page.status_code == 200
E   assert 500 == 200
E    +  where 500 = <WrapperTestResponse streamed [500 INTERNAL SERVER ERROR]>.status_code
------------------------------ Captured log call -------------------------------
ERROR    app:app.py:825 Exception on /search [GET]
Traceback (most recent call last):
  File "/home/ana/linkbox/.venv/lib/python3.13/site-packages/flask/app.py", line 1455, in wsgi_app
    response = self.full_dispatch_request()
  File "/home/ana/linkbox/.venv/lib/python3.13/site-packages/flask/app.py", line 869, in full_dispatch_request
    rv = self.handle_user_exception(e)
  File "/home/ana/linkbox/.venv/lib/python3.13/site-packages/flask/app.py", line 867, in full_dispatch_request
    rv = self.dispatch_request()
  File "/home/ana/linkbox/.venv/lib/python3.13/site-packages/flask/app.py", line 852, in dispatch_request
    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^
  File "/home/ana/linkbox/app.py", line 46, in search
    rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall()
           ~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
sqlite3.OperationalError: near "s": syntax error
=========================== short test summary info ============================
FAILED tests/test_app.py::test_search_survives_a_quote - assert 500 == 200
1 failed, 3 passed in 0.46s
```

**The new test fails with a 500, an internal server error, from a search for an English word.**
That is the defect, shown from your own application and nothing more: the quote ended the string
in the SQL, the rest of the text was read as SQL, SQLite refused it, and Flask answered 500. A
search for a word with an apostrophe breaks the page, and the same mistake lets whoever types into
that box change what the query does. The test asks for the page to work, and to show the link,
escaped as the template escapes it, which is what `it&#39;s-here` is.

### The change

Three edits to `app.py`: the query takes its value as a parameter, the token is checked by one
function that every route that writes calls, and the block that ran Flask's debugger is gone. Save
it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "\"\"\"linkbox: short links for a small team, kept in one SQLite file.\"\"\"\nimport secrets\nimport sqlite3\n\nfrom flask import Flask, abort, g, redirect, render_template_string, request\n\nfrom settings import ADMIN_TOKEN, DATABASE\n\napp = Flask(__name__)\n\nPAGE = \"\"\"<!doctype html>\n<title>linkbox</title>\n<form action=\"/search\"><input name=\"q\" value=\"{{ q }}\"><button>Search</button></form>\n<ul>{% for code, url in rows %}<li><a href=\"/{{ code }}\">{{ code }}</a> {{ url }}</li>{% endfor %}</ul>\n\"\"\"\n\n\ndef db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(DATABASE)\n        g.db.execute(\"CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT)\")\n    return g.db\n\n\n@app.teardown_appcontext\ndef close_db(_):\n    conn = g.pop(\"db\", None)\n    if conn is not None:\n        conn.close()\n\n", "note": "The top of the file is lesson 1's, unchanged: the imports, the page, and one database connection per request."}, {"code": "def require_token():\n    sent = request.headers.get(\"X-Token\", \"\")\n    if not secrets.compare_digest(sent, ADMIN_TOKEN):\n        abort(401)\n\n", "note": "New: the one place the token is checked. `secrets.compare_digest()` takes the same time whether the first character is wrong or the last, so how long the answer takes says nothing about how close a guess was. A missing header becomes an empty string, which never matches."}, {"code": "@app.post(\"/links\")\ndef create():\n    require_token()\n    code = secrets.token_urlsafe(4)\n    db().execute(\"INSERT INTO links VALUES (?, ?)\", (code, request.form[\"url\"]))\n    db().commit()\n    return {\"code\": code}, 201\n\n", "note": "`create()` now starts by calling it, which is what the Semgrep rule `writes-need-the-token` looks for. Every route that writes from now on starts with the same line."}, {"code": "@app.get(\"/\")\n@app.get(\"/search\")\ndef search():\n    q = request.args.get(\"q\", \"\")\n    rows = db().execute(\n        \"SELECT code, url FROM links WHERE url LIKE ?\", (f\"%{q}%\",)\n    ).fetchall()\n    return render_template_string(PAGE, q=q, rows=rows)\n\n", "note": "The fix for the injection. The SQL has a `?` where the value goes, and the value, with its `%` wildcards around it, travels separately as a parameter. SQLite never reads the search text as SQL, so a quote in it is only a quote."}, {"code": "@app.get(\"/<code>\")\ndef follow(code):\n    row = db().execute(\"SELECT url FROM links WHERE code = ?\", (code,)).fetchone()\n    if row is None:\n        abort(404)\n    return redirect(row[0])", "note": "`follow()` was already right. The `if __name__ == \"__main__\"` block that ran Flask with `debug=True` is gone: gunicorn starts the service and never ran it, and a development server is started on purpose, with `flask --app app run --debug`, on your own machine only."}]}
```

**The debugger line deserves its own sentence.** `app.run(debug=True)` starts Werkzeug's
development server with its interactive debugger, which turns any error into a page where Python
can be typed and run on the server. It is protected by a PIN printed to the console, and it is
still a way to run code on the machine for whoever can reach the page. In linkbox it never ran,
because the image starts gunicorn, and that is exactly why it is worth removing: **dead code that
becomes live by accident** is a `python app.py` on a server, one afternoon, to try something.

### The tests, and the scanners

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q
....                                                                     [100%]
4 passed in 0.22s
ana@vm:~/linkbox$ bash ci/sast.sh; echo "exit $?"
exit 0
```

Four tests pass, the new one included, and both tools are quiet. Bandit still knows about the
token; ask it for the low findings too and it is there:

```
ana@vm:~/linkbox$ bandit -q -r . -c bandit.yaml --format custom --msg-template "{relpath}:{line} {test_id} {severity}/{confidence} {msg}"
settings.py:4 B105 LOW/MEDIUM Possible hardcoded password: 'lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x'
```

That is the finding this lesson leaves open on purpose, and the gate's threshold is what lets it
through. Lesson 6 replaces the token with a new one first, and only then takes it out of the code.

### Green again

```
ana@vm:~/linkbox$ git add app.py tests/test_app.py
ana@vm:~/linkbox$ git commit -q -m "the search takes a parameter, writes call require_token(), no debug server"
ana@vm:~/linkbox$ git push ci main
remote: run 2: main at 999ebb9        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: build: passed in 1s        
remote: pipeline passed        
remote: run 2: passed        
To /home/ana/ci/linkbox.git
   f4992c6..999ebb9  main -> main
```

The second run passes every stage. The test that proves each fix is in the same commit as the fix,
so every later push runs it, and both stay fixed. If somebody writes the search with an f-string
again, the static analysis stage stops them; if they write it some way the rule does not match, the
test does.
