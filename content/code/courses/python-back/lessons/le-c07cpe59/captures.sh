#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 10 left (`lab.sh reset
# 11`). Every file the lesson shows whole is taken from its section by `from`.
# The edits a section describes in words are made here with Python, to exactly
# the text the section prints: `rest_framework.authtoken` and the
# REST_FRAMEWORK block in config/settings.py, the User class at the end of
# app/models.py, the four lines app/main.py gains, and the version of
# `authenticate` without the decoy, for one run.
# The password create_user.py asks for is typed into a terminal that `script`
# provides, after a pause, so that getpass has turned the echo off as it does
# for a person; the carriage returns of that terminal are removed. The Django
# development server and agenda-api run in the background, where a student runs
# each in a terminal of its own. Tokens, session keys, hashes, salts and times
# are the ones of the run and differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 11
asroot 'systemctl enable --now postgresql'

block passwords
at '~/agenda'
from passwords.md passwords.py
run 'uv run python manage.py shell -v 0 < passwords.py'

block sessions
WAIT=4 serve django 'uv run python manage.py runserver'
run 'curl -s -c jar.txt http://127.0.0.1:8000/admin/login/ -o /dev/null -w "%{http_code}\n"'
run "grep -vE '^(# |\$)' jar.txt | cut -f1,6"
run 'curl -s -b jar.txt -c jar.txt http://127.0.0.1:8000/admin/login/ -d "csrfmiddlewaretoken=$(grep csrftoken jar.txt | cut -f7)" -d username=bruno -d password=m4-orchard-copper-17 -d next=/admin/ -o /dev/null -w "%{http_code} %{redirect_url}\n"'
run "grep -vE '^(# |\$)' jar.txt | cut -f1,6"
run 'psql agenda -c "select session_key, expire_date from django_session order by expire_date"'
run "curl -s -b jar.txt -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{\"capacity\": 22}'; echo"
run "curl -s -b jar.txt -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -H \"X-CSRFToken: \$(grep csrftoken jar.txt | cut -f7)\" -d '{\"capacity\": 22}'; echo"
run 'cp jar.txt before-logout.txt'
run 'curl -s -b jar.txt -c jar.txt -X POST http://127.0.0.1:8000/admin/logout/ -H "X-CSRFToken: $(grep csrftoken jar.txt | cut -f7)" -o /dev/null -w "%{http_code}\n"'
run "curl -s -b before-logout.txt -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -H \"X-CSRFToken: \$(grep csrftoken before-logout.txt | cut -f7)\" -d '{\"capacity\": 24}'; echo"
stop django

