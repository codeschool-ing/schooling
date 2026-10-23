#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/review.
# app.py and requirements.txt on main are taken from the lesson's listings
# by lab/extract.py; the change on the branch is the edit below, which is
# what the diff in the lesson shows, line for line.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Both commits carry fixed dates and authors, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/review
rm -rf "$D"; mkdir -p "$D"; git -C $D init -q -b main
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put reading-a-diff.md app.py $D/app.py
put reading-a-diff.md requirements.txt $D/requirements.txt
commit $D '2026-11-13 09:00' 'Show a patient their messages'
git -C $D switch -q -c messages

python3 - "$D" <<'PY'
import sys
d = sys.argv[1]
p = d + "/app.py"; s = open(p).read()
def sub(old, new):
    global s
    assert s.count(old) == 1, old
    s = s.replace(old, new)
sub("import secrets\n\nfrom flask import Flask, abort, render_template_string, session\n",
    "from flask import Flask, abort, redirect, render_template_string, request, session\n")
sub("app.secret_key = secrets.token_bytes(32)\n", 'app.secret_key = "vereda-dev"\n')
sub("{% for m in messages %}<p>{{ m.text }}</p>{% endfor %}",
    "{% for m in messages %}<p>{{ m.text|replace('\\n', '<br>')|safe }}</p>{% endfor %}")
s += '''

@app.post("/messages")
def send_message():
    message = dict(request.form)
    message["patient"] = message.get("patient", patient())
    MESSAGES[max(MESSAGES) + 1] = message
    return redirect("/messages")


@app.get("/messages/<int:number>")
def read_message(number):
    patient()
    return render_template_string(PAGE, messages=[MESSAGES[number]])
'''
open(p, "w").write(s)
r = d + "/requirements.txt"
req = open(r).read()
open(r, "w").write(req.replace("flask==3.1.3", "flask>=3.0"))
PY
commit $D '2026-11-13 11:30' 'Let patients send and read messages'

block diff
run $D 'git diff main messages'

