#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 11 left (`lab.sh reset
# 12`). Every file the lesson shows whole is taken from its section by `from`.
# The edits a section describes in words are made here with Python, to exactly
# the text the section prints: EventPatch in app/schemas.py, and in
# app/main.py the imports, the admin on create_event and the PATCH route. The
# passwords create_user.py asks for are typed into a terminal that `script`
# provides, after a pause, as lesson 11's captures do. The Django development
# server and agenda-api run in the background, where a student runs each in a
# terminal of its own.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 12
asroot 'systemctl enable --now postgresql'

block hole
at '~/agenda'
run "uv run python manage.py shell -v 0 -c \"from django.contrib.auth.models import User; User.objects.create_user('carla', 'carla@example.org', 'k7-meadow-harbour-23')\""
from 401-and-403.md doors.py
WAIT=4 serve django 'uv run python manage.py runserver'
run 'uv run python doors.py'
run "curl -si -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{}' | grep -iE '^(HTTP|www-authenticate)|detail'"

block owners
from owners.md events/models.py
run 'uv run python manage.py makemigrations events'
run 'uv run python manage.py migrate events'
from owners.md owners.py
run 'uv run python manage.py shell -v 0 < owners.py'

block drf
from drf-permissions.md events/permissions.py
from drf-permissions.md events/api.py
quiet 'sleep 3'
run 'uv run python doors.py'
run "curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17 | python3 -c \"import json, sys; print(json.load(sys.stdin)['token'])\" > drf-token.txt"
run "curl -s -X PATCH http://127.0.0.1:8000/api/events/async-workshop/ -H \"Authorization: Token \$(cat drf-token.txt)\" -H 'Content-Type: application/json' -d '{\"capacity\": 30}'; echo"
run "curl -s -X POST http://127.0.0.1:8000/api/events/ -H \"Authorization: Token \$(cat drf-token.txt)\" -H 'Content-Type: application/json' -d '{}'; echo"
stop django

block fastapi
at '~/agenda-api'
from fastapi-guards.md app/models.py
run 'uv run alembic revision --autogenerate --rev-id 0003 -m "organisers and admins" 2>&1 | grep -E "Detected|Generating"'
run "sed -n '/^def upgrade/,\$p' migrations/versions/0003_organisers_and_admins.py"
run 'uv run alembic upgrade head 2>&1 | tail -1'
shown 'uv run python create_user.py bruno' '(sleep 4; printf "%s\n" m4-orchard-copper-17) | script -qec "uv run python create_user.py bruno" /dev/null | tr -d "\r"'
shown 'uv run python create_user.py carla' '(sleep 4; printf "%s\n" k7-meadow-harbour-23) | script -qec "uv run python create_user.py carla" /dev/null | tr -d "\r"'
run "psql agenda_api -c \"update users set is_admin = true where username = 'ana'\""
run "psql agenda_api -c \"update events set organiser_id = (select id from users where username = 'bruno') where slug in ('django-night', 'testing-dojo')\""
run "psql agenda_api -c \"update events set organiser_id = (select id from users where username = 'ana') where slug in ('async-workshop', 'auth-clinic')\""
run 'psql agenda_api -c "select e.slug, u.username as organiser from events e left join users u on u.id = e.organiser_id order by e.starts_at"'
from fastapi-guards.md app/guards.py
put /tmp/guards.py <<'PY'
p = 'app/schemas.py'
s = open(p).read()
s = s.replace('''class RegistrationIn(BaseModel):''', '''class EventPatch(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    capacity: int | None = Field(default=None, ge=1, le=1000)
    description: str | None = None


class RegistrationIn(BaseModel):''', 1)
open(p, 'w').write(s)
p = 'app/main.py'
s = open(p).read()
s = s.replace('from .forecast import router as forecast_router\n', 'from .forecast import router as forecast_router\nfrom .guards import AdminUser, EditableEvent\n', 1)
s = s.replace('from .security import CurrentUser\n', '', 1)
s = s.replace('from .schemas import EventIn, EventOut,', 'from .schemas import EventIn, EventOut, EventPatch,', 1)
s = s.replace('def create_event(event: EventIn, session: SessionDep, user: CurrentUser):\n    row = Event(**event.model_dump())',
              'def create_event(event: EventIn, session: SessionDep, user: AdminUser):\n    row = Event(**event.model_dump(), organiser_id=user.id)', 1)
route = '''@app.patch("/events/{slug}", response_model=EventOut, tags=["events"])
def update_event(changes: EventPatch, event: EditableEvent, session: SessionDep):
    for field, value in changes.model_dump(exclude_unset=True).items():
        setattr(event, field, value)
    session.commit()
    return event


'''
s = s.replace('@app.post(\n    "/events/{slug}/registrations"', route + '@app.post(\n    "/events/{slug}/registrations"', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/guards.py'
run "grep -n 'guards\|AdminUser\|organiser_id=\|EditableEvent' app/main.py"
from fastapi-guards.md doors.py
WAIT=5 serve api 'uv run uvicorn app.main:app --port 8001'
run 'uv run python doors.py'
run "curl -s http://127.0.0.1:8001/token -d username=bruno -d password=m4-orchard-copper-17 | python3 -c \"import json, sys; print(json.load(sys.stdin)['access_token'])\" > token.txt"
run "curl -s -X PATCH http://127.0.0.1:8001/events/async-workshop -H \"Authorization: Bearer \$(cat token.txt)\" -H 'Content-Type: application/json' -d '{\"capacity\": 30}'; echo"
run "curl -s -X PATCH http://127.0.0.1:8001/events/testing-dojo -H \"Authorization: Bearer \$(cat token.txt)\" -H 'Content-Type: application/json' -d '{\"capacity\": 30}'; echo"
stop api

lab save 12