block drf
put /tmp/drf.py <<'PY'
p = 'config/settings.py'
s = open(p).read()
s = s.replace("    'rest_framework',\n", "    'rest_framework',\n    'rest_framework.authtoken',\n", 1)
s = s.replace('REST_FRAMEWORK = {\n', '''REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.TokenAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ],
''', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/drf.py'
from drf-tokens.md events/api_urls.py
run "grep -n 'rest_framework' config/settings.py"
run "sed -n '/^REST_FRAMEWORK/,/^}/p' config/settings.py"
run 'uv run python manage.py migrate'
WAIT=4 serve django 'uv run python manage.py runserver'
run "curl -si -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{\"capacity\": 24}' | grep -iE '^(HTTP|www-authenticate)|detail'"
run "curl -s -u bruno:m4-orchard-copper-17 -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{\"capacity\": 24}'; echo"
run 'curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17; echo'
run 'curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17; echo'
run "curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17 | python3 -c \"import json, sys; print(json.load(sys.stdin)['token'])\" > drf-token.txt"
run "curl -s -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H \"Authorization: Token \$(cat drf-token.txt)\" -H 'Content-Type: application/json' -d '{\"capacity\": 24}'; echo"
run 'psql agenda -c "select key, user_id, created from authtoken_token"'
run 'uv run python manage.py drf_create_token -r bruno'
run "curl -s -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H \"Authorization: Token \$(cat drf-token.txt)\" -H 'Content-Type: application/json' -d '{\"capacity\": 24}'; echo"
stop django

block fastapi
at '~/agenda-api'
run 'uv add pyjwt "pwdlib[argon2]" python-multipart'
put /tmp/user.py <<'PY'
p = 'app/models.py'
s = open(p).read()
s += '''

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(150), unique=True)
    password_hash: Mapped[str] = mapped_column(String(255))
'''
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/user.py'
run 'uv run alembic revision --autogenerate --rev-id 0002 -m "users" 2>&1 | grep -E "Detected added|Generating"'
run 'uv run alembic upgrade head 2>&1 | tail -1'
from jwt-in-fastapi.md app/security.py
from jwt-in-fastapi.md create_user.py
shown 'uv run python create_user.py ana' '(sleep 4; printf "%s\n" x9-river-lantern-42) | script -qec "uv run python create_user.py ana" /dev/null | tr -d "\r"'
run 'psql agenda_api -c "select username, password_hash from users"'
from jwt-in-fastapi.md app/auth.py
put /tmp/mainedit.py <<'PY'
p = 'app/main.py'
s = open(p).read()
s = s.replace('from .db import SessionDep\n', 'from .auth import router as auth_router\nfrom .db import SessionDep\n', 1)
s = s.replace('from .schemas import EventIn', 'from .security import CurrentUser\nfrom .schemas import EventIn', 1)
s = s.replace('app.include_router(forecast_router)\n', 'app.include_router(forecast_router)\napp.include_router(auth_router)\n', 1)
s = s.replace('def create_event(event: EventIn, session: SessionDep):', 'def create_event(event: EventIn, session: SessionDep, user: CurrentUser):', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/mainedit.py'
run "grep -n 'auth_router\|CurrentUser' app/main.py"
WAIT=5 serve api 'uv run uvicorn app.main:app --port 8001'

block jwt
run "curl -si http://127.0.0.1:8001/events -H 'Content-Type: application/json' -d '{\"slug\": \"auth-clinic\", \"title\": \"Auth clinic\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"Community Centre, room 3\", \"capacity\": 15}' | grep -iE '^(HTTP|www-authenticate)|detail'"
run 'curl -s http://127.0.0.1:8001/token -d username=ana -d password=x9-river-lantern-42; echo'
run "curl -s http://127.0.0.1:8001/token -d username=ana -d password=x9-river-lantern-42 | python3 -c \"import json, sys; print(json.load(sys.stdin)['access_token'])\" > token.txt"
run "tr '.' '\n' < token.txt"
run 'cut -d. -f1 token.txt | base64 -d; echo'
run 'cut -d. -f2 token.txt | base64 -d; echo'
run 'curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat token.txt)"; echo'
run "curl -s http://127.0.0.1:8001/events -H \"Authorization: Bearer \$(cat token.txt)\" -H 'Content-Type: application/json' -d '{\"slug\": \"auth-clinic\", \"title\": \"Auth clinic\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"Community Centre, room 3\", \"capacity\": 15}'; echo"

block bad
from what-a-jwt-is.md bad_tokens.py
run 'uv run python bad_tokens.py'
run "uv run python -c \"import jwt; print(jwt.decode(open('forged.txt').read(), options={'verify_signature': False}))\""
run 'curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat forged.txt)"; echo'
run 'curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat expired.txt)"; echo'
run 'curl -s http://127.0.0.1:8001/token -d username=ana -d password=wrong; echo'
run 'curl -s http://127.0.0.1:8001/token -d username=nobody -d password=wrong; echo'

block timing
run 'for who in ana nobody ana nobody; do curl -s -o /dev/null -w "$who %{http_code} %{time_total} s\n" http://127.0.0.1:8001/token -d username=$who -d password=wrong; done'
stop api
put /tmp/nodecoy.py <<'PY'
p = 'app/security.py'
s = open(p).read()
s = s.replace('''    stored = user.password_hash if user else DECOY
    if not passwords.verify(password, stored) or user is None:
        return None
''', '''    if user is None:
        return None
    if not passwords.verify(password, user.password_hash):
        return None
''', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/nodecoy.py'
WAIT=5 serve api 'uv run uvicorn app.main:app --port 8001'
run 'for who in ana nobody ana nobody; do curl -s -o /dev/null -w "$who %{http_code} %{time_total} s\n" http://127.0.0.1:8001/token -d username=$who -d password=wrong; done'
stop api
from jwt-in-fastapi.md app/security.py
quiet 'rm -f forged.txt expired.txt'

lab save 11
