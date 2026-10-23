#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds (~/sc and its .venv) and starts from
# no ~/sc/booking. digits.py, test_app.py and both versions of app.py are
# taken from the lesson's own listings by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The commits carry fixed dates, so their hashes repeat.
#   - In "curl" the server was started in the background by serve() and the
#     request comes from the same machine, as from a second terminal.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/booking
rm -rf "$D"

block setup
run /home/ana/sc 'mkdir booking'
run /home/ana/sc 'cd booking'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put canonical-first.md digits.py $D/digits.py
block digits
run $D 'python3 digits.py'

put booking-form.md app.py $D/app.py
put booking-form.md test_app.py $D/test_app.py
block red
run $D 'pytest --tb=line'

block commit
export GIT_AUTHOR_DATE='2026-11-02 10:00:00 -0300' GIT_COMMITTER_DATE='2026-11-02 10:00:00 -0300'
run $D 'git add app.py test_app.py digits.py'
run $D 'git commit -m "Book a session from the form"'

put the-fix.md app.py $D/app.py
block green
run $D 'pytest'

block commit-fix
export GIT_AUTHOR_DATE='2026-11-02 11:20:00 -0300' GIT_COMMITTER_DATE='2026-11-02 11:20:00 -0300'
run $D 'git diff --stat'
run $D 'git commit -am "Validate bookings against allowlists, at one boundary"'
unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE

serve $D 'flask --app app run'
block curl
run $D "curl -s -X POST http://127.0.0.1:5000/bookings -H 'Content-Type: application/json' -d '{\"clinic\": \"moema\", \"date\": \"2026-11-31\", \"time\": \"09:00\", \"phone\": \"11987654321\"}'"
unserve
