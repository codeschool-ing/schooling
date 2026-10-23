---
title: The headers, the test that keeps them, and a false positive
version: 1
---

The scan said three headers are missing. The fix is three lines, and the order is the course's
usual one: **a test that fails because the defect is there, then the change, then the same test
passing.** The scan is not that test. It runs once a day, takes about twenty seconds and reports
a URL. A unit test runs on every push, in under a second, and its name says what broke.

### The test first

The new test asks for the home page and checks the three headers. Save the file as
`tests/test_app.py`:

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


def test_every_answer_carries_the_headers(client):
    page = client.get("/")
    assert page.headers["X-Content-Type-Options"] == "nosniff"
    assert page.headers["X-Frame-Options"] == "DENY"
    assert "frame-ancestors 'none'" in page.headers["Content-Security-Policy"]
```

The test fails on lesson 3's code, which is the proof that it tests something:

```
ana@vm:~/linkbox$ uv venv -q && uv pip install -q -r requirements.txt -r requirements-dev.txt
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q --tb=short
....F                                                                    [100%]
=================================== FAILURES ===================================
____________________ test_every_answer_carries_the_headers _____________________
tests/test_app.py:45: in test_every_answer_carries_the_headers
    assert page.headers["X-Content-Type-Options"] == "nosniff"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.venv/lib/python3.13/site-packages/werkzeug/datastructures/headers.py:72: in __getitem__
    raise BadRequestKeyError(key)
E   werkzeug.exceptions.BadRequestKeyError: 400 Bad Request: The browser (or proxy) sent a request that this server could not understand.
=========================== short test summary info ============================
FAILED tests/test_app.py::test_every_answer_carries_the_headers - werkzeug.ex...
1 failed, 4 passed in 0.42s
```

`BadRequestKeyError` is Werkzeug's own kind of `KeyError`: the response has no
`X-Content-Type-Options` at all, so reading it raises before the comparison is made.

### The fix

One function, registered with `after_request`, adds the headers to every response. Save the file
as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "\"\"\"linkbox: short links for a small team, kept in one SQLite file.\"\"\"\nimport secrets\nimport sqlite3\n\nfrom flask import Flask, abort, g, redirect, render_template_string, request\n\nfrom settings import ADMIN_TOKEN, DATABASE\n\napp = Flask(__name__)\n", "note": "Lesson 3's service, unchanged down to the page template."}, {"code": "PAGE = \"\"\"<!doctype html>\n<title>linkbox</title>\n<form action=\"/search\"><input name=\"q\" value=\"{{ q }}\"><button>Search</button></form>\n<ul>{% for code, url in rows %}<li><a href=\"/{{ code }}\">{{ code }}</a> {{ url }}</li>{% endfor %}</ul>\n\"\"\"\n\n", "note": "The search box writes the text typed back into the `value` attribute of the input. Jinja escapes it on the way in, which is what decides the warning ZAP still raises after the fix."}, {"code": "def db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(DATABASE)\n        g.db.execute(\"CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT)\")\n    return g.db\n\n"}, {"code": "@app.after_request\ndef security_headers(response):", "note": "The new part. Flask calls an `after_request` function on every response it sends, the 404s included, so no route has to remember the headers and a route added next year gets them too."}, {"code": "    response.headers[\"Content-Security-Policy\"] = (\n        \"default-src 'none'; form-action 'self'; frame-ancestors 'none'\"\n    )", "note": "The policy: nothing loads unless a directive allows it. The page uses no script, style or image, so the default is `'none'`; the search form may submit only to this origin; and no other page may put this one in a frame. `secure-code` lesson 8 teaches the directives."}, {"code": "    response.headers[\"X-Content-Type-Options\"] = \"nosniff\"", "note": "The browser must believe the `Content-Type` the server sends rather than guess one from the bytes."}, {"code": "    response.headers[\"X-Frame-Options\"] = \"DENY\"\n    return response\n\n", "note": "The older header that refuses framing, for browsers that do not read `frame-ancestors`."}, {"code": "@app.teardown_appcontext\ndef close_db(_):\n    conn = g.pop(\"db\", None)\n    if conn is not None:\n        conn.close()\n\n\ndef require_token():\n    sent = request.headers.get(\"X-Token\", \"\")\n    if not secrets.compare_digest(sent, ADMIN_TOKEN):\n        abort(401)\n\n\n@app.post(\"/links\")\ndef create():\n    require_token()\n    code = secrets.token_urlsafe(4)\n    db().execute(\"INSERT INTO links VALUES (?, ?)\", (code, request.form[\"url\"]))\n    db().commit()\n    return {\"code\": code}, 201\n\n\n@app.get(\"/\")\n@app.get(\"/search\")\ndef search():\n    q = request.args.get(\"q\", \"\")\n    rows = db().execute(\n        \"SELECT code, url FROM links WHERE url LIKE ?\", (f\"%{q}%\",)\n    ).fetchall()\n    return render_template_string(PAGE, q=q, rows=rows)\n\n\n@app.get(\"/<code>\")\ndef follow(code):\n    row = db().execute(\"SELECT url FROM links WHERE code = ?\", (code,)).fetchone()\n    if row is None:\n        abort(404)\n    return redirect(row[0])"}]}
```

