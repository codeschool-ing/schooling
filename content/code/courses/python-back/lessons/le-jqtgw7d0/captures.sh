#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 13 left (`lab.sh reset
# 14`). Every file the lesson shows whole is taken from its section by `from`.
# The edits a section describes in words are made here with sed or Python, to
# exactly the text the section prints: the pytest tables added to each
# pyproject.toml, the count added to the event list's template and the query
# that pays for it in events/views.py, and the guard taken out of agenda-api's
# update_event for one run and put back. Timings are the ones of the run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 14
asroot 'systemctl enable --now postgresql'
at '~/agenda'

block pytest
run 'rm events/tests.py'
run 'uv add --dev pytest pytest-django'
quiet "printf '\n[tool.pytest.ini_options]\nDJANGO_SETTINGS_MODULE = \"config.settings\"\n' >> pyproject.toml"
run "sed -n '/^\[tool.pytest/,\$p' pyproject.toml"
from pytest-django.md tests/conftest.py
from pytest-django.md tests/test_services.py
run 'uv run pytest tests/test_services.py -v'

block pages
from the-test-client.md tests/test_pages.py
run 'uv run pytest tests/test_pages.py -v'
quiet "sed -i 's/ at {{ event.venue }}\$/ at {{ event.venue }}, {{ event.registrations.count }} registered/' events/templates/events/event_list.html"
run "grep -n 'registered' events/templates/events/event_list.html"
run 'uv run pytest tests/test_pages.py -q --tb=line'
put /tmp/annotate.py <<'PY'
p = 'events/views.py'
s = open(p).read()
s = s.replace('from django.shortcuts import', 'from django.db.models import Count\nfrom django.shortcuts import', 1)
s = s.replace('    events = Event.objects.filter(title__icontains=q)\n',
              '    events = Event.objects.filter(title__icontains=q).annotate(taken=Count("registrations"))\n', 1)
open(p, 'w').write(s)
p = 'events/templates/events/event_list.html'
s = open(p).read()
s = s.replace('{{ event.registrations.count }} registered', '{{ event.taken }} registered', 1)
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/annotate.py'
run "grep -n 'Count\|annotate' events/views.py"
run "grep -n 'registered' events/templates/events/event_list.html"
run 'uv run pytest tests/test_pages.py -q'

block api
from the-api-client.md tests/test_api.py
run 'uv run pytest tests/test_api.py -v'

block tasks
from testing-tasks.md tests/test_tasks.py
run 'uv run pytest tests/test_tasks.py -v'
run 'uv run pytest'

block fastapi
at '~/agenda-api'
run 'createdb agenda_api_test'
run 'uv add --dev pytest'
quiet "printf '\n[tool.pytest.ini_options]\npythonpath = [\".\"]\n' >> pyproject.toml"
run "sed -n '/^\[tool.pytest/,\$p' pyproject.toml"
from fastapi-testclient.md tests/conftest.py
from fastapi-testclient.md tests/test_api.py
run 'uv run pytest -v'
run 'psql agenda_api_test -c "\dt"'

block forgotten
quiet "sed -i 's/def update_event(changes: EventPatch, event: EditableEvent, session: SessionDep):/def update_event(changes: EventPatch, event: EventDep, session: SessionDep):/' app/main.py"
run "grep -n 'def update_event' app/main.py"
run 'uv run pytest -q --tb=line'
quiet "sed -i 's/def update_event(changes: EventPatch, event: EventDep, session: SessionDep):/def update_event(changes: EventPatch, event: EditableEvent, session: SessionDep):/' app/main.py"
run "grep -n 'def update_event' app/main.py"
run 'uv run pytest -q'

lab save 14
