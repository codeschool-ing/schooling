#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 6 left (`lab.sh reset
# 7`). Every file the lesson shows whole is taken from its section by `from`.
# Uvicorn runs in the background with --reload, where a student runs it in a
# terminal of its own; the script waits a few seconds after each file it
# writes so the reload has happened. Registrations are kept in the server's
# memory until lesson 10, so they start empty on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 7
at '~'

block project
run 'mkdir agenda-api && cd agenda-api && uv init --bare && uv add fastapi uvicorn "pydantic[email]"'
at '~/agenda-api'
run 'mkdir app && touch app/__init__.py'
from first-app.md app/store.py
from first-app.md app/main.py
run 'find . -path ./.venv -prune -o -type f -print | sort'
WAIT=5 serve api 'uv run uvicorn app.main:app --reload --port 8001'
run 'curl -s http://127.0.0.1:8001/events | python3 -m json.tool | head -12'
showlog api 'uv run uvicorn app.main:app --reload --port 8001'

block pydantic
from pydantic-models.md app/schemas.py
from pydantic-models.md validate.py
run 'uv run python validate.py'
run 'uv run python -c "from app.schemas import EventIn; EventIn(slug=\"x\", title=\"x\", starts_at=\"tomorrow\", venue=\"x\", capacity=\"fifteen\")" 2>&1 | tail -7'

block routes
from path-and-query.md app/main.py
quiet 'sleep 4'
run 'curl -s "http://127.0.0.1:8001/events?limit=1" | python3 -m json.tool'
run 'curl -s "http://127.0.0.1:8001/events?venue=Public%20Library,%20lab%202" | python3 -m json.tool | grep slug'
run 'curl -s -w "\n%{http_code}\n" "http://127.0.0.1:8001/events?limit=500"'
run 'curl -s -w "\n%{http_code}\n" "http://127.0.0.1:8001/events?limit=ten"'
run 'curl -s -w "\n%{http_code}\n" http://127.0.0.1:8001/events/no-such-event'

block register
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/testing-dojo/registrations'
run 'curl -s http://127.0.0.1:8001/events/testing-dojo/registrations | python3 -m json.tool'
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/testing-dojo/registrations'
run 'curl -s http://127.0.0.1:8001/events/testing-dojo | python3 -m json.tool | grep -E "capacity|taken"'

block errors
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"\", \"email\": \"not-an-address\"}" http://127.0.0.1:8001/events/testing-dojo/registrations | python3 -m json.tool'
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\"" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/testing-dojo/registrations'
run 'curl -s -H "Content-Type: application/json" -d "{\"slug\": \"Bad Slug\", \"title\": \"x\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"x\", \"capacity\": 0}" http://127.0.0.1:8001/events | python3 -m json.tool | grep -E "\"(type|msg)\""'
run 'curl -s -H "Content-Type: application/json" -d "{\"slug\": \"pycon-watch\", \"title\": \"PyCon talks, watched together\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"Public Library, lab 2\", \"capacity\": 15}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events'
run 'curl -s -H "Content-Type: application/json" -d "{\"slug\": \"pycon-watch\", \"title\": \"Again\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"x\", \"capacity\": 15}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events'
run 'curl -si -X DELETE http://127.0.0.1:8001/events/pycon-watch | grep -iE "^(HTTP|allow)"'

block log
stop api
quiet 'rm -f validate.py'
lab save 7
