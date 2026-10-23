#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of python-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and why.
#   - Docker cannot run inside the systemd-nspawn machine the other lessons
#     use, so this lesson's docker commands run on the recording computer
#     itself, as a user ana, against copies of ~/agenda and ~/agenda-api
#     taken from the machine lesson 16 left (`lab.sh reset 17`). The `uv add`
#     the lesson shows runs on that machine, and the copies are taken again
#     after it. Both print the same prompt, because for a student they are
#     one machine.
#   - The daemon is Docker Engine 29.8 from Docker's own packages, configured
#     as the docker course's lab is: Docker Hub images come through
#     mirror.gcr.io, Google's public cache of Docker Hub.
#   - A container on the recording computer does not trust the gateway that
#     re-signs its TLS, so it cannot reach PyPI. The uv cache that each
#     Dockerfile mounts is therefore filled before each build the lesson
#     shows, by a build of lab/warm.Dockerfile, which runs the same `uv sync`
#     with the computer's certificates passed in as a build secret. The build
#     the lesson shows then installs from that cache, which is why its log
#     names no downloads; a student's first build downloads the same packages
#     from PyPI.
#   - Every run starts from a daemon with no containers, volumes or build
#     cache, and with the images it pulls already present, except hello-world,
#     which is removed so the transcript shows its pull.
#   - Ids, digests, sizes, dates and the generated secrets are the ones of
#     the run.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"

VMROOT=/var/lib/machines/pyback
hdir() { [ "$HERE" = '~' ] && echo /home/ana || echo "/home/ana${HERE#\~}"; }
hrun() { # the same prompt, on the recording computer, as its user ana
  printf 'ana@vm:%s$ %s\n' "$HERE" "$1"
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo LC_ALL=C.UTF-8 \
    bash -c "cd $(hdir) && $1" 2>&1 </dev/null || true
}
hquiet() { hrun "$1" >/dev/null; }
hfrom() { # hfrom MD PATH DEST: the file as the lesson shows it, into ana's tree here
  python3 "$COURSE/lab/mdfile.py" "$LESSON/$1" "$2" > "$(hdir)/$3" || { echo "hfrom: $2 is not in $1" >&2; exit 1; }
  chown ana:ana "$(hdir)/$3"
}
sync() { # the two projects, as the machine of the other lessons has them
  for p in agenda agenda-api; do
    rsync -a --delete --exclude .venv --exclude __pycache__ --exclude .pytest_cache \
      --exclude Dockerfile --exclude .dockerignore "$VMROOT/home/ana/$p/" "/home/ana/$p/"
  done
  chown -R ana:ana /home/ana
}
warm() { # fill the uv cache mount for PROJECT (see the header)
  ( cd "/home/ana/$1" && docker build -q -f "$COURSE/lab/warm.Dockerfile" \
      --secret id=ca,src=/etc/ssl/certs/ca-certificates.crt . >/dev/null 2>&1 ) || { echo "warm $1 failed" >&2; exit 1; }
}
daemon() {
  mkdir -p /etc/docker
  printf '{\n  "registry-mirrors": ["https://mirror.gcr.io"]\n}\n' > /etc/docker/daemon.json
  if ! docker info >/dev/null 2>&1; then
    setsid dockerd >/var/log/dockerd.log 2>&1 </dev/null &
    for _ in $(seq 30); do docker info >/dev/null 2>&1 && break; sleep 1; done
  fi
  docker info >/dev/null 2>&1 || { echo "no docker daemon" >&2; exit 1; }
  ids=$(docker ps -aq); [ -n "$ids" ] && docker rm -f $ids >/dev/null
  docker volume prune -af >/dev/null; docker network prune -f >/dev/null; docker builder prune -af >/dev/null
  for img in agenda:0.1.0 agenda-api:0.1.0 agenda:test hello-world; do docker image rm -f "$img" >/dev/null 2>&1 || true; done
  for img in python:3.12-slim astral/uv:0.13.1 postgres:16 redis:7; do docker pull -q "$img" >/dev/null; done
}

lab reset 17
asroot 'systemctl enable --now postgresql'
daemon
id ana >/dev/null 2>&1 || useradd --create-home --shell /bin/bash ana
getent group docker >/dev/null || groupadd docker
usermod -aG docker ana
rm -rf /home/ana/agenda /home/ana/agenda-api /home/ana/deploy
mkdir -p /home/ana/agenda /home/ana/agenda-api
sync

