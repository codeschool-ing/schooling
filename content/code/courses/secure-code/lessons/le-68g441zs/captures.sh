#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It starts from no ~/sc at all, as a student does, and runs the steps of
# "Your lab, built once" and "The first flaw, found by a test" in order.
# app.py and test_app.py are taken from first-flaw.md by lab/extract.py, so
# the program the lesson prints is the program that ran.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `apt install` is not run: the machine had python3, python3-venv, git
#     and curl already, and the lesson says so.
#   - `flask --app app run` in the "serve" block was stopped by `timeout 3`
#     rather than by Ctrl+C, and its last lines are the ones it had written
#     by then. In "curl" the server was started in the background by serve()
#     and the request comes from the same machine, as from a second terminal.
#     Werkzeug colours its warning with terminal escape codes; they are
#     removed from the transcript, which is the text a terminal shows.
#   - The two commits carry a fixed date (GIT_AUTHOR_DATE and
#     GIT_COMMITTER_DATE), so their hashes are the same on every run.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

rm -rf /home/ana/sc /home/ana/.cache/pip
mkdir -p /home/ana

VENV=0
block versions
run /home/ana 'python3 --version'
run /home/ana 'git --version'

block venv
run /home/ana 'mkdir sc'
run /home/ana 'cd sc'
run /home/ana/sc 'python3 -m venv .venv'
run /home/ana/sc '. .venv/bin/activate'
VENV=1
run /home/ana/sc 'pip install --progress-bar off flask==3.1.3 pytest==9.1.1'

block pip-list
run /home/ana/sc 'pip list'

block repo
run /home/ana/sc 'mkdir cancel'
run /home/ana/sc 'cd cancel'
run /home/ana/sc/cancel 'git init -b main'
git -C /home/ana/sc/cancel config user.name ana
git -C /home/ana/sc/cancel config user.email ana@vereda.example
du -sh /home/ana/sc/.venv >&2

put first-flaw.md app.py /home/ana/sc/cancel/app.py
put first-flaw.md test_app.py /home/ana/sc/cancel/test_app.py

block red
run /home/ana/sc/cancel 'pytest'

block commit
export GIT_AUTHOR_DATE='2026-11-01 09:30:00 -0300' GIT_COMMITTER_DATE='2026-11-01 09:30:00 -0300'
run /home/ana/sc/cancel 'git add app.py test_app.py'
run /home/ana/sc/cancel 'git commit -m "Cancel a booking up to 24 hours before"'

# The fix, as the lesson describes it: one line of app.py changed by hand.
python3 - <<'PY'
p = '/home/ana/sc/cancel/app.py'
s = open(p).read()
old = '    if booking is None:\n'
assert s.count(old) == 1
open(p, 'w').write(s.replace(old, '    if booking is None or booking["patient"] != session["patient"]:\n'))
PY

block diff
run /home/ana/sc/cancel 'git diff'

block green
run /home/ana/sc/cancel 'pytest'

block commit-fix
export GIT_AUTHOR_DATE='2026-11-01 09:45:00 -0300' GIT_COMMITTER_DATE='2026-11-01 09:45:00 -0300'
run /home/ana/sc/cancel 'git commit -am "Refuse to cancel a booking that is not the patient'"'"'s"'
unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE

block serve
printf '(.venv) ana@vm:~/sc/cancel$ flask --app app run\n'
( cd /home/ana/sc/cancel && . /home/ana/sc/.venv/bin/activate && timeout 3 flask --app app run ) 2>&1 | sed 's/\x1b\[[0-9;]*m//g'

serve /home/ana/sc/cancel 'flask --app app run'
block curl
run /home/ana/sc/cancel 'curl -si -X POST http://127.0.0.1:5000/bookings/101/cancel'

block port-busy
printf '(.venv) ana@vm:~/sc/cancel$ flask --app app run\n'
( cd /home/ana/sc/cancel && . /home/ana/sc/.venv/bin/activate && timeout 3 flask --app app run ) 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
unserve

block wrong-folder
run /home/ana/sc 'flask --app app run'

block no-venv
run /home/ana/sc 'deactivate'
VENV=0
run /home/ana/sc "python3 -c 'import flask'"
