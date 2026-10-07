#!/usr/bin/env bash
# Lesson 17 of portfolio-project: the seven lines that take loanbook's screenshot.
#
# THIS ONE DID NOT RUN IN THE LAB, which has no browser. It runs from a checkout
# of this repository after `npm ci` (Playwright with Chromium), with Python 3
# serving loanbook, and it proves one thing: that shot.mjs, CUT OUT OF
# the-screenshot.md, opens the page and saves a picture 1000 pixels wide. The
# picture in docs/screenshot.png is the one lab.sh carries; this does not
# replace it, because its dates are today's.
#
# What is STAGED rather than typed:
#   - loanbook is rebuilt with lab.sh at step 18 in .shot-demo/ in the checkout,
#     seeded, and served on port 8000 while the script runs.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
CHECKOUT=${CHECKOUT:-/home/user/schooling}
D=$CHECKOUT/.shot-demo
rm -rf "$D"; mkdir -p "$D"
LOANBOOK=$D/lb bash "$CHECKOUT/content/code/courses/portfolio-project/lab.sh" stage 18 >/dev/null 2>&1
awk '/^```javascript$/{f=1; next} /^```$/{if (f) exit} f' "$HERE/the-screenshot.md" > "$D/lb/shot.mjs"
grep -q "page.screenshot" "$D/lb/shot.mjs" || { echo "no shot.mjs in the-screenshot.md" >&2; exit 1; }
cd "$D/lb" && python3 seed.py >/dev/null && (python3 app.py >/dev/null 2>&1 &)
sleep 1
mkdir -p docs && rm -f docs/screenshot.png
printf '$ node shot.mjs\n'
NODE_PATH=$CHECKOUT/node_modules node shot.mjs 2>&1
python3 -c 'import struct; d = open("docs/screenshot.png", "rb").read(24); print(d[1:4].decode(), *struct.unpack(">II", d[16:24]))'
pkill -f '^python3 app[.]py$'
cd "$CHECKOUT" && rm -rf "$D"
