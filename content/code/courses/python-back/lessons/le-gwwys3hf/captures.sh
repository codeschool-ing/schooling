#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine lesson 15 left (`lab.sh reset
# 16`), which already has nginx installed from Ubuntu's archive by the apt line
# section `installing-nginx` shows; `systemctl enable --now nginx` here does
# what apt does on a machine of your own. Every file the lesson shows whole is
# taken from its section by `from`; the four systemd units and the nginx site,
# which a student writes with sudo and an editor, are written to /tmp first and
# installed with `install` as root. The settings a section adds to the end of
# config/settings.py are added with Python, to exactly the text it prints, and
# one line of the nginx site is taken out and put back for the failure it
# causes. Gunicorn and Uvicorn run in the background until the services take
# over. The recording machine has no IPv6, so the `listen [::]:80` line of
# nginx's default site is removed before it starts; a virtual machine of your
# own needs no such change. Process ids, dates and the certificate's dates are
# the ones of the run.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 16
asroot 'systemctl enable --now postgresql redis-server'
at '~/agenda'

block gunicorn
run 'uv add gunicorn'
WAIT=5 serve gunicorn 'uv run --env-file .env gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000'
showlog gunicorn 'uv run --env-file .env gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000'
run 'ps -o pid,ppid,cmd --forest -C gunicorn | cut -c1-90'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/'
mark() { quiet "wc -l < /tmp/$1.log > /tmp/$1.mark"; }
since() { lab as "tail -n +\$(( \$(cat /tmp/$1.mark) + 1 )) /tmp/$1.log"; }
mark gunicorn
run 'kill -9 $(pgrep -n gunicorn)'
quiet 'sleep 2'

block gunicorn-respawn
since gunicorn
stop gunicorn

block uvicorn
at '~/agenda-api'
WAIT=6 serve uvicorn 'uv run uvicorn app.main:app --workers 2 --host 127.0.0.1 --port 8001'
showlog uvicorn 'uv run uvicorn app.main:app --workers 2 --host 127.0.0.1 --port 8001'
mark uvicorn
run "kill -9 \$(pgrep -f 'multiprocessing.spawn' | head -1)"
quiet 'sleep 3'

block uvicorn-respawn
since uvicorn
stop uvicorn

block static
at '~/agenda'
put /tmp/prod.py <<'PY'
p = 'config/settings.py'
s = open(p).read()
s += '''
STATIC_ROOT = os.environ.get("DJANGO_STATIC_ROOT", BASE_DIR / "staticfiles")

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = not DEBUG
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
SECURE_HSTS_SECONDS = int(os.environ.get("DJANGO_HSTS_SECONDS", "0"))
'''
open(p, 'w').write(s)
PY
quiet 'python3 /tmp/prod.py'
run "sed -n '/^STATIC_ROOT/,\$p' config/settings.py"
run 'sudo install -d -o ana -g ana /var/www/agenda/static'
run 'DJANGO_STATIC_ROOT=/var/www/agenda/static uv run --env-file .env python manage.py collectstatic --noinput'
run 'ls /var/www/agenda/static'

block envfile
run 'sudo install -d -m 755 /etc/agenda'
run "grep -v '^DJANGO_DEBUG=' .env | sudo install -m 600 /dev/stdin /etc/agenda/agenda.env"
run "printf 'DJANGO_ALLOWED_HOSTS=agenda.example.org\nDJANGO_STATIC_ROOT=/var/www/agenda/static\nDJANGO_HSTS_SECONDS=3600\n' | sudo tee -a /etc/agenda/agenda.env > /dev/null"
run 'sudo install -m 600 ../agenda-api/.env /etc/agenda/agenda-api.env'
run 'sudo ls -l /etc/agenda'
run 'sudo cut -d= -f1 /etc/agenda/agenda.env'
run 'cat /etc/agenda/agenda.env'

block units
for u in agenda agenda-worker agenda-beat agenda-api; do
  from systemd-units.md /etc/systemd/system/$u.service /tmp/$u.service
  asroot "install -m 644 /tmp/$u.service /etc/systemd/system/$u.service"
done
run 'sudo systemctl daemon-reload'
run 'sudo systemctl enable --now agenda agenda-worker agenda-beat agenda-api'
quiet 'sleep 6'
run 'systemctl is-active agenda agenda-worker agenda-beat agenda-api'
run 'systemctl status agenda --no-pager | head -12'
run 'journalctl -u agenda-api -n 6 --no-pager -o cat'

block checks
run 'systemctl is-active postgresql redis-server'
run 'uv run --env-file .env celery -A config inspect ping'
run 'curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -H "Host: agenda.example.org" http://127.0.0.1:8000/events/'
run 'curl -s -H "Host: api.agenda.example.org" http://127.0.0.1:8001/events/django-night; echo'

