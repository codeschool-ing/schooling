#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the end of lesson 15 (one
# commit per lesson, fixed dates), the registry, and the CI server's signing
# keys from lesson 14. zizmor is uninstalled first, off screen, so the
# lesson's `uv tool install` is a real install; the end of the script makes
# sure it is back. The first, careless workflow is written with `put` and is
# shown whole in the lesson; the fixed one, ci/workflows.sh and ci/stages are
# copied out of the lesson's own fences (`place`). The branch that brings the
# careless line back is made with sed, and the lesson shows its diff.
# Nothing here runs on GitHub: the workflow is audited, never executed.
# The commit hashes, times and stage timings differ on every run; the
# commits that `git ls-remote` prints are whatever the tags name that day.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1 and zizmor 1.31.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-3mskyaq8
lab project 16 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
quiet 'uv tool uninstall zizmor >/dev/null 2>&1'

block install
run 'uv tool install zizmor==1.31.1'
run 'zizmor --version'

block careless
run 'cd linkbox && mkdir -p .github/workflows'
put .github/workflows/ci.yml <<'YML'
# linkbox's tests on GitHub Actions, written the way a first version
# often is. Every line of it works.
name: ci
on:
  pull_request_target:
permissions: write-all
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - uses: astral-sh/setup-uv@v9
      - name: Say which change this is
        run: echo "testing ${{ github.event.pull_request.title }}"
      - run: bash ci/test.sh
YML
run 'zizmor --quiet --offline .github; echo "exit status $?"'

block auditor
run 'zizmor --quiet --offline --persona auditor .github | grep -E "^(error|warning|help|info)\["'

block ls-remote
run 'git ls-remote https://github.com/actions/checkout refs/tags/v6 refs/tags/v6.1.0'
run 'git ls-remote https://github.com/astral-sh/setup-uv refs/tags/v9.0.0'

block fixed
place "$MD/the-fix.md" .github/workflows/ci.yml
run 'zizmor --quiet --offline .github; echo "exit status $?"'
run 'zizmor --quiet --offline --persona auditor .github'

block this-ci
run 'id'
run 'ls -l /var/run/docker.sock'
run 'ps -C dockerd -o user=,pid=,comm='

block pipeline
place "$MD/in-the-pipeline.md" ci/workflows.sh
place "$MD/in-the-pipeline.md" ci/stages
run 'git add .github ci'
run 'git commit -q -m "the pipeline'"'"'s own workflow hardened, and checked by zizmor on every push"'
run 'git push ci main'

block regression
run 'git switch -q -c title-in-run'
quiet "sed -i 's/        run: echo \"testing \$TITLE\"/        run: echo \"testing \${{ github.event.pull_request.title }}\"/' .github/workflows/ci.yml"
run 'git diff | grep "^[-+] "'
run 'git commit -q -am "print the title directly"'
run 'git push ci title-in-run'

block end
quiet 'git switch -q main && git branch -q -D title-in-run'
quiet 'command -v zizmor >/dev/null || uv tool install -q zizmor==1.31.1'
docker rmi -f $(docker images -q linkbox) $(docker images -q localhost:5000/linkbox) >/dev/null 2>&1
docker image prune -f >/dev/null 2>&1
exit 0
