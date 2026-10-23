#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 12 left (`lab.sh reset
# 13`), which already has Redis installed from Ubuntu's archive by the apt line
# section `installing-redis` shows; `systemctl enable --now redis-server` here
# does what apt does on a machine of your own. Every file the lesson shows
# whole is taken from its section by `from`. The edits a section describes in
# words are made here with Python, to exactly the text the section prints:
# MAILERS and the Celery settings in config/settings.py, the mail call added to
# and later removed from events/api.py, the field added to Registration,
# `robust=True` in events/services.py, and the three changes to agenda-api's
# app/main.py. The mail server, the Django development server, the Celery
# worker, beat and agenda-api run in the background, each where a student runs
# it in a terminal of its own; what such a terminal printed is quoted from the
# line a mark was taken at, so a section shows what appeared while it ran;
# where that is a long traceback, the section quotes its first or last lines
# and says which. The pauses for the retries and for beat's sweep are sleeps
# here. Task ids, process ids, dates and times are the ones of the run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

mark() { quiet "wc -l < /tmp/$1.log > /tmp/$1.mark"; }
since() { lab as "tail -n +\$(( \$(cat /tmp/$1.mark) + 1 )) /tmp/$1.log"; }
first() { since "$1" | head -n "$2"; }
last() { since "$1" | tail -n "$2"; }
REG=http://127.0.0.1:8000/api/events/testing-dojo/registrations/
post() { printf "curl -s $REG -H 'Content-Type: application/json' -d '{\"name\": \"%s\", \"email\": \"%s@example.org\"}'" "$1" "$(echo "$1" | tr A-Z a-z)"; }

lab reset 13
asroot 'systemctl enable --now postgresql'
at '~/agenda'