block nginx-install
asroot "sed -i '/listen \\[::\\]/d' /etc/nginx/sites-available/default && systemctl enable --now nginx"
run 'nginx -v'
run 'systemctl is-active nginx'
run 'curl -s http://127.0.0.1/ | grep -o "<title>.*</title>"'

block nginx-http
from nginx-in-front.md /etc/nginx/sites-available/agenda /tmp/agenda.nginx
asroot 'install -m 644 /tmp/agenda.nginx /etc/nginx/sites-available/agenda'
run 'sudo ln -s /etc/nginx/sites-available/agenda /etc/nginx/sites-enabled/agenda'
run 'sudo rm /etc/nginx/sites-enabled/default'
run 'sudo nginx -t'
run 'sudo systemctl reload nginx'
quiet 'sleep 1'
run 'curl -sI -H "Host: agenda.example.org" http://127.0.0.1/static/events/agenda.css | grep -iE "^(HTTP|server|content-type|content-length)"'
run 'curl -sI -H "Host: agenda.example.org" http://127.0.0.1/events/ | grep -iE "^(HTTP|location)"'
run 'curl -s -D - -o /dev/null -H "Host: api.agenda.example.org" http://127.0.0.1/events | grep -iE "^(HTTP|server|x-|referrer)"'

block https
run 'sudo install -d -m 755 /etc/ssl/agenda'
run 'sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 90 -subj "/CN=agenda.example.org" -addext "subjectAltName=DNS:agenda.example.org,DNS:api.agenda.example.org" -keyout /etc/ssl/agenda/agenda.key -out /etc/ssl/agenda/agenda.crt'
run 'openssl x509 -in /etc/ssl/agenda/agenda.crt -noout -subject -ext subjectAltName -enddate'
from https-behind-nginx.md /etc/nginx/sites-available/agenda /tmp/agenda.nginx
asroot 'install -m 644 /tmp/agenda.nginx /etc/nginx/sites-available/agenda'
run 'sudo nginx -t && sudo systemctl reload nginx'
quiet 'sleep 1'
run 'curl -sI http://127.0.0.1/events/ -H "Host: agenda.example.org" | grep -iE "^(HTTP|location)"'
run 'curl -s -o /dev/null -w "%{http_code}\n" --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/'
run 'curl -s -o /dev/null -w "%{http_code}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/'
run 'curl -sI --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/admin/login/ | grep -iE "^(HTTP|strict|set-cookie)" | cut -c1-90'
run 'sudo systemd-run --quiet --wait --pipe --uid=ana -p EnvironmentFile=/etc/agenda/agenda.env -p WorkingDirectory=/home/ana/agenda /home/ana/agenda/.venv/bin/python manage.py check --deploy'

block forwarded
quiet 'cd ~/agenda-api'
run 'curl -s -o /dev/null --interface 127.0.0.2 --cacert /etc/ssl/agenda/agenda.crt --resolve api.agenda.example.org:443:127.0.0.1 https://api.agenda.example.org/events/django-night'
run 'curl -s -o /dev/null --interface 127.0.0.2 -H "X-Forwarded-For: 203.0.113.9" --cacert /etc/ssl/agenda/agenda.crt --resolve api.agenda.example.org:443:127.0.0.1 https://api.agenda.example.org/events/django-night'
run 'journalctl -u agenda-api -n 2 --no-pager -o cat'
run 'sudo tail -2 /var/log/nginx/access.log | cut -c1-110'

block fails
run 'sudo systemctl stop agenda'
run 'curl -s -o /dev/null -w "%{http_code}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/'
run 'sudo tail -1 /var/log/nginx/error.log | cut -c1-160'
run 'sudo systemctl start agenda'
quiet "sudo sed -i 's|        proxy_pass http://127.0.0.1:8000;|        proxy_pass http://127.0.0.1:8000|' /etc/nginx/sites-available/agenda"
run 'sudo nginx -t'
quiet "sudo sed -i 's|        proxy_pass http://127.0.0.1:8000\$|        proxy_pass http://127.0.0.1:8000;|' /etc/nginx/sites-available/agenda"
quiet "sudo sed -i '0,/        proxy_set_header X-Forwarded-Proto \$scheme;/{//d}' /etc/nginx/sites-available/agenda"
quiet 'sudo nginx -t && sudo systemctl reload nginx'
quiet 'sleep 2'
run 'curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/'
from https-behind-nginx.md /etc/nginx/sites-available/agenda /tmp/agenda.nginx
asroot 'install -m 644 /tmp/agenda.nginx /etc/nginx/sites-available/agenda && systemctl reload nginx'
quiet 'sleep 1'
run 'curl -s -o /dev/null -w "%{http_code}\n" --cacert /etc/ssl/agenda/agenda.crt --resolve agenda.example.org:443:127.0.0.1 https://agenda.example.org/events/'

lab save 16
