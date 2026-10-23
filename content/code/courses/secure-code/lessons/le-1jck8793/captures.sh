#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds, with pip-audit installed as lesson
# 17 does, and starts from no ~/sc/checks. Every file is taken from the
# lesson's own listings by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Before "install", bandit and the two packages it brings that nothing
#     earlier installed (PyYAML, stevedore) are removed without printing
#     anything, so the install shown is a first install.
#   - bandit prints the time it started, and pytest and pip-audit depend on
#     the day: those lines are what they printed on the day of the recording.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/checks
rm -rf "$D"
( . /home/ana/sc/.venv/bin/activate && flock /var/tmp/secure-code-pip.lock pip uninstall -q -y bandit stevedore pyyaml ) >/dev/null 2>&1

block setup
run /home/ana/sc 'mkdir checks'
run /home/ana/sc 'cd checks'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

block install
run $D 'pip install --progress-bar off bandit==1.9.4'

put bandit.md app.py $D/app.py
put bandit.md test_app.py $D/test_app.py
block bandit
run $D 'bandit -q app.py'

block noise
run $D "bandit -q -r . -f custom --msg-template '{relpath}:{line}: {test_id} {msg}'"

put one-command.md check.sh $D/check.sh
printf 'flask==3.1.3\n' > $D/requirements.txt
block hook
run $D "printf 'flask==3.1.3\\n' > requirements.txt"
run $D "printf '#!/bin/sh\\nexec sh ./check.sh\\n' > .git/hooks/pre-commit"
run $D 'chmod +x .git/hooks/pre-commit'

block refused
export GIT_AUTHOR_DATE='2026-11-14 10:00:00 -0300' GIT_COMMITTER_DATE='2026-11-14 10:00:00 -0300'
run $D 'git add .'
run $D 'git commit -m "Reset codes and receipt ids"'

put one-command.md app.py $D/app.py
block accepted
export GIT_AUTHOR_DATE='2026-11-14 10:40:00 -0300' GIT_COMMITTER_DATE='2026-11-14 10:40:00 -0300'
run $D 'git add app.py'
run $D 'git commit -m "Reset codes and receipt ids, from secrets and without the debugger"'
