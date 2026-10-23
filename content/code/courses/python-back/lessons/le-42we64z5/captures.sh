#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 3 left (`lab.sh reset
# 4`), which already has PostgreSQL 16 installed from Ubuntu's archive by the
# apt line section `installing-postgresql` shows; that section's transcript
# starts after it, and `systemctl enable --now postgresql` here does what apt
# does on a machine of your own. Every file the lesson shows whole is taken
# from its section by `from`. Three edits are made with sed or Python here,
# where a student makes them in an editor, and each section shows them as an
# excerpt: DATABASES in config/settings.py, the `description` field added to
# Event, and select_for_update in events/services.py. The failures in
# `when-postgresql-fails` are produced in the order a student meets them,
# before the setup is complete; the stopped server is stopped with systemctl
# and started again. Query plans, costs and timings may differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 4
asroot 'systemctl enable --now postgresql'
at '~/agenda'

block installed
run 'psql --version'
run 'pg_lsclusters'

block fail-chain
put /tmp/dbsettings.py <<'PY'
import re
p = 'config/settings.py'
s = open(p).read()
new = """DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'agenda',
    }
}
"""
s = re.sub(r'DATABASES = \{.*?\n\}\n', new, s, flags=re.S)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/dbsettings.py'
run "sed -n '/^DATABASES/,/^}/p' config/settings.py"
run 'uv run python manage.py migrate 2>&1 | tail -1'
run 'uv add psycopg'
run 'uv run python manage.py migrate 2>&1 | tail -1'
run 'sudo -u postgres createuser --superuser $USER'
run 'uv run python manage.py migrate 2>&1 | tail -1'
run 'createdb agenda'
run 'uv run python manage.py migrate | tail -3'
run 'rm db.sqlite3'

block psql
run 'psql agenda -c "\dt"'

block fail-stopped
run 'sudo systemctl stop postgresql'
run 'uv run python manage.py showmigrations events 2>&1 | tail -1'
run 'sudo systemctl start postgresql && pg_lsclusters'

block models
from models.md events/models.py
run 'uv run python manage.py makemigrations events'
run 'uv run python manage.py sqlmigrate events 0001'
run 'uv run python manage.py migrate events'
from models.md seed.py seed.py
run 'uv run python manage.py shell < seed.py'
run 'psql agenda -c "SELECT id, slug, starts_at, capacity FROM events_event"'
run 'psql agenda -c "SHOW timezone"'

block migrations
run 'uv run python manage.py showmigrations events'
quiet "sed -i 's/^    capacity = models.PositiveIntegerField()$/    capacity = models.PositiveIntegerField()\n    description = models.TextField(blank=True)/' events/models.py"
run "grep -n -A1 'capacity = ' events/models.py"
run 'uv run python manage.py makemigrations events'
run 'cat events/migrations/0002_event_description.py'
run 'uv run python manage.py sqlmigrate events 0002'
run 'uv run python manage.py migrate events'
run 'uv run python manage.py makemigrations --check --dry-run'

block querysets
from querysets.md queries.py queries.py
run 'uv run python manage.py shell < queries.py'

block sql
from the-sql.md sql.py sql.py
run 'uv run python manage.py shell < sql.py'

block constraint
run 'uv run python manage.py shell -c "from events.models import Event, Registration; e = Event.objects.get(slug=\"django-night\"); Registration.objects.create(event=e, name=\"Bruno\", email=\"bruno@example.org\"); Registration.objects.create(event=e, name=\"Bruno again\", email=\"bruno@example.org\")" 2>&1 | tail -2'
run 'psql agenda -c "\d events_registration" | tail -8'

block crowd-nolock
from constraints-and-transactions.md events/services.py
from constraints-and-transactions.md events/views.py
from constraints-and-transactions.md crowd.py crowd.py
run 'rm events/data.py'
quiet "sed -i 's/Event.objects.select_for_update().get/Event.objects.get/' events/services.py"
run 'uv run python manage.py shell < crowd.py'

block crowd-lock
quiet 'uv run python manage.py shell -c "from events.models import Registration; Registration.objects.filter(event__slug=\"async-workshop\").delete()"'
from constraints-and-transactions.md events/services.py
run "grep -n 'select_for_update' events/services.py"
run 'uv run python manage.py shell < crowd.py'

block site
WAIT=4 serve django 'uv run python manage.py runserver'
run 'curl -s http://127.0.0.1:8000/events/django-night/ | grep seats'
run 'curl -s -c cookies.txt -o /dev/null http://127.0.0.1:8000/events/django-night/; TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -s -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Bruno&email=bruno@example.org" http://127.0.0.1:8000/events/django-night/ | grep errorlist'
run 'curl -s http://127.0.0.1:8000/events/async-workshop/ | grep seats'
run 'curl -s http://127.0.0.1:8000/events/nope/ -o /dev/null -w "%{http_code}\n"'
stop django
quiet 'rm -f cookies.txt'

block relations
quiet 'uv run python manage.py shell -c "from events.models import Event, Registration; e = Event.objects.get(slug=\"testing-dojo\"); [Registration.objects.create(event=e, name=n, email=n.lower() + \"@example.org\") for n in (\"Carla\", \"Davi\")]"'
from relations.md nplus1.py nplus1.py
run 'uv run python manage.py shell < nplus1.py'
run 'uv run python manage.py shell -c "from events.models import Event; e = Event.objects.get(slug=\"testing-dojo\"); print(e.registrations.all()); print(e.registrations.first().event.venue)"'

quiet 'rm -f queries.py sql.py crowd.py nplus1.py'
lab save 4