block smtp
run 'uv add --dev aiosmtpd'
WAIT=4 serve smtp 'uv run python -m aiosmtpd -n -l 127.0.0.1:1025'
put /tmp/mailers.py <<'PY'
import re
p = 'config/settings.py'
s = open(p).read()
new = """MAILERS = {
    'default': {
        'BACKEND': 'django.core.mail.backends.smtp.EmailBackend',
        'OPTIONS': {'host': '127.0.0.1', 'port': 1025},
    },
}
DEFAULT_FROM_EMAIL = 'agenda <agenda@example.org>'
"""
s = re.sub(r"MAILERS = \{.*?\n\}\n", new, s, count=1, flags=re.S)
open(p, 'w').write(s)
p = 'events/api.py'
s = open(p).read()
s = s.replace('from .models import Event\n', 'from . import mail\nfrom .models import Event\n', 1)
s = s.replace('''        return Response({"detail": str(refusal)}, status=status.HTTP_409_CONFLICT)
    return Response(''', '''        return Response({"detail": str(refusal)}, status=status.HTTP_409_CONFLICT)
    mail.confirmation(registration)
    return Response(''', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/mailers.py'
from out-of-the-request.md events/mail.py
run "sed -n '/^MAILERS/,/^DEFAULT_FROM_EMAIL/p' config/settings.py"
run "grep -n 'mail' events/api.py"
WAIT=4 serve django 'uv run python manage.py runserver'
mark smtp
run "$(post Fabio); echo"
quiet 'sleep 1'

block smtp-log
since smtp

block smtp-down
stop smtp
run "$(post Gil) -o /dev/null -w '%{http_code}\n'"
run "psql agenda -c \"select name, email, created_at from events_registration where name = 'Gil'\""
run "$(post Gil); echo"

block redis
asroot 'systemctl enable --now redis-server'
run 'redis-server --version'
run 'systemctl is-active redis-server'
run 'redis-cli ping'
run 'uv add "celery[redis]"'

block celery
put /tmp/celery.py <<'PY'
p = 'config/settings.py'
s = open(p).read()
s += '\nCELERY_BROKER_URL = "redis://127.0.0.1:6379/0"\n'
open(p, 'w').write(s)
p = 'events/api.py'
s = open(p).read()
s = s.replace('from . import mail\n', '', 1)
s = s.replace('    mail.confirmation(registration)\n', '', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/celery.py'
from a-celery-app.md config/celery.py
from a-celery-app.md config/__init__.py
from a-celery-app.md events/tasks.py
from a-celery-app.md events/services.py
run 'tail -1 config/settings.py'
run "grep -c 'mail' events/api.py"
stop django
WAIT=4 serve smtp 'uv run python -m aiosmtpd -n -l 127.0.0.1:1025'
WAIT=8 serve worker 'uv run celery -A config worker -l info'
WAIT=4 serve django 'uv run python manage.py runserver'
showlog worker 'uv run celery -A config worker -l info'

block celery-register
mark worker
mark smtp
run "$(post Hana) -w ' %{http_code}\n'"
quiet 'sleep 2'

block celery-worker
since worker

block celery-smtp
since smtp

block lost
stop smtp
mark worker
run "$(post Ivo) -w ' %{http_code}\n'"
quiet 'sleep 2'

block lost-worker
first worker 2

block retries
put /tmp/field.py <<'PY'
p = 'events/models.py'
s = open(p).read()
s = s.replace('''    created_at = models.DateTimeField(auto_now_add=True)
''', '''    created_at = models.DateTimeField(auto_now_add=True)
    confirmation_sent_at = models.DateTimeField(null=True, blank=True)
''', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/field.py'
run "grep -n 'confirmation_sent_at' events/models.py"
run 'uv run python manage.py makemigrations events'
run 'uv run python manage.py migrate events'
from retries-and-idempotency.md events/tasks.py
stop worker
WAIT=8 serve worker 'uv run celery -A config worker -l info'
mark worker
run "$(post Joana) -w ' %{http_code}\n'"
quiet 'sleep 6'
WAIT=4 serve smtp 'uv run python -m aiosmtpd -n -l 127.0.0.1:1025'
quiet 'sleep 40'

block retries-worker
since worker

block idempotent
run "uv run python manage.py shell -v 0 -c \"from events.models import Registration; from events.tasks import send_confirmation; joana = Registration.objects.get(name='Joana'); print(joana.confirmation_sent_at); print(send_confirmation(joana.pk))\""

block redis-down
mark worker
run 'sudo systemctl stop redis-server'
quiet 'sleep 5'

block redis-down-worker
last worker 5

block redis-down-register
run "$(post Kai) -o /dev/null -w '%{http_code}\n'"
run "psql agenda -c \"select name, confirmation_sent_at from events_registration where name = 'Kai'\""
quiet "sed -i 's/transaction.on_commit(lambda: send_confirmation.delay(registration.pk))/transaction.on_commit(lambda: send_confirmation.delay(registration.pk), robust=True)/' events/services.py"
run "grep -n 'on_commit' events/services.py"
quiet 'sleep 3'
mark django
run "$(post Lia) -w ' %{http_code}\n'"

block redis-down-django
first django 1

block redis-back
mark worker
run 'sudo systemctl start redis-server'
quiet 'sleep 6'
since worker

block beat
put /tmp/beat.py <<'PY'
p = 'config/settings.py'
s = open(p).read()
s += '''
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    "resend-unconfirmed": {
        "task": "events.tasks.resend_unconfirmed",
        "schedule": crontab(minute="*"),
    },
}
'''
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/beat.py'
from periodic-tasks.md events/tasks.py
run "sed -n '/^from celery.schedules/,\$p' config/settings.py"
stop worker
WAIT=8 serve worker 'uv run celery -A config worker -l info'
mark worker
WAIT=4 serve beat 'uv run celery -A config beat -l info'
quiet 'sleep 210'
showlog beat 'uv run celery -A config beat -l info'

block beat-worker
since worker

block beat-rows
run "psql agenda -c \"select name, created_at, confirmation_sent_at from events_registration where created_at > now() - interval '1 hour' order by id\""
stop beat
stop worker
stop django

block fastapi
at '~/agenda-api'
from fastapi-background.md app/mail.py
put /tmp/bg.py <<'PY'
p = 'app/main.py'
s = open(p).read()
s = s.replace('from fastapi import FastAPI, HTTPException, status\n', 'from fastapi import BackgroundTasks, FastAPI, HTTPException, status\n', 1)
s = s.replace('from .auth import router as auth_router\n', 'from . import mail\nfrom .auth import router as auth_router\n', 1)
s = s.replace('def register(slug: str, registration: RegistrationIn, session: SessionDep):',
              'def register(slug: str, registration: RegistrationIn, session: SessionDep, background: BackgroundTasks):', 1)
s = s.replace('''        raise HTTPException(status.HTTP_409_CONFLICT, "This address is already registered.")
    return row
''', '''        raise HTTPException(status.HTTP_409_CONFLICT, "This address is already registered.")
    background.add_task(mail.confirmation, row.name, row.email, event.title)
    return row
''', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/bg.py'
run "grep -n 'BackgroundTasks\|background\|import mail' app/main.py"
WAIT=5 serve api 'uv run uvicorn app.main:app --port 8001'
mark smtp
run "curl -s http://127.0.0.1:8001/events/testing-dojo/registrations -H 'Content-Type: application/json' -d '{\"name\": \"Maria\", \"email\": \"maria@example.org\"}' -w ' %{http_code}\n'"
quiet 'sleep 1'

block fastapi-smtp
since smtp

block fastapi-down
stop smtp
mark api
run "curl -s http://127.0.0.1:8001/events/testing-dojo/registrations -H 'Content-Type: application/json' -d '{\"name\": \"Nuno\", \"email\": \"nuno@example.org\"}' -w ' %{http_code}\n'"
quiet 'sleep 1'

block fastapi-down-log
first api 3
last api 1
stop api

lab save 13
