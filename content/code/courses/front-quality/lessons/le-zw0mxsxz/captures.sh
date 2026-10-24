#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 2 > out.txt
#
# It starts from the tag lesson-1 and leaves lesson-2. Every test file is
# taken from the lesson's own listings by lab/extract.py; the fix to weekOf is
# the change the-time-zone shows, applied by an exact replacement, and
# `git diff` prints it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner-jest is made fresh each time, and its two copied files are
#     the planner's own, copied with the `cp` the lesson shows.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 1
J=/home/ana/planner-jest
rm -rf $J

block install
run $P 'npm install --save-exact -D vitest@5.0.5'
block script
run $P 'npm pkg set scripts.test="vitest run"'
run $P 'npm pkg get scripts'
block none
run $P 'npm test; echo "exit code $?"'

put first-test.md src/planner.test.ts $P/src/planner.test.ts
block red
run $P 'npm test'

block utc
run $P 'TZ=UTC npm test'

fix src/planner.ts '  const d = new Date(day);
  const monday = new Date(d);
  monday.setDate(d.getDate() - ((d.getDay() + 6) % 7));
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);' '  const d = new Date(`${day}T00:00:00Z`);
  const monday = new Date(d);
  monday.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  const sunday = new Date(monday);
  sunday.setUTCDate(monday.getUTCDate() + 6);'
block diff
run $P 'git diff src/planner.ts'
block zones
run $P 'for tz in Asia/Tokyo America/Sao_Paulo Pacific/Honolulu; do echo "== $tz"; TZ=$tz npx vitest run | grep Tests; done'
block commit
export GIT_AUTHOR_DATE='2026-10-19 10:00:00 -0300' GIT_COMMITTER_DATE='2026-10-19 10:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "Test the week, and compute it in UTC"'

python3 "$FQ_LAB/extract.py" "$LESSON/more-cases.md" "src/planner.test.ts, below what is there" | sed 1d | sed '1s/^/\n/' >> $P/src/planner.test.ts
block more
run $P 'npx vitest run src/planner.test.ts'

block jsdom
run $P 'npm install --save-exact -D jsdom@29.1.1'
put components.md src/view.test.ts $P/src/view.test.ts
block components
run $P 'npx vitest run src/view.test.ts'

put mocks-and-time.md src/today.test.ts $P/src/today.test.ts
block time
run $P 'npx vitest run src/today.test.ts'

block typecheck
run $P 'npx tsc --noEmit'

block jest-setup
run ~ 'mkdir planner-jest'
run ~ 'cd planner-jest'
run $J 'npm init -y > /dev/null'
run $J 'npm pkg set type=module'
run $J 'npm install --save-exact -D jest@30.5.2 @jest/globals@30.5.2 ts-jest@29.4.15 typescript@6.0.3'
run $J 'cp ../planner/src/planner.ts ../planner/public/courses.json .'
put jest.md planner.test.ts $J/planner.test.ts
put jest.md jest.config.js $J/jest.config.js
block jest-red
run $J 'npx jest'
put jest.md tsconfig.json $J/tsconfig.json
block jest-green
run $J 'npx jest'

block coverage-install
run $P 'npm install --save-exact -D @vitest/coverage-v8@5.0.5'
block coverage
run $P 'npx vitest run --coverage'
block ignore
run $P 'echo coverage >> .gitignore'
run $P 'git add -A'
run $P 'git commit -q -m "Unit and component tests with Vitest"'
run $P 'git log --oneline'
leave 2
