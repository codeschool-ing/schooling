#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 5 left (`lab.sh reset
# 6`). Every file the lesson shows whole is taken from its section by `from`.
# The two edits to config/settings.py that section `why-a-framework` shows as
# excerpts ("rest_framework" in INSTALLED_APPS, and the REST_FRAMEWORK
# dictionary) are made with sed and cat here, where a student makes them in an
# editor. The development server runs in the background. The password is the
# superuser's from lesson 5 and protects nothing.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 6
asroot 'systemctl enable --now postgresql'
at '~/agenda'

block install
run 'uv add djangorestframework'
quiet "sed -i \"s/^    'events',/    'rest_framework',\\n    'events',/\" config/settings.py"
put /tmp/rest.txt <<'PY'

REST_FRAMEWORK = {
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticatedOrReadOnly",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 2,
}
PY
quiet 'cat /tmp/rest.txt >> config/settings.py'
run "sed -n '/^INSTALLED_APPS/,/^]/p' config/settings.py"
run "sed -n '/^REST_FRAMEWORK/,/^}/p' config/settings.py"

block serializers
from serializers.md events/serializers.py
run 'uv run python manage.py shell -c "from events.serializers import EventSerializer; from events.models import Event; print(EventSerializer(Event.objects.get(slug=\"testing-dojo\")).data)"'
run 'uv run python manage.py shell -c "from events.serializers import EventSerializer; s = EventSerializer(data={\"slug\": \"bad slug\", \"title\": \"\", \"capacity\": -1}); print(s.is_valid()); print(s.errors)"'

block views
from api-views.md events/api.py
from api-views.md events/api_urls.py
from api-views.md config/urls.py
WAIT=4 serve django 'uv run python manage.py runserver'
run 'curl -s http://127.0.0.1:8000/api/ | python3 -m json.tool'
run 'curl -s http://127.0.0.1:8000/api/events/ | python3 -m json.tool'
run 'curl -s "http://127.0.0.1:8000/api/events/?page=2" | python3 -m json.tool'
run 'curl -s "http://127.0.0.1:8000/api/events/?venue=Public%20Library,%20lab%202" | python3 -m json.tool | head -4'
run 'curl -s http://127.0.0.1:8000/api/events/django-night/ | python3 -m json.tool'
run 'curl -si -H "Accept: text/html" http://127.0.0.1:8000/api/events/django-night/ | grep -E "^(HTTP|Content-Type)"'

block writes
run 'curl -si -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": 45}" http://127.0.0.1:8000/api/events/django-night/ | sed -n "1p;\$p"; echo'
run 'curl -s -u ana:x9-river-lantern-42 -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": 45}" http://127.0.0.1:8000/api/events/django-night/ | python3 -m json.tool'
run 'curl -s -u ana:x9-river-lantern-42 -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": 1}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/'
run 'curl -s -u ana:x9-river-lantern-42 -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": \"forty\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/'
run 'curl -s -u ana:x9-river-lantern-42 -X POST -H "Content-Type: application/json" -d "{\"slug\": \"pycon-watch\", \"title\": \"PyCon talks, watched together\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"Public Library, lab 2\", \"capacity\": 15}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/'
run 'curl -s -u ana:x9-river-lantern-42 -X DELETE -w "%{http_code}\n" http://127.0.0.1:8000/api/events/pycon-watch/'

block register
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/'
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/'
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\", \"email\": \"not-an-address\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/'
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\", \"email\": \"fabio@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/async-workshop/registrations/'
run 'curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\"" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/'
run 'curl -s -X GET -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/'

block log
stop django
lab save 6
