#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds (~/sc and its .venv) and starts from
# no ~/sc/profile. Every file is taken from the lesson's own listings by
# lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The commits carry fixed dates, so their hashes repeat.
#   - Each server was started in the background by serve() and the requests
#     come from the same machine, as from a second terminal.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/profile
rm -rf "$D"; mkdir -p "$D"; git -C $D init -q -b main
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put four-places.md contexts.py $D/contexts.py
block contexts
run $D 'python3 contexts.py'

put the-profile.md profiles.py $D/profiles.py
put the-profile.md app.py $D/app.py
put the-profile.md test_app.py $D/test_app.py
serve $D 'flask --app app run'
block curl-before
run $D 'curl -s http://127.0.0.1:5000/patients/lucia'
unserve

block red
run $D 'pytest -q --tb=no'

block commit
export GIT_AUTHOR_DATE='2026-11-04 09:30:00 -0300' GIT_COMMITTER_DATE='2026-11-04 09:30:00 -0300'
run $D 'git add contexts.py profiles.py app.py test_app.py'
run $D 'git commit -m "Show the patient profile"'

put the-fix.md app.py $D/app.py
block green
run $D 'pytest -q'

block commit-fix
export GIT_AUTHOR_DATE='2026-11-04 10:40:00 -0300' GIT_COMMITTER_DATE='2026-11-04 10:40:00 -0300'
run $D 'git commit -am "Render the profile with an autoescaping template, tojson and url_for"'
unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE

serve $D 'flask --app app run'
block curl-after
run $D 'curl -s http://127.0.0.1:5000/patients/lucia'
unserve
