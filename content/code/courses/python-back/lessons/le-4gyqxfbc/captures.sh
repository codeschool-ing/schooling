#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 9 left (`lab.sh reset
# 10`). Every file the lesson shows whole is taken from its section by `from`.
# The edits a section describes in words are made here with sed or Python, to
# exactly the text the section prints: the URL in alembic.ini, the import in
# migrations/env.py, `venue` renamed to `place` in app/models.py and back, the
# two functions of the 0002 migration, `event["slug"]` to `event.slug` in
# app/forecast.py, and `.with_for_update()` taken out of app/main.py for one
# run and put back. agenda-api runs in the background, where a student runs it
# in a terminal of its own. Dates, process ids and Alembic's create dates are
# the ones of the run; how many registrations get through without the lock
# differs on every run and every round, which is why that run is three
# rounds.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 10
asroot 'systemctl enable --now postgresql'
at '~/agenda-api'

block engine
run 'uv add sqlalchemy psycopg alembic'
run 'createdb agenda_api'
from the-engine.md app/db.py
from the-engine.md hello_db.py
run 'uv run python hello_db.py'

block models
from mapped-classes.md app/models.py
from mapped-classes.md show_sql.py
run 'uv run python show_sql.py'

block alembic
run 'uv run alembic init migrations'
quiet 'sed -i "s|^sqlalchemy.url = .*|sqlalchemy.url = postgresql+psycopg:///agenda_api|" alembic.ini'
put /tmp/envpy.py <<'PY'
p = 'migrations/env.py'
s = open(p).read()
s = s.replace('target_metadata = None', 'from app.models import Base\n\ntarget_metadata = Base.metadata', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/envpy.py'
run 'grep -n "^sqlalchemy.url" alembic.ini'
run 'grep -n -A2 "import Base" migrations/env.py'
run 'uv run alembic revision --autogenerate --rev-id 0001 -m "events and registrations"'
run 'cat migrations/versions/0001_events_and_registrations.py'
run 'uv run alembic upgrade head'
run 'psql agenda_api -c "\d registrations"'
from alembic.md seed.py
run 'uv run python seed.py'
run 'uv run alembic current'

block rename
quiet 'sed -i "s/^    venue: Mapped/    place: Mapped/" app/models.py'
run 'grep -n "place" app/models.py'
run 'uv run alembic revision --autogenerate --rev-id 0002 -m "venue is now place"'
run "sed -n '/^def upgrade/,\$p' migrations/versions/0002_venue_is_now_place.py"
run 'uv run alembic upgrade head 2>&1 | tail -3'
put /tmp/rename.py <<'PY'
p = 'migrations/versions/0002_venue_is_now_place.py'
s = open(p).read()
head = s[:s.index('def upgrade')]
s = head + '''def upgrade() -> None:
    op.alter_column("events", "venue", new_column_name="place")


def downgrade() -> None:
    op.alter_column("events", "place", new_column_name="venue")
'''
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/rename.py'
run "sed -n '/^def upgrade/,\$p' migrations/versions/0002_venue_is_now_place.py"
run 'uv run alembic upgrade head'
run 'psql agenda_api -c "select slug, place from events"'
run 'uv run alembic history'
run 'uv run alembic downgrade -1'
run 'rm migrations/versions/0002_venue_is_now_place.py'
quiet 'sed -i "s/^    place: Mapped/    venue: Mapped/" app/models.py'
run 'uv run alembic check'

block queries
from querying.md queries.py
from querying.md nplus1.py
run 'uv run python queries.py'
run 'uv run python nplus1.py'

block api
from a-session-per-request.md app/db.py
from a-session-per-request.md app/schemas.py
from a-session-per-request.md app/dependencies.py
from a-session-per-request.md app/main.py
quiet "sed -i 's/event\[\"slug\"\]/event.slug/' app/forecast.py"
run 'grep -n "event.slug" app/forecast.py'
run 'rm app/store.py seed.py'
WAIT=7 serve api 'uv run uvicorn app.main:app --port 8001 --workers 4'
showlog api 'uv run uvicorn app.main:app --port 8001 --workers 4'
run 'curl -s http://127.0.0.1:8001/events/django-night; echo'
run 'curl -s "http://127.0.0.1:8001/events?venue=Public%20Library,%20lab%202"; echo'
run 'curl -s http://127.0.0.1:8001/events/nope; echo'

block lock
run "curl -s -X POST http://127.0.0.1:8001/events/django-night/registrations -H 'Content-Type: application/json' -d '{\"name\": \"Bruno\", \"email\": \"bruno@example.org\"}'; echo"
run "curl -s -X POST http://127.0.0.1:8001/events/django-night/registrations -H 'Content-Type: application/json' -d '{\"name\": \"Bruno\", \"email\": \"bruno@example.org\"}'; echo"
from one-lock-for-every-worker.md crowd.py
run 'uv run python crowd.py http://127.0.0.1:8001/events/async-workshop/registrations'
run 'psql agenda_api -c "select e.slug, count(r.id) from events e left join registrations r on r.event_id = e.id group by e.slug order by e.slug"'

block nolock
stop api
quiet 'sed -i "s/\.with_for_update()//" app/main.py'
run 'grep -n "Event.slug == slug" app/main.py'
run "psql agenda_api -c \"delete from registrations where email like 'p%@example.org'\""
WAIT=7 serve api 'uv run uvicorn app.main:app --port 8001 --workers 4'
run "for round in 1 2 3; do uv run python crowd.py http://127.0.0.1:8001/events/async-workshop/registrations; psql agenda_api -qc \"delete from registrations where email like 'p%@example.org'\"; done"
stop api

block relock
from a-session-per-request.md app/main.py
run 'grep -n "Event.slug == slug" app/main.py'
WAIT=7 serve api 'uv run uvicorn app.main:app --port 8001 --workers 4'
run 'uv run python crowd.py http://127.0.0.1:8001/events/async-workshop/registrations'
run 'curl -s http://127.0.0.1:8001/events/async-workshop; echo'
stop api

lab save 10
