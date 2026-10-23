#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of secure-pipeline, as a script
# that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: the project as lesson 17 leaves it, with the registry and
# the signing keys (lessons 8 and 14). Every file the lesson has the student
# save is copied out of the lesson's own fences (`place`); the first, short
# .github/dependabot.yml is written with `put` and is the one the lesson
# shows before the finding.
#
# WHAT DIFFERS BETWEEN RUNS: the answers of PyPI and npm on the day of the
# recording (what is newest, how old each release is), the commit hashes,
# the run numbers and the stage timings. Node.js and Renovate are downloaded
# on screen and removed, with npm's cache, at the end.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-rk8bxs0t
NODE=node-v24.21.0-linux-x64
lab project 18 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
bash "$COURSE/lab.sh" as sh -c "rm -rf ~/.npm ~/.local/$NODE /tmp/renovate /tmp/report.json /tmp/renovate.log"

block dependabot-first
run 'cd linkbox'
run 'mkdir -p .github'
put .github/dependabot.yml <<'EOF'
version: 2
updates:
  - package-ecosystem: pip
    directory: /
    schedule:
      interval: weekly
EOF
run 'zizmor --offline -q .github/dependabot.yml; echo "exit $?"'

block dependabot-pass
place "$MD/dependabot.md" .github/dependabot.yml
run 'zizmor --offline -q .github/dependabot.yml; echo "exit $?"'

block dependabot-push
run 'git add .github/dependabot.yml'
run 'git commit -q -m "dependabot: weekly, grouped, and nothing younger than 14 days"'
run 'git push ci main'

block node
run "curl -fsSLO https://nodejs.org/dist/v24.21.0/$NODE.tar.xz"
run "curl -fsSL https://nodejs.org/dist/v24.21.0/SHASUMS256.txt | grep \" $NODE.tar.xz\$\" | sha256sum --check"
run "tar -xJf $NODE.tar.xz -C ~/.local && rm $NODE.tar.xz"
run "export PATH=~/.local/$NODE/bin:\$PATH"
run 'node --version'

block renovate-commit
place "$MD/renovate.md" renovate.json
run 'git add renovate.json'
run 'git commit -q -m "renovate: the same rules, for running it anywhere"'

block renovate-main
run 'npx --yes renovate@44.164.10 --platform=local --report-type=file --report-path=/tmp/report.json'
run 'jq -c .repositories.local.libYearsWithStatus.dependencyStatus /tmp/report.json'

block stale
run 'git switch -c stale-lock'
run 'uv pip compile -q requirements.in --generate-hashes --exclude-newer 2026-09-20 -o requirements.txt'
run 'uv pip compile -q requirements-dev.in --generate-hashes --exclude-newer 2026-09-20 -o requirements-dev.txt'
run 'git diff --stat'
run 'git commit -q -am "the lock as it was compiled on 20 September"'

block renovate-stale
run 'npx --yes renovate@44.164.10 --platform=local --report-type=file --report-path=/tmp/report.json >/tmp/renovate.log 2>&1'
cmd=$(cat <<'EOF'
jq -c '.repositories.local.packageFiles.pip_requirements[] | .packageFile as $file | .deps[] | select(.updates | length > 0) | {$file, dep: .depName, from: .currentVersion, to: .updates[0].newVersion, waiting: (.updates[0].pendingChecks // false)}' /tmp/report.json
EOF
)
run "$cmd"
run 'git status --short'

block push-stale
run 'git push ci stale-lock'

block fix
run 'pip-audit --fix -r requirements.txt -r requirements-dev.txt'
run 'grep -A2 "^werkzeug" requirements.txt requirements-dev.txt'
run 'git diff --stat'

block push-fix
run 'git commit -q -am "pip-audit --fix"'
run 'git push ci stale-lock'

block right-fix
run 'git reset -q --hard HEAD~1'
run 'uv pip compile -q requirements.in --generate-hashes --exclude-newer 2026-10-16 -P werkzeug -o requirements.txt'
run 'git diff'

block push-right
run 'git commit -q -am "werkzeug 3.1.9, for PYSEC-2026-4312"'
run 'git push ci stale-lock'

block releases
run 'git switch -q main'
place "$MD/noise-budget.md" "~/releases.py"
run 'python3 ~/releases.py 2026-10-16 requirements.txt requirements-dev.txt'

block end
bash "$COURSE/lab.sh" as sh -c "rm -rf ~/.npm ~/.local/$NODE /tmp/renovate /tmp/report.json /tmp/renovate.log ~/releases.py"
docker rmi -f $(docker images -q linkbox) >/dev/null 2>&1
exit 0
