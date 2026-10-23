#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/csrf.
# app.py and test_app.py are taken from the-portal.md by lab/extract.py, so
# the program the lesson prints is the program that ran. Each fix is the
# change its section describes, applied by an exact string replacement, and
# `git diff` shows it. No page on another site is built or served: the
# forged request is shown as the portal receives it, from the test client.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/csrf
rm -rf "$D"

block setup
run /home/ana/sc 'mkdir csrf'
run /home/ana/sc 'cd csrf'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put the-portal.md app.py $D/app.py
put the-portal.md test_app.py $D/test_app.py

block red
run $D 'pytest -q --tb=no'

block commit
export GIT_AUTHOR_DATE='2026-11-13 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-13 09:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -q -m "Change the e-mail address and the phone number"'

fix() {  # fix 'old' 'new': one exact replacement in app.py, which must match once
  python3 - "$1" "$2" <<'PY'
import sys
p = '/home/ana/sc/csrf/app.py'
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

# The token.
fix '<form method="post" action="/account/email">
' '<form method="post" action="/account/email">
  <input type="hidden" name="csrf" value="{{ csrf_token() }}">
'
fix '<form method="post" action="/account/phone">
' '<form method="post" action="/account/phone">
  <input type="hidden" name="csrf" value="{{ csrf_token() }}">
'
fix '    return name


@app.get("/account")' '    return name


def csrf_token():
    if "csrf" not in session:
        session["csrf"] = secrets.token_urlsafe(32)
    return session["csrf"]


app.jinja_env.globals["csrf_token"] = csrf_token


@app.before_request
def refuse_cross_site_changes():
    if request.method in ("GET", "HEAD", "OPTIONS"):
        return
    expected = session.get("csrf")
    sent = request.form.get("csrf", "")
    if not expected or not secrets.compare_digest(sent.encode(), expected.encode()):
        abort(403)


@app.get("/account")'
block diff-token
run $D 'git diff'
block green-token
run $D 'pytest -q --tb=no'
export GIT_AUTHOR_DATE='2026-11-13 09:30:00 -0300' GIT_COMMITTER_DATE='2026-11-13 09:30:00 -0300'
run $D 'git commit -qam "Refuse a change without the session'"'"'s token"'

# SameSite, and the origin.
fix 'app.secret_key = secrets.token_bytes(32)
' 'app.secret_key = secrets.token_bytes(32)
app.config.update(SESSION_COOKIE_SAMESITE="Lax", SESSION_COOKIE_SECURE=True)
'
fix '        return
    expected = session.get("csrf")' '        return
    origin = request.headers.get("Origin")
    if origin is not None and origin != request.host_url.rstrip("/"):
        abort(403)
    expected = session.get("csrf")'
block diff-origin
run $D 'git diff'
block green-origin
run $D 'pytest -q'

block commit-fix
export GIT_AUTHOR_DATE='2026-11-13 09:45:00 -0300' GIT_COMMITTER_DATE='2026-11-13 09:45:00 -0300'
run $D 'git commit -qam "Keep the session cookie to its own site, and check the origin"'
run $D 'git log --oneline'
