#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l5.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l5.txt; done
#
# It runs on the planner as lesson 4 left it, the commit tagged lesson-4, and
# tags what it leaves lesson-5. STAGED: nothing beyond the files shown.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
quiet '~/planner' 'git switch -q main; git reset -q --hard lesson-4 && git clean -fdq'

shown tokens-as-data.md tokens.json '~/planner/tokens.json'
shown tokens-as-data.md tokens.mjs '~/planner/tokens.mjs'
block tokens
session '~/planner' 'npm pkg set scripts.tokens="node tokens.mjs"' 'npm run tokens' "sed -n '1,14p' src/tokens.css"
block scale
session '~/planner' 'grep font-size src/tokens.css'
block space
session '~/planner' 'grep space src/tokens.css'

shown colour-and-contrast.md contrast.mjs '~/planner/contrast.mjs'
block contrast
session '~/planner' 'npm pkg set scripts.contrast="node contrast.mjs"' 'npm run contrast'
block light-fails
session '~/planner' "sed -i 's/{color.grey-600}/{color.grey-400}/' tokens.json" 'node contrast.mjs' \
  "sed -i 's/{color.grey-400}/{color.grey-600}/' tokens.json"
block dark-fails
session '~/planner' "sed -i 's/{color.grey-300}/{color.grey-400}/' tokens.json" 'node contrast.mjs | grep FAIL' \
  "sed -i 's/{color.grey-400}/{color.grey-300}/' tokens.json"

block themes
session '~/planner' "sed -n '/^:root,/,\$p' src/tokens.css"

shown the-planner-in-tokens.md src/style.css '~/planner/src/style.css'
block grep
session '~/planner' "grep -nE '#[0-9a-fA-F]{3,6}|[0-9]px' src/style.css; echo \$?"
block build
session '~/planner' 'npm run build 2>&1 | grep css' 'npm run contrast > /dev/null && echo contrast ok' \
  'git add tokens.json tokens.mjs contrast.mjs src/tokens.css src/style.css package.json' \
  'git commit -qm "Tokens, a type and spacing scale, two themes"'
quiet '~/planner' 'git tag -f lesson-5'
