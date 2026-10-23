#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds (~/sc and its .venv) and starts from
# no ~/sc/signup. test_app.py and both versions of app.py are taken from the
# lesson's own listings by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The commits carry fixed dates, so their hashes repeat.
#   - Each server was started in the background by serve() and the requests
#     come from the same machine, as from a second terminal.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/signup
rm -rf "$D"
BAD="curl -s -w '\n%{http_code}\n' -d 'name=&email=lucia&birth=2031-01-01' http://127.0.0.1:5000/signup"

block setup
run /home/ana/sc 'mkdir signup'
run /home/ana/sc 'cd signup'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put any-client.md app.py $D/app.py
serve $D 'flask --app app run'
block curl
run $D "$BAD"
unserve

put the-test.md test_app.py $D/test_app.py
block red
run $D 'pytest --tb=line'

block commit
export GIT_AUTHOR_DATE='2026-11-03 14:00:00 -0300' GIT_COMMITTER_DATE='2026-11-03 14:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -m "Sign up from the form"'

put one-source.md app.py $D/app.py
block green
run $D 'pytest'

block commit-fix
export GIT_AUTHOR_DATE='2026-11-03 15:10:00 -0300' GIT_COMMITTER_DATE='2026-11-03 15:10:00 -0300'
run $D 'git commit -am "Check every field on the server, and draw the form from the same rules"'
unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE

serve $D 'flask --app app run'
block form
run $D "curl -s -w '\\n' http://127.0.0.1:5000/signup"
block refused
run $D "$BAD"
unserve
