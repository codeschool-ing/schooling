#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine from `lab.sh reset 1`, which
# is a fresh Ubuntu 24.04 with section `your-lab`'s apt line and uv already
# installed. The two programs are taken from section `same-endpoint-twice`
# by `from`, and so are the two bare applications of `wsgi-and-asgi`, so
# the file a student copies is the file that ran. Each server is
# started in the background and stopped by this script, where a student runs
# it in a terminal of its own and stops it with Ctrl-C. The failures in
# `when-setup-fails` are produced on purpose: a shell started without the
# PATH a terminal opened before `pipx ensurepath` still has, manage.py
# run by the system's Python, and a second server on a port already taken.
# Package versions are whatever PyPI served on the day, and uv prints them.
#
# Recorded on Ubuntu 24.04 under systemd-nspawn, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

lab reset 1

block tools
run 'python3 --version'
run 'uv --version'
run 'git --version'
run 'curl --version | head -1'

block django
run 'mkdir hello-django && cd hello-django && uv init --bare'
at '~/hello-django'
run 'uv add django'
run 'uv run django-admin startproject hello .'
run 'find . -path ./.venv -prune -o -type f -print | sort'
from same-endpoint-twice.md hello/urls.py
WAIT=4 serve django 'uv run python manage.py runserver 8000'
run 'curl -si http://127.0.0.1:8000/hello/ana; echo'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/goodbye/ana'

block fastapi
at '~'
run 'mkdir hello-fastapi && cd hello-fastapi && uv init --bare'
at '~/hello-fastapi'
run 'uv add fastapi uvicorn'
from same-endpoint-twice.md main.py
WAIT=4 serve fastapi 'uv run uvicorn main:app --port 8001'
run 'curl -si http://127.0.0.1:8001/hello/ana; echo'
run 'curl -s http://127.0.0.1:8001/openapi.json | head -c 160; echo'

block raw
from wsgi-and-asgi.md wsgi_app.py
from wsgi-and-asgi.md asgi_app.py
WAIT=2 serve wsgi 'uv run python wsgi_app.py'
WAIT=3 serve asgi 'uv run uvicorn asgi_app:app --port 8003'
run 'curl -si http://127.0.0.1:8002/hello/ana; echo'
run 'curl -si http://127.0.0.1:8003/hello/ana; echo'
stop wsgi
stop asgi

block compare
at '~'
run 'for p in hello-django hello-fastapi; do echo "$p: $(cd $p && uv pip list 2>/dev/null | tail -n +3 | wc -l) packages, $(du -sh $p/.venv | cut -f1) in .venv"; done'

block logs
quiet 'sleep 1'
lab as 'cat /tmp/django.log; echo ---; cat /tmp/fastapi.log'

block fail-uv
shown 'uv --version' 'env PATH=/usr/local/bin:/usr/bin:/bin bash -c "uv --version"'

block fail-system-python
at '~/hello-django'
run 'python3 manage.py check'
run 'uv run python manage.py check'

block fail-port
run 'uv run python manage.py runserver 8000'

stop django
stop fastapi
lab save 1
