#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 4 left (`lab.sh reset
# 5`), with w3m already installed by the apt line section `a-superuser` shows.
# Every file the lesson shows whole is taken from its section by `from`. The
# admin is a site for a browser; this lesson reads its pages as text with
# w3m, through the `page` script the lesson shows, so that every screen is a
# capture. The read-only change in `what-it-is-not` is shown as an excerpt
# and made here with Python. The development server runs in the background.
# The passwords are this course's and protect nothing.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 5
asroot 'systemctl enable --now postgresql'
at '~/agenda'
from a-superuser.md '~/.local/bin/page' /home/ana/.local/bin/page
quiet 'chmod +x ~/.local/bin/page'
WAIT=4 serve django 'uv run python manage.py runserver'

block superuser
run "DJANGO_SUPERUSER_PASSWORD='x9-river-lantern-42' uv run python manage.py createsuperuser --noinput --username ana --email ana@example.org"
run 'curl -si http://127.0.0.1:8000/admin/ | grep -E "^(HTTP|Location)"'
run 'curl -s -c ~/admin-cookies.txt -o /dev/null http://127.0.0.1:8000/admin/login/'
run 'TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -si -b ~/admin-cookies.txt -c ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&username=ana&password=x9-river-lantern-42&next=/admin/" http://127.0.0.1:8000/admin/login/ | grep -E "^(HTTP|Location)"'
run 'page /admin/ | sed -n "/^Site administration/,/^Recent actions/p"'

block register
from registering.md events/admin.py
quiet 'sleep 3'
run 'page /admin/ | sed -n "/^Site administration/,/^Recent actions/p"'
run 'page /admin/events/event/ | sed -n "/^Select event to change/,/^[0-9]* events/p"'

block list
from list-pages.md events/admin.py
quiet 'sleep 3'
run 'page /admin/events/event/ | sed -n "/^Select event to change/,/^[0-9]* events/p"'
run 'page "/admin/events/event/?q=dojo" | sed -n "/^Select event to change/,/^[0-9]* event/p"'

block inline
run 'page /admin/events/event/3/change/ | sed -n "/^Change event/,/^\[Save\]/p"'

block action
run 'TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -s -b ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&action=registrations_csv&_selected_action=1&_selected_action=3" http://127.0.0.1:8000/admin/events/event/'

block bypass
run 'psql agenda -c "SELECT count(*) FROM events_registration WHERE event_id = 2"'
run 'TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -si -b ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&event=2&name=Elisa&email=elisa@example.org" http://127.0.0.1:8000/admin/events/registration/add/ | grep -E "^(HTTP|Location)"'
run 'psql agenda -c "SELECT count(*) FROM events_registration WHERE event_id = 2"'
run 'uv run python manage.py shell -c "from django.contrib.admin.models import LogEntry; [print(e.action_time.date(), e.user, e) for e in LogEntry.objects.all()]"'

block readonly
put /tmp/readonly.py <<'PY'
p = 'events/admin.py'
s = open(p).read()
s = s.replace('''    readonly_fields = ["created_at"]
    extra = 0
''', '''    readonly_fields = ["created_at"]
    extra = 0

    def has_add_permission(self, request, obj=None):
        return False
''')
s = s.replace('''    search_fields = ["name", "email"]
''', '''    search_fields = ["name", "email"]

    def has_add_permission(self, request):
        return False
''')
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/readonly.py'
run "grep -n -B1 -A1 'has_add_permission' events/admin.py"
quiet 'sleep 3'
run 'curl -s -b ~/admin-cookies.txt -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/events/registration/add/'
run 'uv run python manage.py shell -c "from events.models import Registration; Registration.objects.filter(email=\"elisa@example.org\").delete()"'

block staff
from staff-and-groups.md organisers.py
run 'uv run python manage.py shell -c "from django.contrib.auth.models import Permission; print(list(Permission.objects.filter(content_type__app_label=\"events\").values_list(\"codename\", flat=True)))"'
run 'uv run python manage.py shell < organisers.py'
quiet 'rm -f ~/admin-cookies.txt'
run 'curl -s -c ~/admin-cookies.txt -o /dev/null http://127.0.0.1:8000/admin/login/; TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -si -b ~/admin-cookies.txt -c ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&username=bruno&password=m4-orchard-copper-17&next=/admin/" http://127.0.0.1:8000/admin/login/ | grep -E "^(HTTP|Location)"'
run 'page /admin/ | sed -n "/^Site administration/,/^Recent actions/p"'
run 'curl -s -b ~/admin-cookies.txt -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/events/event/3/delete/'
run 'curl -s -b ~/admin-cookies.txt -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/auth/user/'

block log
stop django
quiet 'rm -f ~/admin-cookies.txt organisers.py'
lab save 5
