"""linkbox: short links for a small team, kept in one SQLite file."""
import secrets
import sqlite3

from flask import Flask, abort, g, redirect, render_template_string, request

from settings import ADMIN_TOKEN, DATABASE

app = Flask(__name__)

PAGE = """<!doctype html>
<title>linkbox</title>
<form action="/search"><input name="q" value="{{ q }}"><button>Search</button></form>
<ul>{% for code, url in rows %}<li><a href="/{{ code }}">{{ code }}</a> {{ url }}</li>{% endfor %}</ul>
"""


def db():
    if "db" not in g:
        g.db = sqlite3.connect(DATABASE)
        g.db.execute("CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT)")
    return g.db


@app.after_request
def security_headers(response):
    response.headers["Content-Security-Policy"] = (
        "default-src 'none'; form-action 'self'; frame-ancestors 'none'"
    )
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    return response


@app.teardown_appcontext
def close_db(_):
    conn = g.pop("db", None)
    if conn is not None:
        conn.close()


def require_token():
    sent = request.headers.get("X-Token", "")
    if not secrets.compare_digest(sent, ADMIN_TOKEN):
        abort(401)


@app.post("/links")
def create():
    require_token()
    code = secrets.token_urlsafe(4)
    db().execute("INSERT INTO links VALUES (?, ?)", (code, request.form["url"]))
    db().commit()
    return {"code": code}, 201


@app.get("/")
@app.get("/search")
def search():
    q = request.args.get("q", "")
    rows = db().execute(
        "SELECT code, url FROM links WHERE url LIKE ?", (f"%{q}%",)
    ).fetchall()
    return render_template_string(PAGE, q=q, rows=rows)


@app.get("/<code>")
def follow(code):
    row = db().execute("SELECT url FROM links WHERE code = ?", (code,)).fetchone()
    if row is None:
        abort(404)
    return redirect(row[0])