The values are the strictest this page allows, and that is a choice worth making on a page this
small. A page that loads scripts from a content delivery network, or styles inline, needs a longer
policy, and writing one is `secure-code` lesson 8's subject. What matters to the pipeline is that
the policy is in the code, under a test, and not in a proxy configuration nobody versions.

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q
.....                                                                    [100%]
5 passed in 0.14s
```

### The scan agrees, almost

Build the image again and run the stage:

```
ana@vm:~/linkbox$ bash ci/build.sh
sha256:9bc6c45b950209db1d54ef697dc38ac6179f1774610b72101332d13faf5be90f
ana@vm:~/linkbox$ bash ci/dast.sh > /tmp/dast.log; echo "exit status $?"
2026-10-23 04:47:24,188 Unable to copy yaml file to /zap/wrk/zap.yaml [Errno 30] Read-only file system: '/zap/wrk/zap.yaml'
exit status 0
ana@vm:~/linkbox$ grep -v ^PASS /tmp/dast.log
Using the Automation Framework
Total of 4 URLs
WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
	http://linkbox-staging-6852-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 60
```

**Exit status 0, and one warning left: 10031.** The three header rules now pass on every URL the
spider found, which makes 60 passing rules, and two of those URLs were 404 pages. The headers are on
those too, because `after_request` runs on Flask's 404 pages as well. The test does not ask about a
404, so check it once by hand: start the new image with the two commands of the staging section,
then ask it for a page that does not exist and for the search twice:

```
ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -sI http://linkbox-app:8000/nothing-here
HTTP/1.1 404 NOT FOUND
Server: gunicorn
Date: Fri, 23 Oct 2026 04:47:43 GMT
Connection: close
Content-Type: text/html; charset=utf-8
Content-Length: 207
Content-Security-Policy: default-src 'none'; form-action 'self'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY

ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -s "http://linkbox-app:8000/search?q=ZAP"
<!doctype html>
<title>linkbox</title>
<form action="/search"><input name="q" value="ZAP"><button>Search</button></form>
<ul></ul>
ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -s "http://linkbox-app:8000/search?q=a%22b"
<!doctype html>
<title>linkbox</title>
<form action="/search"><input name="q" value="a&#34;b"><button>Search</button></form>
<ul></ul>
```

The first command is the evidence for the 404 page. The other two are the evidence for 10031.

### Deciding that 10031 is a false positive

Rule 10031 looks for **a value the scanner sent that comes back inside an HTML attribute**. The
search writes the text typed into the box's `value` attribute, so the word `ZAP` comes back as
`value="ZAP"`, and the rule matches. What the rule is worried about is a value written into an
attribute without escaping. Then a double quote typed in the box would end the attribute, and
whatever followed it would be read by the browser as markup: that is cross-site scripting, a page
that runs what a stranger typed.

The rule cannot tell an escaped value from one that is not. It sent a plain word, saw it come back,
and warned. **The decision has to be made from the response, by a person**, and the third command
above makes it: the search was sent a double quote, and the page wrote it as `&#34;`, the escaped
form. Jinja escapes every value it puts into a template rendered with `render_template_string`, so
a quote cannot end the attribute. Lesson 3's `test_search_survives_a_quote` already holds the same
behaviour for an apostrophe, `&#39;`, so the escaping is under a test as well.

So 10031 is a false positive **for this page, as written today**. That last clause is why the rule
stays a WARN and is not set to IGNORE. The configuration file works per rule, not per URL or per
parameter: IGNORE would silence 10031 for every page linkbox will ever have, including one written
next year that marks a value `|safe` and turns the escaping off. Left as a WARN, the finding stays
visible, and the reason it is accepted belongs beside it, where the next person to read the scan
will find it. Lesson 7 gives that reason a place: an exception with an owner and a date, which the
gate honours until the date passes.

| finding | decision | why |
|---|---|---|
| 10020, 10021, 10038 | fixed, rules set to FAIL | real, fixed in the code, held by a unit test and by the scan |
| 10031 | false positive, left at WARN | the value is escaped, which the response shows; IGNORE would hide a real one later |

### What changed, and what did not

Before the fix, linkbox's responses could be framed, sniffed and loaded with anything. After it,
a browser refuses all three. Nothing about the search's escaping changed: it was safe before, and
the scan's one remaining warning is the scan being careful rather than linkbox being wrong.
