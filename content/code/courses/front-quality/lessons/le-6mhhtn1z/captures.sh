#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of front-quality, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash ../../lab.sh capture 1 > out.txt
#
# It starts from no ~/planner at all, and leaves the tag lesson-1 for lesson 2.
# Every file the lesson shows is taken from the lesson's own listings by
# lab/extract.py, so the file in the lesson is the file that ran.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "dev" is the log of `npm run dev`, started in the background by serve()
#     and printed once Vite answered; "curl" ran meanwhile, as from a second
#     terminal. "port-taken" is the log of a second `npm run dev` started the
#     same way while the first still held port 5173.
#   - "old-node" ran with Node.js 18.19.1, the version Ubuntu 24.04's own
#     nodejs package carries, unpacked from nodejs.org's tarball into
#     /var/tmp/front-quality-node18 and put first on the PATH for that one
#     command, as `sudo apt install nodejs` would have put it.
#   - "types" edits src/view.ts with an exact replacement, records what tsc
#     said, and puts the file back with `git checkout`, which is shown.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"

rm -rf "$P"

block versions
run ~ 'node --version'
run ~ 'npm --version'
run ~ 'git --version'

block create
run ~ 'npm create vite@9.3.1 planner -- --template vanilla-ts --no-interactive'
block template
run ~ 'cd planner'
run $P 'ls -A . src public'
block clear
run $P 'rm -r src/counter.ts src/assets public/favicon.svg public/icons.svg'

put the-planner.md public/courses.json $P/public/courses.json
put the-planner.md src/planner.ts $P/src/planner.ts
block install
run $P 'npm install --save-exact vite@8.3.5 typescript@6.0.3'
run $P 'cat package.json'

put the-page.md index.html $P/index.html
put the-page.md public/book.svg $P/public/book.svg
put the-page.md src/style.css $P/src/style.css
put the-page.md src/view.ts $P/src/view.ts
put the-page.md src/main.ts $P/src/main.ts

block tsc
run $P 'npx tsc --noEmit'

serve 5173 $P 'npm run dev'
block dev
printf 'ana@dev:~/planner$ npm run dev\n'
cat /var/tmp/front-quality-server-5173.log
block curl
run $P 'curl -s http://localhost:5173/courses.json | head -n 4'
run $P 'curl -s http://localhost:5173/src/planner.ts | head -n 3'

block port-taken
serve 5174 $P 'npm run dev'
printf 'ana@dev:~/planner$ npm run dev\n'
cat /var/tmp/front-quality-server-5174.log
unserve 5174
unserve 5173

block commit
export GIT_AUTHOR_DATE='2026-10-19 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-19 09:00:00 -0300'
run $P 'git init'
run $P 'git add -A'
run $P 'git commit -q -m "The study planner"'
run $P 'git log --oneline'

# The failures of when-setup-fails.
block no-package
run ~ 'npm run dev'
block no-modules
run $P 'rm -rf node_modules'
run $P 'npm run dev'
run $P 'npm ci'
block old-node
N18=/var/tmp/front-quality-node18
if [ ! -x $N18/bin/node ]; then
  mkdir -p $N18
  curl -fsSL https://nodejs.org/dist/v18.19.1/node-v18.19.1-linux-x64.tar.xz | tar -xJ -C $N18 --strip-components=1
fi
printf 'ana@dev:~/planner$ node --version\n'; ( cd $P && PATH=$N18/bin:$PATH node --version )
printf 'ana@dev:~/planner$ npm run dev\n'; ( cd $P && PATH=$N18/bin:$PATH npm run dev ) 2>&1

block types
fix src/view.ts 'Number(data.get("minutes"))' 'data.get("minutes")'
run $P 'npx tsc --noEmit'
run $P 'git checkout src/view.ts'
run $P 'npx tsc --noEmit'

leave 1
