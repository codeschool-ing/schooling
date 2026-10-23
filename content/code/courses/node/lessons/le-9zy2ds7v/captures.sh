#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l3.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l3.txt; done
#
# Needs lesson 1's captures to have run (Node in ana's home). The programs are
# taken out of the lesson's .md by lab/shown.py; the small files the lesson
# makes with echo and mkdir are made by those same typed lines.
#
# STAGED: the three package.json files of "how Node decides" (the lesson says
# what each holds and shows them with cat), and the files of the package tidy,
# whose package.json the lesson shows whole and whose three one-line files the
# typed lines write.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
M='~/server/modules'
quiet '~/server' 'rm -rf modules && mkdir -p modules/none modules/typeless modules/typed modules/pkg modules/paths modules/cache modules/esm modules/mix'
for d in none typeless typed; do shown how-node-decides.md hello.js $M/$d/hello.js; done
quiet $M "echo '{ \"name\": \"typeless\" }' > typeless/package.json; echo '{ \"name\": \"typed\", \"type\": \"module\" }' > typed/package.json"
shown how-node-decides.md old.js $M/typed/old.js
shown the-wrapper.md trap.js $M/trap.js
shown the-wrapper.md where.mjs $M/where.mjs
for f in counter.js main.js a.js b.js; do shown the-cache.md $f $M/cache/$f; done
shown esm-in-node.md start.mjs $M/esm/start.mjs
shown esm-in-node.md menu.mjs $M/esm/menu.mjs
for f in slug.cjs slug.mjs use-cjs.mjs use-esm.cjs later.mjs; do shown mixing-them.md $f $M/mix/$f; done

block decides
session $M 'cat typeless/package.json typed/package.json' 'cd none && node hello.js' \
  'cd ../typeless && node hello.js' 'cd ../typed && node hello.js'
block old
session $M/typed 'node old.js'

block tidy
session $M/pkg 'mkdir -p node_modules/tidy/dist node_modules/tidy/src'
python3 - <<'PY' > /tmp/nodelab/tidy.json
import re
t = open("package-exports.md").read()
print(re.findall(r"```json\n(.*?)```", t, re.S)[0], end="")
PY
bash "$LAB_SH" script "cat > ~/server/modules/pkg/node_modules/tidy/package.json" < /tmp/nodelab/tidy.json
block tidy-use
session $M/pkg \
  "echo 'exports.kind = \"CommonJS build\";' > node_modules/tidy/dist/tidy.cjs" \
  "echo 'export const kind = \"ES module build\";' > node_modules/tidy/dist/tidy.mjs" \
  "echo 'export const words = (s) => s.split(/\\s+/).length;' > node_modules/tidy/dist/words.mjs" \
  "echo 'module.exports = \"private\";' > node_modules/tidy/src/internal.js" \
  "node -p 'require(\"tidy\").kind'" \
  "node --input-type=module -e 'import { kind } from \"tidy\"; console.log(kind)'" \
  "node --input-type=module -e 'import { words } from \"tidy/words\"; console.log(words(\"three words here\"))'" \
  "node -p 'require(\"tidy/src/internal.js\")' 2>&1 | grep -E '^Error|code:'"
block paths-list
session $M/pkg 'node -p module.paths'
block resolve
session $M/pkg "node -p 'require.resolve(\"tidy\")'"

block paths
session $M/paths "mkdir lib && echo 'module.exports = \"lib/index.js\";' > lib/index.js" \
  "node -e 'console.log(require(\"./lib\"))'" \
  "echo 'import x from \"./lib/index\"; console.log(x);' > no-extension.mjs" \
  'node no-extension.mjs 2>&1 | grep -E "^Error"' \
  "echo 'import x from \"./lib\"; console.log(x);' > folder.mjs" \
  'node folder.mjs 2>&1 | grep -A1 -E "^Error"'

block wrapper
session $M "node -p 'require(\"node:module\").wrapper'"
block trap
session $M "node -p 'require(\"./trap.js\")'"
block where
session '~/server' 'node modules/where.mjs'

block cache
session $M/cache 'node main.js'
block cycle
session $M/cache 'node a.js'

block start-missing
session $M/esm 'node start.mjs'
block tla
shown esm-in-node.md prices.mjs $M/esm/prices.mjs
session $M/esm "echo '{\"tea\": 4.5, \"cake\": 7}' > prices.json" 'node start.mjs'
block json
session $M/esm 'node menu.mjs' "sed 's/ with { type: \"json\" }//' menu.mjs > bare.mjs" \
  'node bare.mjs 2>&1 | grep -E "^TypeError"'

block use-cjs
session $M/mix 'node use-cjs.mjs'
block use-esm
session $M/mix 'node use-esm.cjs'
block later
session $M/mix "node -e 'require(\"./later.mjs\")' 2>&1 | grep -E '^Error'"

block builtins
session $M "node -p 'require(\"node:module\").builtinModules.length'"
block node-test
session $M "node -e 'require(\"node:test\"); console.log(\"node:test loads\")'" \
  "node -e 'require(\"test\")' 2>&1 | grep -E '^Error'"
