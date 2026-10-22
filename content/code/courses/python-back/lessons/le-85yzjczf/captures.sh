#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 7 left (`lab.sh reset
# 8`). Every file the lesson shows whole is taken from its section by `from`.
# Uvicorn runs in the background with --reload; a student runs it in a
# terminal of its own. The registrations start empty on every run, since they
# live in the server's memory until lesson 10.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 8
at '~/agenda-api'
from dependencies.md app/dependencies.py
from dependencies.md app/main.py
WAIT=5 serve api 'uv run uvicorn app.main:app --reload --port 8001'

block schema
run 'curl -s http://127.0.0.1:8001/openapi.json | head -c 300; echo'
run "curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; d = json.load(sys.stdin); [print(m.upper().ljust(5), p) for p, ops in d[\"paths\"].items() for m in ops]'"
run "curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; print(list(json.load(sys.stdin)[\"components\"][\"schemas\"]))'"
run "curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; print(json.dumps(json.load(sys.stdin)[\"components\"][\"schemas\"][\"RegistrationIn\"], indent=2))'"

block docs
run 'curl -s http://127.0.0.1:8001/docs | grep -oE "https://[^\"]+"'
run 'curl -s http://127.0.0.1:8001/redoc | grep -oE "https://[^\"]+"'

block describing
run "curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; op = json.load(sys.stdin)[\"paths\"][\"/events/{slug}/registrations\"][\"post\"]; print(op[\"tags\"], op[\"summary\"]); print(sorted(op[\"responses\"])); print(op[\"responses\"][\"409\"])'"
run "curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; op = json.load(sys.stdin)[\"paths\"][\"/events\"][\"get\"]; print(op[\"summary\"], \"|\", op[\"description\"]); [print(p[\"name\"], p[\"in\"], p[\"schema\"]) for p in op[\"parameters\"]]'"

block depends
run 'curl -s "http://127.0.0.1:8001/events?limit=1&offset=1" | python3 -m json.tool | grep slug'
run 'curl -s -w "\n%{http_code}\n" "http://127.0.0.1:8001/events?offset=-1"'
run 'curl -s -w "\n%{http_code}\n" http://127.0.0.1:8001/events/nope'
run 'curl -s -w "\n%{http_code}\n" http://127.0.0.1:8001/events/nope/registrations'

block yield
quiet 'wc -l < /tmp/api.log > /tmp/api.mark'
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Gil\", \"email\": \"gil@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/django-night/registrations'
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Gil\", \"email\": \"gil@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/django-night/registrations'
quiet 'sleep 1'
block yield-log
lab as 'tail -n +$(( $(cat /tmp/api.mark) + 1 )) /tmp/api.log'

block override
from overriding.md override.py
run 'uv add --dev httpx2'
run 'uv run python override.py'

stop api
quiet 'rm -f override.py'
lab save 8
