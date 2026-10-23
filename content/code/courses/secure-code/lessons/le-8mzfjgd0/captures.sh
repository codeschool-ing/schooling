#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/exams.
# app.py and test_app.py are taken from the-portal.md by lab/extract.py, so
# the program the lesson prints is the program that ran. Each fix is the
# change its section describes, applied by an exact string replacement, and
# `git diff` shows it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/exams
rm -rf "$D"

block setup
run /home/ana/sc 'mkdir exams'
run /home/ana/sc 'cd exams'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put the-portal.md app.py $D/app.py
put the-portal.md test_app.py $D/test_app.py

block red
run $D 'pytest -q --tb=no'

block grid
run $D "pytest -q --tb=short -k 'owner and rafael'"

block commit
export GIT_AUTHOR_DATE='2026-11-12 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-12 09:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -q -m "List, show and delete a patient'"'"'s exams"'

fix() {  # fix 'old' 'new': one exact replacement in app.py, which must match once
  python3 - "$1" "$2" <<'PY'
import sys
p = '/home/ana/sc/exams/app.py'
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

# The owner inside the query.
fix '    return name


@app.get("/exams")' '    return name


def own_exam(exam_id):
    row = db().execute(
        "SELECT id, title, taken FROM exams WHERE id = ? AND patient = ?",
        (exam_id, signed_in()),
    ).fetchone()
    if row is None:
        abort(404)
    return row


@app.get("/exams")'
fix '    signed_in()
    row = db().execute("SELECT id, title, taken FROM exams WHERE id = ?", (exam_id,)).fetchone()
    if row is None:
        abort(404)
    return jsonify(dict(row))
' '    return jsonify(dict(own_exam(exam_id)))
'
fix '    signed_in()
    db().execute("DELETE FROM exams WHERE id = ?", (exam_id,))
' '    exam = own_exam(exam_id)
    db().execute("DELETE FROM exams WHERE id = ?", (exam["id"],))
'
block diff-scoped
run $D 'git diff'
block green-scoped
run $D 'pytest -q --tb=no'
export GIT_AUTHOR_DATE='2026-11-12 09:30:00 -0300' GIT_COMMITTER_DATE='2026-11-12 09:30:00 -0300'
run $D 'git commit -qam "Read and delete an exam only for its owner"'

# The owner from the session, in the list too.
fix '    name = request.args.get("patient", signed_in())
    rows = db().execute("SELECT id, title, taken FROM exams WHERE patient = ?", (name,))
' '    rows = db().execute("SELECT id, title, taken FROM exams WHERE patient = ?", (signed_in(),))
'
fix 'from flask import Flask, abort, g, jsonify, request, session' 'from flask import Flask, abort, g, jsonify, session'
block diff-list
run $D 'git diff'
block green-list
run $D 'pytest -q'

block commit-fix
export GIT_AUTHOR_DATE='2026-11-12 09:45:00 -0300' GIT_COMMITTER_DATE='2026-11-12 09:45:00 -0300'
run $D 'git commit -qam "List only the signed-in patient'"'"'s exams"'
run $D 'git log --oneline'
