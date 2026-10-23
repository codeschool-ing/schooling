#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 1 left (`lab.sh reset
# 2`). Every file the lesson shows whole is taken from its section by `from`.
# The three edits to config/settings.py that section `settings` shows as an
# excerpt (TIME_ZONE, "events" in INSTALLED_APPS, and TimingMiddleware at the
# top of MIDDLEWARE) are made with sed here, where a student makes them in an
# editor. The development server runs in the background and is restarted by
# this script wherever the lesson changes a file it does not reload by
# itself; a student's runserver reloads on save. The DEBUG=False run is a
# copy of settings.py with the one line changed, which the section says.
# Timings in Server-Timing differ on every run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 2

block project
run 'mkdir agenda && cd agenda && uv init --bare && uv add django'
at '~/agenda'
run 'uv run django-admin startproject config .'
run 'uv run python manage.py migrate'
run 'ls'
WAIT=4 serve django 'uv run python manage.py runserver'
run 'curl -s http://127.0.0.1:8000/ | grep -o "<title>.*</title>"'
run 'uv run python manage.py help | sed -n "/\[django\]/,/^$/p" | head -12'
stop django

block settings
run "grep -nE '^(DEBUG|ALLOWED_HOSTS|ROOT_URLCONF|WSGI_APPLICATION|LANGUAGE_CODE|TIME_ZONE|USE_TZ|STATIC_URL) ' config/settings.py"
quiet "sed -i \"s/^TIME_ZONE = 'UTC'/TIME_ZONE = 'America\\/Sao_Paulo'/\" config/settings.py"
run 'uv run python manage.py diffsettings | grep -E "^(TIME_ZONE|DEBUG|ROOT_URLCONF)"'
quiet "sed 's/^DEBUG = True/DEBUG = False/' config/settings.py > config/settings_nodebug.py"
run 'uv run python manage.py runserver --settings config.settings_nodebug'
quiet 'rm config/settings_nodebug.py'

block apps
run 'uv run python manage.py startapp events'
run 'find events -type f | sort'
from apps.md events/data.py
quiet "sed -i \"s/^    'django.contrib.staticfiles',/    'django.contrib.staticfiles',\\n    'events',/\" config/settings.py"
run "sed -n '/^INSTALLED_APPS/,/^]/p' config/settings.py"
run 'uv run python manage.py check'

block urls-views
from urls.md config/urls.py
from urls.md events/urls.py
from views.md events/views.py
WAIT=4 serve django 'uv run python manage.py runserver'
run 'curl -s http://127.0.0.1:8000/events/; echo'
run 'curl -s "http://127.0.0.1:8000/events/?venue=Public%20Library,%20lab%202"; echo'
run 'curl -si http://127.0.0.1:8000/events/django-night/; echo'
run 'curl -si http://127.0.0.1:8000/events/django-night | head -4'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/no-such-event/'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/a%20space/'
run 'curl -si -X OPTIONS http://127.0.0.1:8000/events/django-night/ | grep -iE "^(HTTP|allow)"'
run 'uv run python manage.py shell -c "from django.urls import reverse; print(reverse(\"events:detail\", args=[\"testing-dojo\"]))"'
run 'uv run python manage.py shell -c "from django.urls import resolve; m = resolve(\"/events/testing-dojo/\"); print(m.view_name, m.func.__name__, m.kwargs)"'

block middleware
stop django
from request-cycle.md events/middleware.py
quiet "sed -i \"s/^MIDDLEWARE = \\[/MIDDLEWARE = [\\n    'events.middleware.TimingMiddleware',/\" config/settings.py"
run "sed -n '/^MIDDLEWARE/,/^]/p' config/settings.py"
WAIT=4 serve django 'uv run python manage.py runserver'
run 'curl -si http://127.0.0.1:8000/events/django-night/ | grep -iE "^(HTTP|server-timing|x-frame)"'
run 'curl -si http://127.0.0.1:8000/events/nope/ | grep -iE "^(HTTP|server-timing)"'
run 'curl -si -X POST http://127.0.0.1:8000/events/django-night/ | grep -iE "^(HTTP|server-timing)"'

block cbv
from class-based-views.md events/views.py
from class-based-views.md events/urls.py
quiet 'sleep 3'
run 'curl -s http://127.0.0.1:8000/events/async-workshop/; echo'
run 'curl -si -X OPTIONS http://127.0.0.1:8000/events/async-workshop/ | grep -iE "^(HTTP|allow)"'

block log
stop django
lab as 'cat /tmp/django.log'
lab save 2
