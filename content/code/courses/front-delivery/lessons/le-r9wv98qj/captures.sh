#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l7.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l7.txt; done
#
# It runs on the planner as lesson 6 left it, the commit tagged lesson-6, and
# tags what it leaves lesson-7. It starts from no library, no registry and no
# registry login. STAGED: the password typed at `npm adduser` is a made-up one
# for a registry that only listens on this computer; it is typed through a
# pseudo-terminal by lab/lib.sh's `tty`, so it is not echoed, as it would not
# be for a person.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
quiet '~' 'rm -rf ~/planner-ui ~/registry; sed -i "/4873/d" ~/.npmrc'
quiet '~/planner' 'git switch -q main; git reset -q --hard lesson-6 && git clean -fdq && npm ci'

# The library.
block lib
session '~' 'mkdir -p ~/planner-ui/src && cd ~/planner-ui' \
  'cp ../planner/tokens.json ../planner/tokens.mjs ../planner/contrast.mjs .' \
  'cp ../planner/src/components.ts ../planner/src/format.ts src/' 'git init -q' \
  'find . -path ./.git -prune -o -type f -print | sort'
shown the-library.md src/types.ts '~/planner-ui/src/types.ts'
shown the-library.md src/index.ts '~/planner-ui/src/index.ts'
block retarget
session '~/planner-ui' "sed -i 's#\"./planner\"#\"./types\"#' src/components.ts" 'grep -n import src/components.ts'

shown package-json.md package.json '~/planner-ui/package.json'
shown building-the-library.md vite.config.ts '~/planner-ui/vite.config.ts'
shown building-the-library.md tsconfig.json '~/planner-ui/tsconfig.json'
block build
session '~/planner-ui' 'npm install --save-dev --save-exact vite@8.3.5 typescript@6.0.3 2>&1 | tail -1' \
  'npm run build > /dev/null && find dist -type f | sort'
block pack
session '~/planner-ui' "npm pack --dry-run 2>&1 | grep -E 'notice [0-9.]+k?B|total files'"
block ignore
session '~/planner-ui' "printf 'node_modules\ndist\n*.tgz\n' > .gitignore"

# The registry.
quiet '~' 'mkdir -p ~/registry'
shown a-registry-of-your-own.md '~/registry/config.yaml' '~/registry/config.yaml'
bg reg '~/registry' 'npx -y verdaccio@6.10.7 --config ./config.yaml'
for _ in $(seq 90); do curl -s http://127.0.0.1:4873/-/ping >/dev/null && break; sleep 1; done
block reg-start
bg_show reg
block adduser
tty '~/planner-ui' 'npm adduser --registry http://127.0.0.1:4873/ --auth-type=legacy' ana lab-password-1 ana@example.org

# Publishing.
block npmrc
session '~/planner-ui' "echo '@planner:registry=http://127.0.0.1:4873/' > .npmrc"
block publish
session '~/planner-ui' 'npm run build > /dev/null' 'npm publish 2>&1 | tail -1' 'npm view @planner/ui versions' \
  "npm publish 2>&1 | grep -m1 'npm error'"
block lib-commit
session '~/planner-ui' 'git add . && git commit -qm "The planner'"'"'s UI library, 0.1.0"'

# The planner as a consumer.
block consume
session '~/planner' 'cp ../planner-ui/.npmrc .' 'npm install --save-exact @planner/ui@0.1.0 2>&1 | tail -1' \
  "grep -A1 '\"dependencies\"' package.json"
block switch
session '~/planner' "sed -i 's#\"./components\"#\"@planner/ui\"#' src/view.ts src/session-row.stories.ts src/week-summary.stories.ts" \
  "sed -i 's#@import \"./tokens.css\";#@import \"@planner/ui/tokens.css\";#' src/style.css" \
  'grep -n "@planner/ui" src/*.ts src/style.css'
block remove
session '~/planner' 'git rm -q src/components.ts src/format.ts src/tokens.css tokens.json tokens.mjs contrast.mjs' \
  'npm pkg delete scripts.tokens scripts.contrast'
block checks
session '~/planner' 'npx tsc && npm test 2>&1 | grep Tests' 'npm run build 2>&1 | grep css' \
  'npm run build-storybook > /dev/null 2>&1' 'npx playwright test 2>&1 | tail -1'
block consume-commit
session '~/planner' 'git add -A && git commit -qm "Use @planner/ui 0.1.0 instead of local copies"'

# A second release.
shown a-second-release.md src/components.ts '/tmp/fdlab/progress.ts'
quiet '~/planner-ui' 'cat /tmp/fdlab/progress.ts >> src/components.ts'
block export
session '~/planner-ui' "sed -i 's/export { actionButton, sessionRow, weekSummary }/export { actionButton, progressBar, sessionRow, weekSummary }/' src/index.ts" \
  'npx tsc && echo types ok'
shown a-second-release.md CHANGELOG.md '~/planner-ui/CHANGELOG.md'
block release
session '~/planner-ui' 'git add -A && git commit -qm "Add progressBar"' 'npm version minor' 'git log --oneline --decorate -2' \
  'npm run build > /dev/null && npm publish 2>&1 | tail -1'
block outdated
session '~/planner' 'npm outdated @planner/ui; echo $?'
block upgrade
session '~/planner' 'npm install --save-exact @planner/ui@0.2.0 2>&1 | tail -1' \
  'git commit -qam "@planner/ui 0.2.0"' 'git log --oneline -1'
quiet '~/planner' 'npm run build'
quiet '~/planner' 'git tag -f lesson-7'
bg_stop reg INT
