#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/console.
# app.py and test_app.py are taken from the-console.md by lab/extract.py, so
# the program the lesson prints is the program that ran. Each fix is the
# change its section describes, applied by an exact string replacement, and
# `git diff` shows it. The decorator one-decorator.md prints is checked
# against the file after the fix, so the two cannot drift.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The commits carry fixed dates, so their hashes repeat.
#   - In "curl-open" and "curl-closed" the server was started in the
#     background by serve() and the request comes from the same machine, as
#     from a second terminal. The Date header is the recording's.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/console
rm -rf "$D"

block setup
run /home/ana/sc 'mkdir console'
run /home/ana/sc 'cd console'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put the-console.md app.py $D/app.py
put the-console.md test_app.py $D/test_app.py

serve $D 'flask --app app run'
block curl-open
run $D 'curl -si http://127.0.0.1:5000/export'
unserve

block red
run $D 'pytest -q --tb=no'

block commit
export GIT_AUTHOR_DATE='2026-11-11 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-11 09:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -q -m "Staff console: agenda, clinical notes and the export"'

fix() {  # fix 'old' 'new': one exact replacement in app.py, which must match once
  python3 - "$1" "$2" <<'PY'
import sys
p = '/home/ana/sc/console/app.py'
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

# One decorator, on the two routes the tests named.
fix 'import secrets
' 'import secrets
from functools import wraps
'
fix '  <input type="hidden" name="role" value="physio">
' ''
fix '    return name


@app.get("/console")' '    return name


def requires(*roles):
    def decorate(view):
        @wraps(view)
        def checked(*args, **kwargs):
            name = session.get("staff")
            if name not in STAFF:
                abort(401)
            if STAFF[name] not in roles:
                abort(403)
            return view(*args, **kwargs)

        checked.allowed_roles = roles
        return checked

    return decorate


@app.get("/console")'
fix '@app.get("/patients/<name>/notes")
def read_notes(name):
    signed_in()
' '@app.get("/patients/<name>/notes")
@requires("physio")
def read_notes(name):
'
fix '@app.post("/patients/<name>/notes")
def add_note(name):
    signed_in()
    if request.form.get("role") != "physio":
        abort(403)
' '@app.post("/patients/<name>/notes")
@requires("physio")
def add_note(name):
'
python3 - "$LESSON/one-decorator.md" <<'PY'
import json, re, sys
body = re.search(r"```schooling-example\n(.*?)\n```", open(sys.argv[1]).read(), re.S).group(1)
shown = "\n".join(p["code"] for p in json.loads(body)["parts"])
assert shown in open('/home/ana/sc/console/app.py').read(), "one-decorator.md differs from app.py"
PY
[ $? = 0 ] || exit 1
block diff-notes
run $D 'git diff'
block green-notes
run $D 'pytest -q --tb=no'
export GIT_AUTHOR_DATE='2026-11-11 09:30:00 -0300' GIT_COMMITTER_DATE='2026-11-11 09:30:00 -0300'
run $D 'git commit -qam "Check the role on the server for clinical notes"'

block open-routes
run $D 'pytest -q --tb=short -k every_route'

# Every route declares who may use it.
fix 'def signed_in():
    name = session.get("staff")
    if name is None:
        abort(401)
    return name


' ''
fix '@app.get("/console")
def console():
    name = signed_in()
    return render_template_string(PAGE, name=name, role=STAFF.get(name))
' '@app.get("/console")
@requires("reception", "physio", "admin")
def console():
    name = session["staff"]
    return render_template_string(PAGE, name=name, role=STAFF[name])
'
fix '@app.get("/agenda")
def agenda():
    signed_in()
' '@app.get("/agenda")
@requires("reception", "physio", "admin")
def agenda():
'
fix '@app.get("/export")
def export():' '@app.get("/export")
@requires("admin")
def export():'
block diff-routes
run $D 'git diff'
block green-routes
run $D 'pytest -q'

block commit-fix
export GIT_AUTHOR_DATE='2026-11-11 10:00:00 -0300' GIT_COMMITTER_DATE='2026-11-11 10:00:00 -0300'
run $D 'git commit -qam "Every route says who may use it"'
run $D 'git log --oneline'

serve $D 'flask --app app run'
block curl-closed
run $D 'curl -si http://127.0.0.1:5000/export'
unserve
