#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED:
#   - The project as it stands at the start of lesson 7 (lessons 1 to 6, one
#     commit each, fixed dates), the pre-commit hook of lesson 6 and the CI
#     server of lesson 1. The virtual environment the earlier lessons made is
#     rebuilt off-screen.
#   - Every branch is pushed to the CI server and run there. The three
#     exception lines and the unused function in app.py are written off-screen
#     and shown on screen with `tail` and `git diff`.
#   - The webhook secret is a made-up value that opens nothing.
# The gate compares an exception's date with the day it runs, so the dates in
# the commands are computed from the day of the recording: four weeks ahead,
# four days ahead and yesterday. On another day they are other dates, and the
# prose quotes the ones of this recording (23 October 2026). The commit hashes
# and the temporary paths pip-audit prints are random.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-4qey5srs
FAR=$(date -d '+28 days' +%F) NEAR=$(date -d '+4 days' +%F) PAST=$(date -d '-1 day' +%F)
lab project 7 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
quiet 'cd linkbox && uv venv -q .venv && uv pip install -q -r requirements.txt -r requirements-dev.txt'

block statuses
run 'python3 -m json.tool --no-such-option 2>/dev/null; echo "exit $?"'
run 'no-such-scanner 2>/dev/null; echo "exit $?"'

block verdict-files
for f in ci/pipeline.sh ci/sast.sh ci/dast.sh; do
  place "$MD/verdicts.md" "$f"
done
for f in ci/gate.py ci/exceptions.txt tests/test_gate.py ci/sca.sh; do
  place "$MD/the-gate.md" "$f"
done

block gate-tests
run '.venv/bin/python -m pytest -q tests/test_gate.py'

block empty
run 'python3 ci/gate.py </dev/null 2>&1 | tail -n 1; echo "exit ${PIPESTATUS[0]}"'

block unresolvable
run 'sed -i s/werkzeug==3.1.9/werkzeug==3.0.1/ requirements.txt'
run 'bash ci/sca.sh; echo "exit $?"'
run 'git checkout -q requirements.txt'

block first-push
run 'git add -A'
run 'git commit -q -m "a gate that breaks, warns or passes, and exceptions that expire"'
run 'git push ci main'

block fixable
run 'git switch -q -c jinja-3.1.4'
run 'sed -i s/jinja2==3.1.6/jinja2==3.1.4/ requirements.txt'
run 'git commit -q -am "jinja2 back to 3.1.4"'
run 'git push ci jinja-3.1.4'

block unfixable
run 'git switch -q main && git switch -q -c ecdsa'
run 'echo ecdsa==0.19.2 >>requirements.txt'
run 'git commit -q -am "ecdsa, to check the signatures of incoming webhooks"'
run 'git push ci ecdsa'

block advisory
run 'pip-audit -r requirements.txt -f json 2>/dev/null | jq -r ".dependencies[] | select(.name == \"ecdsa\") | .vulns[0].description"'

block excepted
run 'git switch -q jinja-3.1.4'
lab as sh -c "cd linkbox && cat >>ci/exceptions.txt" <<EOT
PYSEC-2026-1475 $FAR templates need rework for 3.1.5; Ana, see issue 41
PYSEC-2026-1472 $FAR templates need rework for 3.1.5; Ana, see issue 41
PYSEC-2026-1471 $FAR templates need rework for 3.1.6; Ana, see issue 41
EOT
run 'tail -n 3 ci/exceptions.txt'
run 'git commit -q -am "jinja2 3.1.4 excepted for four weeks, while the templates are reworked"'
run 'git push ci jinja-3.1.4'
run 'cat ~/ci/runs/4/logs/sca.log'

block owner
run 'git blame -s ci/exceptions.txt | tail -n 3'
run 'git log -1 --format="%an, %ad" --date=short -- ci/exceptions.txt'

block near
run "sed -i 's/ $FAR / $NEAR /' ci/exceptions.txt"
run 'bash ci/sca.sh; echo "exit $?"'

block expired
run "sed -i 's/ $NEAR / $PAST /' ci/exceptions.txt"
run 'bash ci/sca.sh; echo "exit $?"'
run 'git checkout -q ci/exceptions.txt'

block secret
run 'git switch -q main && git switch -q -c webhook'
run 'printf "WEBHOOK_SECRET = \"Zr4tq8LmW2xK9vB6nP3sH7yC1dF5gJ0a\"\n" >webhook.py'
run 'git add webhook.py && git commit -q --no-verify -m "verify incoming webhooks"'
run 'git push ci webhook'

block secret-cleanup
run 'git push -q ci --delete webhook'
run 'git switch -q main && git branch -q -D webhook'

block nightly
run 'rm -rf /tmp/nightly && git clone -q ~/ci/linkbox.git /tmp/nightly'
run '/tmp/nightly/ci/pipeline.sh && /tmp/nightly/ci/pipeline.sh ci/nightly'
quiet 'rm -rf /tmp/nightly'

block deadcode
run 'git switch -q -c export'
quiet "python3 - <<'PY'
from pathlib import Path
p = Path('app.py')
p.write_text(p.read_text() + '''

def export_links():
    with open(\"/tmp/linkbox-export.csv\", \"w\") as out:
        for code, url in db().execute(\"SELECT code, url FROM links\"):
            out.write(f\"{code},{url}\\\\n\")
''')
PY"
run 'git diff'
run 'git commit -q -am "an export of every link, for the quarterly report"'
run 'git push ci export'

block baselines
run 'gitleaks git --help | grep baseline'
run 'semgrep scan --help 2>/dev/null | grep -A2 "baseline-commit=VAL"'
run 'pip-audit --help | grep -A2 -- "--ignore-vuln ID  "'

block end
quiet 'git switch -q main'
quiet 'docker rmi -f $(docker images -q linkbox) >/dev/null 2>&1; docker image prune -f >/dev/null 2>&1'
exit 0
