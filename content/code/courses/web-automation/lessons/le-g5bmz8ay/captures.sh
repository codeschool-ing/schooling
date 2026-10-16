#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. tests/page-object.spec.js is
# shown three times, in `the-duplication`, `a-page-object` and `fixtures`;
# pages/shop-page.js twice, in `a-page-object` and `components`, which also
# shows pages/product-card.js, pages/basket-summary.js and
# tests/page-object-card.spec.js; `fixtures` shows tests/fixtures.js. `stage 12`
# leaves the last version of each. What is STAGED rather than typed, beyond
# what ../../lab.sh's header lists for every lesson:
#   - in "dup", "dup-cart", "po", "po-cart", "po-cart-fixed" and "components",
#     the earlier versions of the two files above, taken from their own
#     sections with `lab.sh fence` and replaced by the final ones after;
#   - in "dup-cart" and "po-cart", the button's text changed in
#     app/public/app.js with the sed the transcript shows, the markup change the
#     sections describe, and put back after; in "po-cart-fixed", the one line of
#     pages/shop-page.js changed the same way, and put back;
#   - in "number", the method `itemCount()` the section shows appended to
#     pages/basket-summary.js, and tests/page-object-number.spec.js written from
#     the section's unlabelled block (whose route delays the basket's answer
#     by 200 ms, as the prose says); both are taken out after;
#   - every run that adds to the basket uses --workers 1: the shop has one
#     basket for everybody (lesson 15), and the prose says so;
#   - Playwright's colour codes (ESC[...m) are stripped from the test runs,
#     which is what a terminal shows once it has drawn them.
#
# Recorded 2026-10-11 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 12 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolor() { sed 's/\x1b\[[0-9;]*m//g'; }
version() {   # write one section's version of a file into the project; a
              # schooling-example is joined from its parts, as stage does
  bash "$HERE/../../lab.sh" fence "$HERE/$1" "$2" | python3 -c '
import json, sys
s = sys.stdin.read()
if s.startswith("{"):
    s = "\n".join(p["code"] for p in json.loads(s)["parts"]) + "\n"
sys.stdout.write(s)' > "$2"
  chown ana:ana "$2"
}

block dup
version the-duplication.md tests/page-object.spec.js
run 'npx playwright test tests/page-object.spec.js --workers 1' | nocolor

block dup-cart
run "sed -i 's/>Add to basket</>Add to cart</' app/public/app.js"
run 'npx playwright test tests/page-object.spec.js --workers 1' | nocolor
run "sed -i 's/>Add to cart</>Add to basket</' app/public/app.js"

block po
version a-page-object.md tests/page-object.spec.js
version a-page-object.md pages/shop-page.js
run 'npx playwright test tests/page-object.spec.js --workers 1' | nocolor

block po-cart
run "sed -i 's/>Add to basket</>Add to cart</' app/public/app.js"
run 'npx playwright test tests/page-object.spec.js --workers 1' | nocolor

block po-cart-fixed
run "sed -i \"s/name: 'Add to basket'/name: 'Add to cart'/\" pages/shop-page.js"
run 'npx playwright test tests/page-object.spec.js --workers 1' | nocolor
as_ana "cd $P && sed -i 's/>Add to cart</>Add to basket</' app/public/app.js"
version a-page-object.md pages/shop-page.js

block components
version components.md pages/shop-page.js
run 'npx playwright test tests/page-object.spec.js tests/page-object-card.spec.js --workers 1' | nocolor

block number
cp pages/basket-summary.js /tmp/l12-basket-summary.js
python3 - pages/basket-summary.js <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().rstrip()
assert s.endswith("}")
s = s[:-1].rstrip() + "\n\n  async itemCount() {\n    return Number(await this.count.textContent());\n  }\n}\n"
open(p, "w").write(s)
PY
python3 - "$HERE/assertions-belong-in-tests.md" tests/page-object-number.spec.js <<'PY'
import re, sys
md = open(sys.argv[1]).read()
blocks = re.findall(r"```javascript\n(.*?)\n```", md, re.S)
spec = [b for b in blocks if "the count, read as a number" in b][0]
open(sys.argv[2], "w").write(spec + "\n")
PY
chown ana:ana pages/basket-summary.js tests/page-object-number.spec.js
run "npx playwright test tests/page-object-number.spec.js --workers 1 --repeat-each 5 | grep -E 'passed|failed|✘|✓|Received'" | nocolor
rm -f tests/page-object-number.spec.js
cp /tmp/l12-basket-summary.js pages/basket-summary.js; chown ana:ana pages/basket-summary.js

block fixtures
version fixtures.md tests/page-object.spec.js
run 'npx playwright test tests/page-object.spec.js tests/page-object-card.spec.js --workers 1' | nocolor
