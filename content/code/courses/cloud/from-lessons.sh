# Sourced by the lessons' captures.sh. Not for the student, who has none of it.
#
# THE PROGRAMS A CAPTURE RUNS ARE READ OUT OF THE LESSON THAT SHOWS THEM, so the
# two cannot drift apart: there is no second copy of prices.py to edit.
#
#   prices_py DIR      writes DIR/prices.py from the example in lesson 1,
#                      section the-price-sheet: its code parts, in order
#   sh_fences FILE N   prints the Nth ```sh fence of FILE (counted from 1)

CLOUD_COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

prices_py() {
  python3 - "$CLOUD_COURSE/lessons/le-2wg89q1w/the-price-sheet.md" "$1/prices.py" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
blocks = re.findall(r'^```schooling-example\n(.*?)\n```$', text, re.S | re.M)
found = [b for b in (json.loads(x) for x in blocks) if b.get('file') == 'prices.py']
if len(found) != 1:
    sys.exit(f'{sys.argv[1]}: expected one example for prices.py, found {len(found)}')
open(sys.argv[2], 'w').write(''.join(p['code'] for p in found[0]['parts']))
PY
}

sh_fences() {
  python3 - "$1" "$2" <<'PY'
import re, sys
fences = re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)
n = int(sys.argv[2])
if not 1 <= n <= len(fences):
    sys.exit(f'{sys.argv[1]}: no sh fence number {n} (there are {len(fences)})')
sys.stdout.write(fences[n - 1])
PY
}
