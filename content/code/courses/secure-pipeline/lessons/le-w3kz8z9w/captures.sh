#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED:
#   - The project as it stands at the start of lesson 6 (lessons 1 to 5, one
#     commit each, fixed dates, so the first commit is 3f932db every time) and
#     the CI server of lesson 1, already holding that history. The virtual
#     environment the earlier lessons made is rebuilt off-screen.
#   - gitleaks 8.30.1 was already in ~/.local/bin; the install on screen
#     downloads the same release, checks it and installs it over the copy.
#   - git-filter-repo runs through uvx from PyPI, in a throwaway clone that is
#     deleted at the end of the block; the project's history is not rewritten.
#   - The key in export.py is a made-up value that opens nothing.
# The new token is random and never printed; the commit hashes of the commits
# made on screen are random too, because the commits carry the time they were
# made.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-w3kz8z9w
lab project 6 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
quiet 'cd linkbox && uv venv -q .venv && uv pip install -q -r requirements.txt -r requirements-dev.txt && cd ~'

block install
run 'curl -fsSLO https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz'
run 'curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_checksums.txt | grep linux_x64.tar.gz | sha256sum --check'
run 'tar -xzf gitleaks_8.30.1_linux_x64.tar.gz gitleaks'
run 'install -m 755 gitleaks ~/.local/bin/ && rm gitleaks gitleaks_8.30.1_linux_x64.tar.gz'
run 'gitleaks version'

block copies
run 'cd linkbox'
run 'git rev-list --all | wc -l'
run 'git grep -l lbx_7Rq2 $(git rev-list --all)'
run 'git -C ~/ci/linkbox.git grep -n lbx_7Rq2 main -- settings.py'

block dir
run 'gitleaks dir --no-banner --no-color -v .'

block git
run 'gitleaks git --no-banner --no-color -v .'

block tests-fail
place "$MD/the-response.md" settings.py
run '.venv/bin/python -m pytest -q 2>&1 | tail -n 4'

block tests-pass
place "$MD/the-response.md" tests/conftest.py
run '.venv/bin/python -m pytest -q'

block rotate
run "export LINKBOX_TOKEN=\$(python3 -c 'import secrets; print(\"lbx_\" + secrets.token_urlsafe(24))')"
run '.venv/bin/gunicorn --daemon --pid linkbox.pid --bind 127.0.0.1:8000 app:app'
quiet 'sleep 2'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "X-Token: lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x" -d url=https://example.org http://127.0.0.1:8000/links'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "X-Token: $LINKBOX_TOKEN" -d url=https://example.org http://127.0.0.1:8000/links'
run 'kill $(cat linkbox.pid)'

block commit
run 'git add settings.py tests/conftest.py'
run 'git commit -q -m "the token out of the code, and a token of their own for the tests"'

block still-there
run 'gitleaks dir --no-banner --no-color .'
run 'gitleaks git --no-banner --no-color --redact -v .'

block rewrite
run 'git clone -q ~/linkbox ~/rewritten && cd ~/rewritten'
run 'echo "regex:lbx_[A-Za-z0-9]+==>REMOVED" > ~/replace.txt'
run 'uvx --from git-filter-repo==2.47.0 git-filter-repo --replace-text ~/replace.txt'
run 'git log --oneline'
run 'git -C ~/linkbox log --oneline'
run 'git show $(git rev-list --max-parents=0 HEAD):settings.py'
run 'git -C ~/ci/linkbox.git grep -c lbx_7Rq2 main -- settings.py'
run 'cd ~/linkbox && rm -rf ~/rewritten ~/replace.txt'

block ignore
place "$MD/history.md" .gitleaksignore
run 'gitleaks git --no-banner --no-color .'
run 'git add .gitleaksignore'
run 'git commit -q -m "the rotated token, recorded as a dead finding"'

block hook
place "$MD/before-the-commit.md" "~/linkbox/.git/hooks/pre-commit"
run 'chmod +x .git/hooks/pre-commit'

block refused
run 'printf "EXPORT_KEY = \"kq83JdZ0p1Vx7LmN4tR6sW9yB2cF5hG8\"\n" > export.py'
run 'git add export.py'
run 'git commit -m "export the links to the reporting service"'
run 'git log --oneline -1'
run 'git restore --staged export.py && rm export.py'

block boot
for f in ci/secrets.sh ci/stages ci/dast.sh; do
  place "$MD/in-the-pipeline.md" "$f"
done
run 'docker build -q -t linkbox:dev . && docker run --rm linkbox:dev 2>&1 | tail -n 5'

block push
run 'git add ci'
run 'git commit -q -m "secret scanning first in the pipeline, and a token for the staging copy"'
run 'git push ci main'

block run-log
run 'cat ~/ci/runs/1/logs/secrets.log'

block end
quiet 'docker rmi -f $(docker images -q linkbox) >/dev/null 2>&1; docker image prune -f >/dev/null 2>&1'
exit 0
