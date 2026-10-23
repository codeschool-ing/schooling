#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# It starts from a machine with Docker, git and Python and nothing of the
# course: no ~/linkbox, no ~/ci, and no uv, which the lesson installs. Every
# file of the project is copied out of the lesson's own fences (`place`), so
# what runs here is what the student saves.
#
# WHAT IS STAGED:
#   - Docker Engine was installed and ana added to the docker group before the
#     recording; the lesson gives the commands and says they were not run.
#   - "PyPI cannot be reached" is produced by pointing uv at a proxy address
#     where nothing listens (HTTPS_PROXY=http://127.0.0.1:9), which is what uv
#     sees when the network is down. "The daemon is not running" points the
#     client at a socket nothing listens on, for the same reason: stopping the
#     real daemon would stop the recording.
#   - "the port is taken" is a small web server started beforehand on 8000.
# The short codes linkbox makes are random, and so are the commit hashes,
# because the commits carry the time they were made.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-4588gzk1
bash "$COURSE/lab.sh" as sh -c 'rm -rf ~/linkbox ~/ci ~/.local/bin/uv ~/.local/bin/uvx ~/.gitconfig ~/.cache/uv'
docker rmi -f $(docker images -q linkbox) >/dev/null 2>&1
docker builder prune -af >/dev/null 2>&1

block versions
run 'docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"'
run 'id -nG'
run 'git --version'
run 'python3 --version'

block uv
run 'curl -fsSLO https://github.com/astral-sh/uv/releases/download/0.11.32/uv-x86_64-unknown-linux-gnu.tar.gz'
run 'curl -fsSL https://github.com/astral-sh/uv/releases/download/0.11.32/uv-x86_64-unknown-linux-gnu.tar.gz.sha256 | sha256sum --check'
run 'tar -xzf uv-x86_64-unknown-linux-gnu.tar.gz'
run 'mkdir -p ~/.local/bin && install -m 755 uv-x86_64-unknown-linux-gnu/uv uv-x86_64-unknown-linux-gnu/uvx ~/.local/bin/'
run 'rm -r uv-x86_64-unknown-linux-gnu*'
run 'uv --version'

block identity
run 'git config --global user.name "Ana Lima"'
run 'git config --global user.email ana@example.org'
run 'git config --global init.defaultBranch main'

block mkdir
run 'mkdir linkbox && cd linkbox'
run 'git init'
for f in app.py settings.py requirements.txt requirements-dev.txt tests/test_app.py Dockerfile .gitignore .dockerignore; do
  place "$MD/linkbox.md" "$f"
done

block tests
run 'uv venv'
run 'uv pip install -r requirements.txt -r requirements-dev.txt'
run '.venv/bin/python -m pytest -q'

block use
run '.venv/bin/gunicorn --daemon --pid linkbox.pid --bind 127.0.0.1:8000 app:app'
quiet 'sleep 2'
run 'curl -s -X POST -H "X-Token: lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x" -d url=https://example.org/docs/handbook/onboarding http://127.0.0.1:8000/links'
run 'code=$(curl -s -X POST -H "X-Token: lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x" -d url=https://example.org/status http://127.0.0.1:8000/links | jq -r .code)'
run 'curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" http://127.0.0.1:8000/$code'
run 'curl -s "http://127.0.0.1:8000/search?q=handbook"'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X POST -d url=https://example.org http://127.0.0.1:8000/links'
run 'kill $(cat linkbox.pid)'

block commit
run 'git add -A'
run 'git status --short'
run 'git commit -q -m "linkbox as it was handed over"'
run 'git log --oneline'

block pipeline-commit
for f in ci/pipeline.sh ci/stages ci/test.sh ci/build.sh; do
  place "$MD/the-pipeline.md" "$f"
done
run 'chmod +x ci/pipeline.sh'
run 'git add ci'
run 'git commit -q -m "a pipeline: the tests, then the image"'

block bare
run 'mkdir ~/ci'
run 'git init --bare ~/ci/linkbox.git'
place "$MD/the-pipeline.md" "~/ci/linkbox.git/hooks/post-receive"

block remote
run 'chmod +x ~/ci/linkbox.git/hooks/post-receive'
run 'git remote add ci ~/ci/linkbox.git'

block push
run 'git push ci main'

block runs
run 'ls ~/ci/runs/1'
run 'ls ~/ci/runs/1/logs'
run 'cat ~/ci/runs/1/logs/test.log'

block images
run 'docker images linkbox'

block fail-hook
run 'chmod -x ~/ci/linkbox.git/hooks/post-receive'
run 'git commit -q --allow-empty -m "does the CI run?"'
run 'git push ci main'
run 'chmod +x ~/ci/linkbox.git/hooks/post-receive'

block fail-docker
run 'DOCKER_HOST=unix:///run/nothing.sock docker version --format "{{.Server.Version}}"'

block fail-network
run 'rm -rf .venv && uv venv -q'
quiet 'uv cache clean'
run 'HTTPS_PROXY=http://127.0.0.1:9 uv pip install -r requirements.txt'

block fail-port
quiet 'setsid python3 -m http.server 8000 --bind 127.0.0.1 >/dev/null 2>&1 </dev/null & echo $! > /tmp/web.pid'
quiet 'sleep 1'
quiet 'uv pip install -q -r requirements.txt'
run '.venv/bin/gunicorn --bind 127.0.0.1:8000 app:app'
quiet 'kill $(cat /tmp/web.pid); rm -f /tmp/web.pid'

block end
docker rmi -f $(docker images -q linkbox) >/dev/null 2>&1
exit 0
