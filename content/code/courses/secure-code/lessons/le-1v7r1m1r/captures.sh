#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/upload.
# app.py and test_app.py are taken from the-uploads.md by lab/extract.py.
# Each fix is the change its section describes, applied by an exact string
# replacement, and `git diff` shows it. The witnesses are ordinary: a name
# with ../ in front, a text file named .pdf, a file that is too big, and a
# pickled cookie that holds nothing but the text size.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - In "traversal" the portal was started in the background by serve(),
#     as from a second terminal.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/upload
rm -rf "$D"

block setup
run /home/ana/sc 'mkdir upload'
run /home/ana/sc 'cd upload'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put the-uploads.md app.py $D/app.py
put the-uploads.md test_app.py $D/test_app.py

serve $D 'flask --app app run'
block traversal
run $D "printf '%%PDF-1.7\\n' > knee.pdf"
run $D "curl -s -F 'exam=@knee.pdf' http://127.0.0.1:5000/exams"
run $D "curl -s -F 'exam=@knee.pdf;filename=../escape.pdf' http://127.0.0.1:5000/exams"
run $D 'ls static static/uploads'
unserve

block red
run $D 'pytest -q --tb=no'
block commit
export GIT_AUTHOR_DATE='2026-11-15 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-15 09:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -q -m "Exam uploads and text-size preferences"'

fix() {  # fix 'old' 'new': one exact replacement in app.py, which must match once
  python3 - "$1" "$2" <<'PY'
import sys
p = '/home/ana/sc/upload/app.py'
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

block pickled
run $D 'pytest -q --tb=short -k pickled'

# JSON, validated.
fix 'import base64
import pickle
from pathlib import Path

from flask import Flask, jsonify, request, send_from_directory
' 'import base64
import binascii
import json
from pathlib import Path

from flask import Flask, abort, jsonify, request, send_from_directory
'
fix 'app.config["UPLOADS"] = Path("static/uploads")
' 'app.config["UPLOADS"] = Path("static/uploads")
TEXT_SIZES = {"normal", "large"}
'
fix '    prefs = {"text_size": request.form.get("text_size", "normal")}
    response = jsonify(prefs)
    response.set_cookie("prefs", base64.b64encode(pickle.dumps(prefs)).decode())
    return response' '    prefs = {"text_size": request.form.get("text_size", "normal")}
    if prefs["text_size"] not in TEXT_SIZES:
        abort(400)
    response = jsonify(prefs)
    response.set_cookie("prefs", base64.urlsafe_b64encode(json.dumps(prefs).encode()).decode())
    return response'
fix '    raw = request.cookies.get("prefs")
    prefs = pickle.loads(base64.b64decode(raw)) if raw else {"text_size": "normal"}
    return jsonify(prefs)' '    raw = request.cookies.get("prefs")
    if raw is None:
        return jsonify(text_size="normal")
    try:
        prefs = json.loads(base64.urlsafe_b64decode(raw))
    except (binascii.Error, ValueError):
        abort(400)
    if not isinstance(prefs, dict) or prefs.get("text_size") not in TEXT_SIZES:
        abort(400)
    return jsonify(text_size=prefs["text_size"])'
block diff-pickle
run $D 'git diff'
block green-pickle
run $D 'pytest -q --tb=no'
block commit-pickle
export GIT_AUTHOR_DATE='2026-11-15 09:20:00 -0300' GIT_COMMITTER_DATE='2026-11-15 09:20:00 -0300'
run $D 'git commit -qam "Keep preferences as validated JSON, not pickle"'

# Names the portal chooses.
fix 'import json
from pathlib import Path
' 'import json
import secrets
from pathlib import Path
'
fix 'app.config["UPLOADS"] = Path("static/uploads")
' 'app.config["UPLOADS"] = Path("uploads")
'
fix '    exam.save(folder / exam.filename)
    return jsonify(id=exam.filename), 201' '    exam_id = secrets.token_hex(8)
    exam.save(folder / f"{exam_id}.pdf")
    return jsonify(id=exam_id), 201'
fix '@app.get("/exams/<name>")
def download(name):
    return send_from_directory(app.config["UPLOADS"], name)' '@app.get("/exams/<exam_id>")
def download(exam_id):
    response = send_from_directory(
        app.config["UPLOADS"],
        f"{exam_id}.pdf",
        mimetype="application/pdf",
        as_attachment=True,
        download_name="exam.pdf",
    )
    response.headers["X-Content-Type-Options"] = "nosniff"
    return response'
block diff-names
run $D 'git diff'
block green-names
run $D 'pytest -q --tb=no'
block commit-names
export GIT_AUTHOR_DATE='2026-11-15 09:40:00 -0300' GIT_COMMITTER_DATE='2026-11-15 09:40:00 -0300'
run $D 'git commit -qam "Store uploads under ids, outside static, and serve them as downloads"'

# Contents and size.
fix 'TEXT_SIZES = {"normal", "large"}
' 'app.config["MAX_CONTENT_LENGTH"] = 5 * 1024 * 1024
TEXT_SIZES = {"normal", "large"}
'
fix '    exam = request.files["exam"]
    folder' '    exam = request.files["exam"]
    if exam.stream.read(5) != b"%PDF-":
        abort(400)
    exam.stream.seek(0)
    folder'
block diff-contents
run $D 'git diff'
block green-contents
run $D 'pytest -q'
block commit-fix
export GIT_AUTHOR_DATE='2026-11-15 10:00:00 -0300' GIT_COMMITTER_DATE='2026-11-15 10:00:00 -0300'
run $D 'git commit -qam "Accept only PDFs, up to 5 MB"'
run $D 'git log --oneline'
