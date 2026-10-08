#!/usr/bin/env bash
# Lesson 13 of portfolio-project: what axe and a keyboard find on loanbook's page.
#
# THIS ONE DID NOT RUN IN THE LAB. laptop and srv have no browser, so these two
# checks ran on the machine that recorded the course, from a checkout of this
# repository after `npm ci` (Playwright with Chromium, and @axe-core/playwright
# 4.13), with Python 3.11 serving loanbook. The transcripts in the lesson say `$`
# rather than ana@laptop for that reason.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - loanbook is rebuilt with lab.sh at step 10, then at step 12; each time two
#     items are added, Projector 2 is lent, and the server started on port 8000.
#   - The two scripts are written into .axe-demo/ in the checkout.
# THE PROGRAMS ARE CUT OUT OF THE LESSON, so the file a student copies is the
# file that ran: axe-check.mjs is the code of with-a-tool.md's example, its
# parts joined, and tab-walk.mjs is with-a-keyboard.md's javascript fence.
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p ${CHECKOUT:-/home/user/schooling}/.axe-demo
python3 - "$HERE" ${CHECKOUT:-/home/user/schooling}/.axe-demo <<'PY'
import json, re, sys
here, out = sys.argv[1], sys.argv[2]
tool = open(f"{here}/with-a-tool.md").read()
example = json.loads(re.search(r"^```schooling-example\n(.*?)\n```$", tool, re.S | re.M).group(1))
open(f"{out}/axe-check.mjs", "w").write("".join(p["code"] + "\n" for p in example["parts"]))
keys = open(f"{here}/with-a-keyboard.md").read()
open(f"{out}/tab-walk.mjs", "w").write(re.search(r"^```javascript\n(.*?)^```$", keys, re.S | re.M).group(1))
PY
set -u
D=${CHECKOUT:-/home/user/schooling}/.axe-demo
run() { printf '$ %s\n' "$*"; bash -c "$*" 2>&1; }
serve() { rm -rf $D/lb; LOANBOOK=$D/lb bash ${CHECKOUT:-/home/user/schooling}/content/code/courses/portfolio-project/lab.sh stage $1 >/dev/null 2>&1
  (cd $D/lb && python3 app.py add "Projector 1" >/dev/null && python3 app.py add "Projector 2" >/dev/null && (python3 app.py >/dev/null 2>&1 &) ); sleep 1
  curl -s -X POST localhost:8000/api/items/2/loan -d '{"borrower": "Beatriz Nunes"}' >/dev/null; }
stop() { pkill -f '^python3 app[.]py$'; sleep 0.5; }
cd $D
serve 10
printf '##### before\n'
run node axe-check.mjs
printf '##### before-tab\n'
run node tab-walk.mjs
stop
serve 12
printf '##### after\n'
run node axe-check.mjs
printf '##### after-tab\n'
run node tab-walk.mjs
stop
