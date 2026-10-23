#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 8 left (`lab.sh reset
# 9`). Every file the lesson shows whole is taken from its section by `from`;
# the two lines `async-in-fastapi` adds to app/main.py are added here with
# Python. The partner service, agenda-api and, in `async-django`, agenda under
# Uvicorn each run in the background, where a student runs each in a terminal
# of its own. Every time printed here is a measurement of that run, on a
# machine with 4 processors, and differs on every run and every machine; the
# lesson reads the proportions, not the decimals.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 9
asroot 'systemctl enable --now postgresql'
at '~/agenda-api'
from waiting.md slow.py
from waiting.md three.py
from the-event-loop.md loop.py
from async-in-fastapi.md app/forecast.py
from async-in-fastapi.md load.py
put /tmp/include.py <<'PY'
p = 'app/main.py'
s = open(p).read()
s = s.replace('from .dependencies import EventDep', 'from .dependencies import EventDep', 1)
s = s.replace('from .schemas import', 'from .forecast import router as forecast_router\nfrom .schemas import', 1)
s = s.replace('    description="Community events with a limited number of seats.",\n)\n',
              '    description="Community events with a limited number of seats.",\n)\napp.include_router(forecast_router)\n', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/include.py'
WAIT=4 serve slow 'uv run uvicorn slow:app --port 8002'

block waiting
run 'curl -s -w "  %{time_total} s\n" http://127.0.0.1:8002/forecast/community-centre'
run 'uv run python three.py'

block loop
run 'uv run python loop.py'

block fastapi
run "grep -n 'forecast' app/main.py"
WAIT=5 serve api 'uv run uvicorn app.main:app --port 8001'
run 'curl -s http://127.0.0.1:8001/forecast/async/django-night; echo'
run 'uv run python load.py http://127.0.0.1:8001/forecast/async/django-night 20'
run 'uv run python load.py http://127.0.0.1:8001/forecast/sync/django-night 20'
run 'uv run python load.py http://127.0.0.1:8001/forecast/async/django-night 100'
run 'uv run python load.py http://127.0.0.1:8001/forecast/sync/django-night 100'

block blocking
run 'uv run python load.py http://127.0.0.1:8001/forecast/blocking/django-night 1'
run 'uv run python load.py http://127.0.0.1:8001/forecast/blocking/django-night 10'
run 'uv run python load.py http://127.0.0.1:8001/forecast/async/django-night 10'

block busy
run 'curl -s http://127.0.0.1:8001/forecast/busy/async; echo'
run 'uv run python load.py http://127.0.0.1:8001/forecast/busy/async 4'
run 'uv run python load.py http://127.0.0.1:8001/forecast/busy/sync 4'
stop api

block django
at '~/agenda'
run 'uv add httpx2 uvicorn'
from async-django.md events/forecast.py
from async-django.md events/urls.py
from async-django.md orm_async.py
run 'uv run python manage.py shell < orm_async.py'
WAIT=5 serve asgi 'uv run uvicorn config.asgi:application --port 8000'
run 'curl -s http://127.0.0.1:8000/events/testing-dojo/forecast/; echo'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/nope/forecast/'
at '~/agenda-api'
run 'uv run python load.py http://127.0.0.1:8000/events/testing-dojo/forecast/ 20'
stop asgi
stop slow
at '~/agenda'
quiet 'rm -f orm_async.py'
at '~/agenda-api'
quiet 'rm -f three.py loop.py'
lab save 9
