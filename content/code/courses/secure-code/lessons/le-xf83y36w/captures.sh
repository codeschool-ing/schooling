#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of secure-code, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs the workspace lesson 1 builds and starts from no ~/sc/csp.
# app.py, test_app.py, look.py and static/portal.js are taken from the
# lesson's own listings by lab/extract.py. Each change to app.py is the one
# its section describes, applied by an exact string replacement, and
# `git diff` shows it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Before "install", playwright and its dependencies are removed without
#     printing anything, so the install shown is a first install.
#   - `playwright install chromium` is NOT RUN, and the lesson says so. The
#     recording machine had a Chromium build already (version 153.0.8010.12,
#     under /opt/pw-browsers); PLAYWRIGHT_BROWSERS_PATH points Playwright at a
#     folder that presents that build under the name Playwright 1.56.0
#     expects. The console messages are that build's wording.
#   - Every "look-*" block ran with the portal started in the background by
#     serve(), restarted after each change, as a second terminal would.
#     "server-report" is the lines the portal wrote to its own terminal
#     during "look-report", picked out of its log with grep.
#   - "look-early" ran with the header renamed to the enforcing one and
#     renamed back right after, as the lesson asks the student to do.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Python 3.13 as python3, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
export PLAYWRIGHT_BROWSERS_PATH=/var/tmp/pwb
# The folder Playwright 1.56.0 looks in, presenting the machine's Chromium build.
mkdir -p $PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-1194/chrome-linux
ln -sfn /opt/pw-browsers/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell \
  $PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-1194/chrome-linux/headless_shell

D=/home/ana/sc/csp
rm -rf "$D"
( . /home/ana/sc/.venv/bin/activate && flock /var/tmp/secure-code-pip.lock pip uninstall -q -y playwright greenlet pyee typing_extensions ) >/dev/null 2>&1

block setup
run /home/ana/sc 'mkdir csp'
run /home/ana/sc 'cd csp'
run $D 'git init -b main'
git -C $D config user.name ana; git -C $D config user.email ana@vereda.example

put the-portal.md app.py $D/app.py
put the-portal.md test_app.py $D/test_app.py

block red
run $D 'pytest -q --tb=no'

block commit
export GIT_AUTHOR_DATE='2026-11-14 09:00:00 -0300' GIT_COMMITTER_DATE='2026-11-14 09:00:00 -0300'
run $D 'git add app.py test_app.py'
run $D 'git commit -q -m "Greet the patient with her next session"'

block install
run $D 'pip install --progress-bar off playwright==1.56.0'

put the-portal.md look.py $D/look.py
look() {  # look BLOCK: (re)start the portal, run look.py, stop the portal
  serve $D 'flask --app app run'
  block "$1"
  run $D 'python3 look.py'
  unserve
}
look look-plain

fix() {  # fix 'old' 'new': one exact replacement in app.py, which must match once
  python3 - "$1" "$2" <<'PY'
import sys
p = '/home/ana/sc/csp/app.py'
s = open(p).read()
old, new = sys.argv[1], sys.argv[2]
assert s.count(old) == 1, old
open(p, 'w').write(s.replace(old, new))
PY
}

# Report-only.
fix 'from flask import Flask, render_template_string
' 'from flask import Flask, render_template_string, request
'
fix '"""


@app.get("/")' '"""

POLICY = "; ".join([
    "default-src '"'"'self'"'"'",
    "script-src '"'"'self'"'"'",
    "object-src '"'"'none'"'"'",
    "base-uri '"'"'none'"'"'",
    "frame-ancestors '"'"'none'"'"'",
    "form-action '"'"'self'"'"'",
    "report-uri /csp-report",
])


@app.after_request
def send_the_policy(response):
    response.headers["Content-Security-Policy-Report-Only"] = POLICY
    return response


@app.post("/csp-report")
def csp_report():
    report = request.get_json(force=True, silent=True) or {}
    details = report.get("csp-report", {})
    log.warning(
        "csp violation directive=%r blocked=%r",
        details.get("violated-directive"),
        details.get("blocked-uri"),
    )
    return "", 204


@app.get("/")'
block diff-report
run $D 'git diff'
block green-report
run $D 'pytest -q --tb=no'
block commit-report
export GIT_AUTHOR_DATE='2026-11-14 09:30:00 -0300' GIT_COMMITTER_DATE='2026-11-14 09:30:00 -0300'
run $D 'git add look.py'
run $D 'git commit -qam "Send a report-only policy, and log what it reports"'

look look-report
block server-report
grep 'csp violation' /var/tmp/secure-code-server.log

fix 'Content-Security-Policy-Report-Only' 'Content-Security-Policy'
look look-early
fix '"Content-Security-Policy"] = POLICY' '"Content-Security-Policy-Report-Only"] = POLICY'

# Moving the scripts.
block mkdir
run $D 'mkdir static'
put moving-scripts.md static/portal.js $D/static/portal.js
fix '<button onclick="document.getElementById('"'"'when'"'"').classList.toggle('"'"'large'"'"')">Larger text</button>
<script>
  document.title = "Vereda: " + document.getElementById("when").textContent;
</script>
' '<button id="larger">Larger text</button>
<script src="/static/portal.js"></script>
'
block diff-move
run $D 'git diff'
block green-move
run $D 'pytest -q --tb=no'
look look-moved
block commit-move
export GIT_AUTHOR_DATE='2026-11-14 10:00:00 -0300' GIT_COMMITTER_DATE='2026-11-14 10:00:00 -0300'
run $D 'git add static/portal.js'
run $D 'git commit -qam "Move the page'"'"'s scripts into a file"'

# Enforcing.
fix '"Content-Security-Policy-Report-Only"] = POLICY' '"Content-Security-Policy"] = POLICY'
block diff-enforce
run $D 'git diff'
block green-enforce
run $D 'pytest -q'
look look-enforced

serve $D 'flask --app app run'
block curl
run $D 'curl -sI http://127.0.0.1:5000/'
unserve

block commit-fix
export GIT_AUTHOR_DATE='2026-11-14 10:15:00 -0300' GIT_COMMITTER_DATE='2026-11-14 10:15:00 -0300'
run $D 'git commit -qam "Enforce the policy"'
run $D 'git log --oneline'
