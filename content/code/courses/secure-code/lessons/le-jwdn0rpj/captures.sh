#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/sessions.
# app.py and test_app.py are taken from the-portal.md by lab/extract.py, so
# the program the lesson prints is the program that ran. Each fix is the
# change its section describes, applied by an exact string replacement, and
# `git diff` shows it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The commits carry fixed dates, so their hashes repeat.
#   - In "curl" the server was started in the background by serve() and the
#     request comes from the same machine, as from a second terminal. The
#     session id it prints is random and differs on every run.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/sessions
rm -rf "$D"

block setup
run /home/ana/sc 'mkdir sessions'
run /home/ana/sc 'cd sessions'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put the-portal.md app.py $D/app.py
put the-portal.md test_app.py $D/test_app.py

block red
run $D 'pytest -q --tb=no'

block commit
export GIT_AUTHOR_DATE='2026-11-09 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-09 09:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -q -m "Sign patients in with a server-side session"'

fix() {  # fix 'old' 'new': one exact replacement in app.py, which must match once
  python3 - "$1" "$2" <<'PY'
import sys
p = '/home/ana/sc/sessions/app.py'
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

# Born: a random id, and a cookie with its three attributes.
fix 'import hashlib
' 'import secrets
'
fix 'def new_session_id(name):
    return hashlib.md5(f"{name}{now():%Y%m%d%H%M}".encode()).hexdigest()
' 'def new_session_id():
    return secrets.token_urlsafe(32)


def set_sid(response, sid):
    response.set_cookie("sid", sid, httponly=True, secure=True, samesite="Lax")
'
fix 'new_session_id("visitor")' 'new_session_id()'
fix 'new_session_id(name)' 'new_session_id()'
fix '        response.set_cookie("sid", sid)
' '        set_sid(response, sid)
'
fix '    response.set_cookie("sid", sid)
    return response
' '    set_sid(response, sid)
    return response
'
block diff-born
run $D 'git diff'
block green-born
run $D 'pytest -q --tb=no'
export GIT_AUTHOR_DATE='2026-11-09 09:20:00 -0300' GIT_COMMITTER_DATE='2026-11-09 09:20:00 -0300'
run $D 'git commit -qam "Draw session ids from secrets, and mark the cookie"'

serve $D 'flask --app app run'
block curl
run $D "curl -si -d name=lucia -d password=lucia-pw http://127.0.0.1:5000/sign-in"
unserve

# Rotated and expired.
fix 'from datetime import datetime
' 'from datetime import datetime, timedelta
'
fix 'SESSIONS = {}
' 'SESSIONS = {}
IDLE = timedelta(minutes=15)
ABSOLUTE = timedelta(hours=8)
'
fix '    record = SESSIONS.get(request.cookies.get("sid"))
    if record is None or record["patient"] is None:
        abort(401)
    return record["patient"]
' '    sid = request.cookies.get("sid")
    record = SESSIONS.get(sid)
    if record is None or record["patient"] is None:
        abort(401)
    if now() - record["seen"] > IDLE or now() - record["created"] > ABSOLUTE:
        del SESSIONS[sid]
        abort(401)
    record["seen"] = now()
    return record["patient"]
'
fix '    sid = request.cookies.get("sid")
    if sid not in SESSIONS:
        sid = new_session_id()
    SESSIONS[sid] = {"patient": name}
' '    SESSIONS.pop(request.cookies.get("sid"), None)
    sid = new_session_id()
    SESSIONS[sid] = {"patient": name, "created": now(), "seen": now()}
'
block diff-rotate
run $D 'git diff'
block green-rotate
run $D 'pytest -q --tb=no'
export GIT_AUTHOR_DATE='2026-11-09 09:50:00 -0300' GIT_COMMITTER_DATE='2026-11-09 09:50:00 -0300'
run $D 'git commit -qam "Issue a new id at sign-in, and expire idle and old sessions"'

# Ended.
fix '    response = jsonify(signed_out=True)
' '    SESSIONS.pop(request.cookies.get("sid"), None)
    response = jsonify(signed_out=True)
'
block diff-end
run $D 'git diff'
block green-end
run $D 'pytest -q'

block commit-fix
export GIT_AUTHOR_DATE='2026-11-09 10:05:00 -0300' GIT_COMMITTER_DATE='2026-11-09 10:05:00 -0300'
run $D 'git commit -qam "End the session on the server at sign-out"'
run $D 'git log --oneline'
