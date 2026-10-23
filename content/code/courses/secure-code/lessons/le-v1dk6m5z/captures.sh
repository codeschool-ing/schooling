#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds (~/sc and its .venv) and starts from
# no ~/sc/deps. Both versions of requirements.txt are taken from the lesson's
# own listings by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Before "install", every package lesson 1 did not install is removed
#     from the environment without printing anything, so the install shown is
#     a first install, as it is for a student.
#   - pip-audit asks PyPI's vulnerability data, which changes as advisories
#     are published: the rows below are what it answered on the day of the
#     recording. The commit carries a fixed date, so its hash repeats.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/deps
rm -rf "$D" /home/ana/wheels

BASE='blinker click flask iniconfig itsdangerous jinja2 markupsafe packaging pip pluggy pygments pytest werkzeug'
extra=$(. /home/ana/sc/.venv/bin/activate && pip freeze --all | cut -d= -f1 | tr 'A-Z_' 'a-z-' | grep -vxF -f <(tr ' ' '\n' <<<"$BASE"))
[ -n "$extra" ] && ( . /home/ana/sc/.venv/bin/activate && flock /var/tmp/secure-code-pip.lock pip uninstall -q -y $extra ) >/dev/null 2>&1

block setup
run /home/ana/sc 'mkdir deps'
run /home/ana/sc 'cd deps'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

block show
run $D 'pip show flask'

block install
run $D 'pip install --progress-bar off pip-audit==2.10.1'

put pip-audit.md requirements.txt $D/requirements.txt
export GIT_AUTHOR_DATE='2026-11-12 10:00:00 -0300' GIT_COMMITTER_DATE='2026-11-12 10:00:00 -0300'
( cd $D && git add requirements.txt && git commit -q -m "Pin the portal's dependencies" )
unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE

block red
run $D 'pip-audit -r requirements.txt'

put pip-audit.md requirements.txt 2 $D/requirements.txt
block diff
run $D 'git diff'

block green
run $D 'pip-audit -r requirements.txt'

block hash
run $D 'pip download --no-deps --progress-bar off -d ~/wheels jinja2==3.1.6'
run $D 'pip hash ~/wheels/jinja2-3.1.6-py3-none-any.whl'
