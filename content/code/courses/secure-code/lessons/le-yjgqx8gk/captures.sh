#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/errors.
# Every file is taken from the lesson's own listings by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The server in "before" and "after" was started in the background by
#     serve(), with its output sent to server.log as the lesson's command
#     says; the requests come from the same machine.
#   - Each error reference is random, so it differs on every run; the
#     commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/errors
rm -rf "$D"

block setup
run /home/ana/sc 'mkdir errors'
run /home/ana/sc 'cd errors'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put error-pages.md app.py $D/app.py
put error-pages.md test_app.py $D/test_app.py

serve $D 'flask --app app run > server.log 2>&1'
block before
printf '(.venv) ana@vm:~/sc/errors$ flask --app app run > server.log 2>&1 &\n'
run $D 'curl -s http://127.0.0.1:5000/patients/marta/phone'
run $D "curl -s -d 'name=lucia&password=correct horse battery staple' http://127.0.0.1:5000/login"
run $D 'grep portal server.log'
unserve

block red
run $D 'pytest -q --tb=no'

block commit
export GIT_AUTHOR_DATE='2026-11-15 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-15 09:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -q -m "Show phones, and log sign-ins"'

put the-fix.md app.py $D/app.py
block green
run $D 'pytest -q'


rm -f $D/server.log
serve $D 'flask --app app run > server.log 2>&1'
block after
printf '(.venv) ana@vm:~/sc/errors$ flask --app app run > server.log 2>&1 &\n'
run $D 'curl -s http://127.0.0.1:5000/patients/marta/phone'
run $D "curl -s -d 'name=lucia&password=correct horse battery staple' http://127.0.0.1:5000/login"
run $D "grep -A 8 'portal' server.log"
unserve