block install
hrun 'docker --version'
hrun 'docker compose version'
hrun 'id -nG'
hrun 'docker run --rm hello-world | head -2'

block django-image
at '~/agenda'
hfrom an-image-for-django.md Dockerfile Dockerfile
hfrom an-image-for-django.md .dockerignore .dockerignore
warm agenda
hrun 'docker build -t agenda:0.1.0 . 2>&1 | grep -E "^#[0-9]+ \[stage|^#[0-9]+ [0-9.]+ (Installed|Bytecode)|naming to"'
hrun 'docker run --rm agenda:0.1.0 python -c "import psycopg" 2>&1 | tail -4'

block binary
run 'uv add "psycopg[binary]"'
at '~/agenda-api'
run 'uv add "psycopg[binary]"'
at '~/agenda'
sync
warm agenda
hrun 'docker build -q -t agenda:0.1.0 .'
hrun 'docker run --rm agenda:0.1.0 python -c "import psycopg; print(psycopg.pq.__impl__, psycopg.pq.version())"'
hrun 'docker run --rm agenda:0.1.0 whoami'
hrun 'docker image ls agenda'

block api-image
at '~/agenda-api'
hfrom an-image-for-fastapi.md Dockerfile Dockerfile
hfrom an-image-for-fastapi.md .dockerignore .dockerignore
warm agenda-api
hrun 'docker build -q -t agenda-api:0.1.0 .'
hrun 'docker run --rm agenda-api:0.1.0 ls'
hrun 'docker run --rm agenda-api:0.1.0 python -c "from app.config import settings" 2>&1 | tail -3'

block deploy
at '~'
run 'sudo systemctl disable --now agenda agenda-worker agenda-beat agenda-api'
hrun 'mkdir deploy'
at '~/deploy'
hfrom compose.md compose.yaml compose.yaml
hrun "for name in DJANGO_SECRET_KEY DATABASE_PASSWORD API_SECRET_KEY API_DATABASE_PASSWORD; do echo \"\$name=\$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')\"; done > .env"
hrun 'chmod 600 .env && cut -d= -f1 .env'
hrun 'docker compose config --services'
hrun 'docker compose up -d --wait db api-db redis 2>&1 | grep -v "^ *Image\|Pulling\|Pulled"'

block migrate
hrun 'docker compose run --rm web python manage.py migrate 2>&1 | tail -3'
hrun 'docker compose run --rm api alembic upgrade head 2>&1 | tail -3'
hrun 'docker compose up -d --wait 2>&1 | tail -4'
hquiet 'for _ in $(seq 60); do docker compose logs api 2>&1 | grep -q Error && break; sleep 1; done'
hrun 'docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"'
hrun 'curl -s -o /dev/null -w "%{http_code}\n" -H "Host: agenda.example.org" -H "X-Forwarded-Proto: https" http://127.0.0.1:8000/events/'
hrun 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8001/events'
hrun 'docker compose logs api 2>&1 | grep -m1 Error'

block httpx
at '~/agenda-api'
run 'uv remove --dev httpx2'
run 'uv add httpx2'
sync
warm agenda-api
hrun 'docker build -q -t agenda-api:0.1.0 .'
at '~/deploy'
hrun 'docker compose up -d --wait api 2>&1 | tail -1'
hquiet 'for _ in $(seq 60); do curl -sf -o /dev/null http://127.0.0.1:8001/events && break; sleep 1; done'
hrun 'curl -s http://127.0.0.1:8001/events; echo'
hrun 'docker compose logs --tail 2 worker'

block persist
hrun "docker compose exec web python manage.py shell -v 0 -c \"from django.contrib.auth.models import User; User.objects.create_user('ana', 'ana@example.org', 'not-a-real-password'); print(User.objects.count())\""
hrun 'docker compose down 2>&1 | tail -3'
hrun 'docker compose up -d --wait 2>&1 | tail -2'
hrun "docker compose exec web python manage.py shell -v 0 -c \"from django.contrib.auth.models import User; print(User.objects.count())\""
hrun 'docker volume ls --format "{{.Name}}"'

block release
hrun 'docker compose exec web python manage.py check --deploy 2>&1 | grep "^?:" | cut -c1-72'
hrun 'docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -4'
hrun 'docker compose down 2>&1 | tail -1'

lab save 17
