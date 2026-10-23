#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/search.
# app.py, test_app.py and orm.py are taken from the lesson's own listings by
# lab/extract.py. Each fix is the change its section describes, applied by an
# exact string replacement, and `git diff` shows it. Every input shown is one
# a receptionist could type: a surname with an apostrophe, a sort nobody
# offered, a percent sign.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Before "install", SQLAlchemy and its dependencies are removed without
#     printing anything, so the install shown is a first install.
#   - In "curl" and "percent" the portal was started in the background by
#     serve(), as from a second terminal. The Date header is the recording's.
#   - patients.db is listed in .gitignore, written without being shown, so
#     the commits hold only the code.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/search
rm -rf "$D"
( . /home/ana/sc/.venv/bin/activate && flock /var/tmp/secure-code-pip.lock pip uninstall -q -y sqlalchemy ) >/dev/null 2>&1

block setup
run /home/ana/sc 'mkdir search'
run /home/ana/sc 'cd search'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example
printf 'patients.db\n__pycache__/\n' > $D/.gitignore

put the-search.md app.py $D/app.py
put the-search.md test_app.py $D/test_app.py

block init
run $D 'flask --app app init-db'
serve $D 'flask --app app run'
block curl
run $D "curl -si -G --data-urlencode \"surname=D'Ávila\" http://127.0.0.1:5000/patients"
unserve

block red
run $D 'pytest -q --tb=no'
block apostrophe
run $D 'pytest -q --tb=short -k apostrophe'

block commit
export GIT_AUTHOR_DATE='2026-11-05 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-05 09:00:00 -0300'
run $D 'git add .gitignore app.py test_app.py'
run $D 'git commit -q -m "Search patients by surname, sorted"'

fix() {  # fix 'old' 'new': one exact replacement in app.py, which must match once
  python3 - "$1" "$2" <<'PY'
import sys
p = '/home/ana/sc/search/app.py'
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

# Placeholders, and an allowlist for the sort.
fix ']


def db():' ']
SORTS = {"surname": "surname", "clinic": "clinic, surname"}


def db():'
fix '    order = request.args.get("sort", "surname")
    rows = db().execute(
        f"SELECT first_name, surname, clinic FROM patients "
        f"WHERE surname LIKE '"'"'%{term}%'"'"' ORDER BY {order}"
    )' '    order = SORTS.get(request.args.get("sort", "surname"))
    if order is None:
        abort(400)
    rows = db().execute(
        "SELECT first_name, surname, clinic FROM patients "
        f"WHERE surname LIKE ? ORDER BY {order}",
        (f"%{term}%",),
    )'
block diff-params
run $D 'git diff'
block green-params
run $D 'pytest -q --tb=no'
block commit-params
export GIT_AUTHOR_DATE='2026-11-05 09:30:00 -0300' GIT_COMMITTER_DATE='2026-11-05 09:30:00 -0300'
run $D 'git commit -qam "Pass the surname as a parameter, and allowlist the sort"'

serve $D 'flask --app app run'
block percent
run $D "curl -s -G --data-urlencode 'surname=%' http://127.0.0.1:5000/patients"
unserve

# LIKE wildcards.
fix '@app.get("/patients")' 'def like_pattern(term):
    escaped = term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    return f"%{escaped}%"


@app.get("/patients")'
fix '        f"WHERE surname LIKE ? ORDER BY {order}",
        (f"%{term}%",),' '        f"WHERE surname LIKE ? ESCAPE '"'"'\\'"'"' ORDER BY {order}",
        (like_pattern(term),),'
block diff-like
run $D 'git diff'
block green-like
run $D 'pytest -q'
block commit-fix
export GIT_AUTHOR_DATE='2026-11-05 09:45:00 -0300' GIT_COMMITTER_DATE='2026-11-05 09:45:00 -0300'
run $D 'git commit -qam "Search for % and _ literally"'
run $D 'git log --oneline'

# The ORM.
block install
run $D 'pip install --progress-bar off sqlalchemy==2.1.6'
put orm.md orm.py $D/orm.py
block orm
run $D "python3 orm.py 2>&1 | grep -v '^ '"
