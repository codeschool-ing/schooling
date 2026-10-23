---
title: linkbox, the project you inherit
version: 1
---

Every lesson of this course works on one small service, **linkbox**: short links for a team, the
kind that turns `https://example.org/docs/handbook/onboarding` into a slash and six characters. It is written in
Python with Flask and keeps its links in an SQLite file. The language is incidental; what the
course does to its pipeline is the same for a Go service or a Node one.

**You inherit it, the way most code is met at work.** It runs, its tests pass, and somebody built
it in a hurry. It carries at least four security defects, and that is deliberate: lessons 3 to 6
find them with tools, one class of tool per lesson, and fix each one with a test that proves the
fix. Reading the code now and spotting them is a good exercise. Fixing them now would leave those
lessons nothing to find, so leave them in.

### The files

Make the project's directory and start a repository in it:

```
ana@vm:~$ mkdir linkbox && cd linkbox
ana@vm:~/linkbox$ git init
Initialized empty Git repository in /home/ana/linkbox/.git/
```

The service is one file. Save it as `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "\"\"\"linkbox: short links for a small team, kept in one SQLite file.\"\"\"\nimport secrets\nimport sqlite3\n\nfrom flask import Flask, abort, g, redirect, render_template_string, request\n\nfrom settings import ADMIN_TOKEN, DATABASE\n", "note": "One file, one table and three routes. Everything the service knows is in an SQLite file whose name comes from `settings.py`."}, {"code": "app = Flask(__name__)\n\nPAGE = \"\"\"<!doctype html>\n<title>linkbox</title>\n<form action=\"/search\"><input name=\"q\" value=\"{{ q }}\"><button>Search</button></form>\n<ul>{% for code, url in rows %}<li><a href=\"/{{ code }}\">{{ code }}</a> {{ url }}</li>{% endfor %}</ul>\n\"\"\"\n\n", "note": "The page is a template string: a search box and the list of links that match it."}, {"code": "def db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(DATABASE)\n        g.db.execute(\"CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT)\")\n    return g.db\n\n", "note": "One connection per request, opened the first time a route asks for it. The table is created if it is not there yet, so a new database file needs no setup step."}, {"code": "@app.teardown_appcontext\ndef close_db(_):\n    conn = g.pop(\"db\", None)\n    if conn is not None:\n        conn.close()\n\n", "note": "The connection is closed when the request ends, whatever the route did."}, {"code": "@app.post(\"/links\")\ndef create():\n    if request.headers.get(\"X-Token\") != ADMIN_TOKEN:\n        abort(401)\n    code = secrets.token_urlsafe(4)\n    db().execute(\"INSERT INTO links VALUES (?, ?)\", (code, request.form[\"url\"]))\n    db().commit()\n    return {\"code\": code}, 201\n\n", "note": "Creating a link needs the administration token in an `X-Token` header. The short code is four random bytes, written as six URL-safe characters."}, {"code": "@app.get(\"/\")\n@app.get(\"/search\")\ndef search():\n    q = request.args.get(\"q\", \"\")\n    rows = db().execute(f\"SELECT code, url FROM links WHERE url LIKE '%{q}%'\").fetchall()\n    return render_template_string(PAGE, q=q, rows=rows)\n\n", "note": "The front page and the search are the same route: every link whose address contains the text typed, or every link when nothing was typed."}, {"code": "@app.get(\"/<code>\")\ndef follow(code):\n    row = db().execute(\"SELECT url FROM links WHERE code = ?\", (code,)).fetchone()\n    if row is None:\n        abort(404)\n    return redirect(row[0])\n\n", "note": "Following a code answers with a redirect to the address it stands for, or a 404."}, {"code": "if __name__ == \"__main__\":\n    app.run(debug=True)", "note": "Run as `python app.py`, the file starts Flask's own development server."}]}
```

The settings are a second file, so the tests can point the database somewhere else. Save it as
`settings.py`:

```python
import os

DATABASE = os.environ.get("LINKBOX_DB", "linkbox.db")
ADMIN_TOKEN = "lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x"
```

