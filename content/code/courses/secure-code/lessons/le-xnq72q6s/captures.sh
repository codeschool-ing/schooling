#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/secrets.
# Every file is taken from the lesson's own listings by lab/extract.py. The
# key sms_live_4f9a1c7e2b8d6a3f is invented for the lesson and opens nothing.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Before "install", detect-secrets is removed without printing anything,
#     so the install shown is a first install of it; the packages it shares
#     with earlier lessons stay, and pip says so.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

D=/home/ana/sc/secrets
rm -rf "$D"
( . /home/ana/sc/.venv/bin/activate && flock /var/tmp/secure-code-pip.lock pip uninstall -q -y detect-secrets ) >/dev/null 2>&1

block setup
run /home/ana/sc 'mkdir secrets'
run /home/ana/sc 'cd secrets'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put where-secrets-hide.md app.py $D/app.py
put from-the-environment.md test_app.py $D/test_app.py
block red
run $D 'pytest -q --tb=no'

block commit
export GIT_AUTHOR_DATE='2026-11-16 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-16 09:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -q -m "Send reminders by SMS"'

block install
run $D 'pip install --progress-bar off detect-secrets==1.5.0'

block scan
run $D 'detect-secrets-hook app.py'

put from-the-environment.md app.py $D/app.py
block green
run $D 'pytest -q'

block refuse
run $D "python3 -c 'import app'"

block env
run $D "printf 'PORTAL_SECRET_KEY=%s\\nSMS_API_KEY=%s\\n' \"\$(python3 -c 'import secrets; print(secrets.token_hex(32))')\" sms_test_0000 > .env"
run $D "printf '.env\\n__pycache__/\\n' > .gitignore"
run $D 'git check-ignore -v .env'
run $D 'git status --short'

block load
run $D "set -a; . ./.env; set +a; python3 -c 'import app; print(app.SMS_API_KEY)'"

block history
export GIT_AUTHOR_DATE='2026-11-16 10:15:00 -0300' GIT_COMMITTER_DATE='2026-11-16 10:15:00 -0300'
run $D 'git add .gitignore app.py'
run $D 'git commit -q -m "Read secrets from the environment"'
run $D 'git log --oneline'
run $D "git log -p -S sms_live_ --format='%h %s' -- app.py | grep -E '^[0-9a-f]{7} |sms_live_'"
