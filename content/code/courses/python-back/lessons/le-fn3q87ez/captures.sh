#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 2 left (`lab.sh reset
# 3`). Every file the lesson shows whole is taken from its section by `from`.
# The one edit to config/settings.py that section `inheritance` shows as an
# excerpt (DIRS in TEMPLATES) is made with sed here, where a student makes it
# in an editor. The development server runs in the background; a student's
# runs in a terminal of its own. The registrations are kept in the server's
# memory until lesson 4, so they start empty on every run of this script.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 3
at '~/agenda'

from template-language.md events/data.py
from template-language.md events/templates/events/event_list.html
from inheritance.md templates/base.html
from inheritance.md templates/about.html
from inheritance.md config/urls.py
from forms-and-csrf.md events/forms.py
from forms-and-csrf.md events/views.py
from forms-and-csrf.md events/urls.py
from forms-and-csrf.md events/templates/events/event_detail.html
from static-files.md events/static/events/agenda.css
quiet "sed -i \"s/'DIRS': \\[\\],/'DIRS': [BASE_DIR \\/ 'templates'],/\" config/settings.py"

block settings
run "grep -n \"'DIRS'\" config/settings.py"
run 'find templates events/templates events/static -type f | sort'
WAIT=4 serve django 'uv run python manage.py runserver'

block list
run 'curl -s http://127.0.0.1:8000/events/'
run 'curl -s http://127.0.0.1:8000/about/ | grep -E "<title>|<h1>"'

block escaping
run 'curl -s "http://127.0.0.1:8000/events/?q=<b>dojo</b>" | grep Results'
run 'curl -s "http://127.0.0.1:8000/events/?q=dojo" | grep -A4 "<ul>"'

block form
run 'curl -s http://127.0.0.1:8000/events/async-workshop/ | sed -n "/<main>/,/<\/main>/p"'
run 'curl -s -o /dev/null -w "%{http_code}\n" -d "name=Bruno&email=bruno@example.org" http://127.0.0.1:8000/events/async-workshop/'
run 'curl -s -c cookies.txt -o /dev/null http://127.0.0.1:8000/events/async-workshop/ && grep -o "csrftoken.*" cookies.txt | cut -c1-24'
run 'TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -si -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Bruno&email=bruno@example.org" http://127.0.0.1:8000/events/async-workshop/ | grep -E "^(HTTP|Location)"'
run 'curl -s http://127.0.0.1:8000/events/async-workshop/ | grep seats'
run 'TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -s -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Carla&email=carla.example.org" http://127.0.0.1:8000/events/async-workshop/ | grep -B1 -A1 errorlist'

block full
run 'TOKEN=$(grep csrftoken cookies.txt | cut -f7); for i in $(seq 2 12); do curl -s -o /dev/null -w "%{http_code} " -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Person $i&email=p$i@example.org" http://127.0.0.1:8000/events/async-workshop/; done; echo'
run 'curl -s http://127.0.0.1:8000/events/async-workshop/ | grep seats'
run 'TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -s -w "%{http_code}\n" -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Davi&email=davi@example.org" http://127.0.0.1:8000/events/async-workshop/ | grep -E "errorlist|^[0-9]{3}$"'

block static
run 'curl -sI http://127.0.0.1:8000/static/events/agenda.css | grep -E "^(HTTP|Content-Type|Content-Length)"'
run 'curl -s http://127.0.0.1:8000/events/ | grep stylesheet'

block failures
run 'uv run python manage.py shell -c "from django.template.loader import render_to_string; render_to_string(\"events/event_lsit.html\")" 2>&1 | tail -1'
run 'uv run python manage.py shell -c "from django.template import Template, Context; print(repr(Template(\"[{{ event.titel }}]\").render(Context({\"event\": {\"title\": \"Django Night\"}}))))"'
run 'uv run python manage.py shell -c "from django.template import Template; Template(\"{% for e in events %}{{ e }}\")" 2>&1 | tail -1'
run 'uv run python manage.py shell -c "from django.template import Template; Template(\"{{ event.starts_at|dat }}\")" 2>&1 | tail -1'

block log
stop django
lab as 'grep -E "\"(GET|POST)" /tmp/django.log | head -8; grep -c "\"POST" /tmp/django.log; grep -i forbidden /tmp/django.log'
quiet 'rm -f cookies.txt'
lab save 3