The dependencies, every one pinned to an exact version, as they were the day the project was
handed over. Save them as `requirements.txt`:

```
flask==3.0.0
werkzeug==3.0.1
jinja2==3.1.2
markupsafe==2.1.3
itsdangerous==2.1.2
click==8.1.7
blinker==1.7.0
gunicorn==21.2.0
```

What only the tests need, as `requirements-dev.txt`:

```
pytest==8.4.2
```

Three tests: a link cannot be made without the token, a link redirects, and the search finds what
was saved. Each test gets a database of its own in a temporary directory. Save them as
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
```

The image the service runs in. It is the shortest Dockerfile that works, and lesson 8 takes it
apart. Save it as `Dockerfile`:

```dockerfile
FROM python:3.13
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

What git should never record, as `.gitignore`:

```
.venv/
__pycache__/
.pytest_cache/
*.db
*.pid
ci-logs/
```

And what `docker build` should never copy into the image, as `.dockerignore`:

```
.venv
.git
*.db
```

### Run the tests

A virtual environment keeps the pinned packages inside the project. `uv venv` makes it and
`uv pip install` fills it, in a few seconds, because uv resolves and installs in parallel:

```
ana@vm:~/linkbox$ uv venv
Using CPython 3.13.16 interpreter at: /usr/bin/python
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
ana@vm:~/linkbox$ uv pip install -r requirements.txt -r requirements-dev.txt
Resolved 13 packages in 548ms
Downloading pygments (1.2MiB)
   Building markupsafe==2.1.3
 Downloaded pygments
      Built markupsafe==2.1.3
Prepared 13 packages in 1.33s
Installed 13 packages in 15ms
 + blinker==1.7.0
 + click==8.1.7
 + flask==3.0.0
 + gunicorn==21.2.0
 + iniconfig==2.3.1
 + itsdangerous==2.1.2
 + jinja2==3.1.2
 + markupsafe==2.1.3
 + packaging==26.3
 + pluggy==1.7.0
 + pygments==2.21.0
 + pytest==8.4.2
 + werkzeug==3.0.1
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q
...                                                                      [100%]
3 passed in 0.42s
```

### Use it

gunicorn is the server the image runs, and it runs on your machine the same way. `--daemon` puts it
in the background and `--pid` writes down its process number, so you can stop it afterwards:

```
ana@vm:~/linkbox$ .venv/bin/gunicorn --daemon --pid linkbox.pid --bind 127.0.0.1:8000 app:app
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x" -d url=https://example.org/docs/handbook/onboarding http://127.0.0.1:8000/links
{"code":"kJOsxQ"}
ana@vm:~/linkbox$ code=$(curl -s -X POST -H "X-Token: lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x" -d url=https://example.org/status http://127.0.0.1:8000/links | jq -r .code)
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" http://127.0.0.1:8000/$code
302 https://example.org/status
ana@vm:~/linkbox$ curl -s "http://127.0.0.1:8000/search?q=handbook"
<!doctype html>
<title>linkbox</title>
<form action="/search"><input name="q" value="handbook"><button>Search</button></form>
<ul><li><a href="/kJOsxQ">kJOsxQ</a> https://example.org/docs/handbook/onboarding</li></ul>
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -d url=https://example.org http://127.0.0.1:8000/links
401
ana@vm:~/linkbox$ kill $(cat linkbox.pid)
```

Five requests: two links made, one followed, a search, and an attempt with no token, which answers
`401`. The token is in `settings.py` for anybody who can read the file, which is one of the four
defects, and it waits for lesson 6. The codes are random, so yours differ.

### The first commit

```
ana@vm:~/linkbox$ git add -A
ana@vm:~/linkbox$ git status --short
A  .dockerignore
A  .gitignore
A  Dockerfile
A  app.py
A  requirements-dev.txt
A  requirements.txt
A  settings.py
A  tests/test_app.py
ana@vm:~/linkbox$ git commit -q -m "linkbox as it was handed over"
ana@vm:~/linkbox$ git log --oneline
3215f0f linkbox as it was handed over
```
