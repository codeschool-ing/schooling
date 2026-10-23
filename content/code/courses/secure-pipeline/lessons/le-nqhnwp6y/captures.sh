#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the end of lesson 14 (one
# commit per lesson, fixed dates), the registry, and the CI server's signing
# keys. The .venv with lesson 5's pins is made off screen, as a student who
# followed the course already has it. Every file the lesson changes is copied
# out of the lesson's own fences (`place`); requirements.txt and
# requirements-dev.txt are made by the `uv pip compile` commands on screen.
# ~/scratch/ecdsa is a partial clone made on screen and removed at the end.
# PyPI's answers (release dates, advisories) are what PyPI said on the day of
# the recording; the commit hashes, image ids and timings differ on every run.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1 and uv 0.11.32, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-nqhnwp6y
lab project 15 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
quiet 'cd linkbox && uv venv -q && uv pip install -q -r requirements.txt -r requirements-dev.txt'

block tree
run 'uv pip tree --package gunicorn --package flask'

block gunicorn-releases
run 'curl -s https://pypi.org/pypi/gunicorn/json | jq -r ".releases | to_entries[] | select(.value | length > 0) | \"\(.value[0].upload_time[:10]) \(.key)\"" | sort | tail -n 12'
run 'for v in 22.0.0 26.2.0; do echo "$v: $(curl -s https://pypi.org/pypi/gunicorn/$v/json | jq -c "[.info.requires_dist[] | select(contains(\"extra\") | not)]")"; done'

block keeps
place "$MD/the-lock.md" requirements.in
place "$MD/the-lock.md" requirements-dev.in
run 'uv pip compile requirements.in --exclude-newer 2026-10-16 -o requirements.txt 2>/dev/null | grep -E "^(click|gunicorn|markupsafe)=="'

block compile
run 'rm requirements.txt requirements-dev.txt'
run 'uv pip compile -q requirements.in --generate-hashes --exclude-newer 2026-10-16 -o requirements.txt'
run 'uv pip compile -q requirements-dev.in --generate-hashes --exclude-newer 2026-10-16 -o requirements-dev.txt'
run 'head -n 10 requirements.txt'
run 'grep "==" requirements.txt requirements-dev.txt'
run 'grep -c -- "--hash=sha256" requirements.txt requirements-dev.txt'

block packaging
run 'printf "flask>=3.1.3,<4\ngunicorn>=22,<23\n" | uv pip compile - --exclude-newer 2026-10-16 --no-header 2>/dev/null | grep -A1 "^packaging"'

block dates
run 'for d in 2024-06-01 2026-10-16; do echo "$d: $(echo flask | uv pip compile - --exclude-newer $d --no-header 2>/dev/null | grep -E "^(flask|werkzeug)==" | tr "\n" " ")"; done'
run 'uv pip compile requirements.in --exclude-newer 2026-08-01 --no-header 2>&1 | tail -n 1'

block tests
place "$MD/the-lock.md" ci/test.sh
quiet 'rm -rf .venv'
run 'bash ci/test.sh'

block digests
run 'docker buildx imagetools inspect mirror.gcr.io/library/python:3.13-slim | head -n 3'
run 'docker image inspect --format "{{index .RepoDigests 0}}" gcr.io/distroless/python3-debian13:nonroot'

block offline-old
run 'docker build -q --network none -t linkbox:offline . 2>&1 | tail -n 4'

block build
place "$MD/no-network.md" Dockerfile
place "$MD/no-network.md" ci/build.sh
place "$MD/no-network.md" .gitignore
place "$MD/no-network.md" .dockerignore
place "$MD/no-network.md" bandit.yaml
run 'bash ci/build.sh'
run 'ls wheels'

block commit
run 'git add -A'
run 'git status --short'
run 'git commit -q -m "dependencies compiled with their hashes, base images by digest, and a build with no network"'
run 'git push ci main'

block packaging-gone
run 'docker run --rm --entrypoint python3 linkbox:$(git rev-parse --short HEAD) -c "import importlib.util as u; print(u.find_spec(\"packaging\"), u.find_spec(\"gunicorn\").origin)"'

block ecdsa
run 'curl -s https://pypi.org/pypi/ecdsa/json | jq -r ".releases | to_entries[] | select(.value | length > 0) | \"\(.value[0].upload_time[:10]) \(.key)\"" | sort | tail -n 4'
run 'curl -s https://pypi.org/pypi/ecdsa/0.19.2/json | jq -r ".vulnerabilities[] | \"\(.id) \(.aliases | join(\" \")) fixed_in=\(.fixed_in)\""'
run 'curl -s https://pypi.org/pypi/ecdsa/0.19.2/json | jq -r ".vulnerabilities[0].details" | fold -s -w 96'

block ecdsa-repo
run 'git clone -q --filter=blob:none --no-checkout https://github.com/tlsfuzzer/python-ecdsa ~/scratch/ecdsa'
run 'git -C ~/scratch/ecdsa log -1 --format="%cs %s"'
run 'git -C ~/scratch/ecdsa shortlog -sn --no-merges --since=2025-10-01 HEAD'

block replace
place "$MD/replace.md" "~/scratch/sign.py"
run 'uv run -q --no-project --with "cryptography==50.0.2" python ~/scratch/sign.py'

block end
quiet 'rm -rf ~/scratch'
docker rmi -f $(docker images -q linkbox) $(docker images -q localhost:5000/linkbox) >/dev/null 2>&1
docker image prune -f >/dev/null 2>&1
exit 0
