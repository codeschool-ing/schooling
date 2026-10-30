#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 23's captures left, and saves what it
# leaves for lesson 25.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one lesson, the course
# page's spec, is taken from the section that shows it). No server runs: every
# test in this lesson answers its own requests.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-haskz2jx
T="npx ng test --watch=false 2>&1"

# the-runner
cap '~/planner' "$T | tail -14"
cap '~/planner' 'cat src/app/minutes-pipe.spec.ts'

# pure-functions
save pure-functions src/app/planner.spec.ts
cap '~/planner' "$T | grep -E '✓|Tests '"
cap '~/planner' "sed -i 's/(date.getDay() + 6) % 7/date.getDay()/' src/app/planner.ts"
cap '~/planner' "$T | grep -E '✓|❯|×|Tests '"
cap '~/planner' 'git checkout -- src/app/planner.ts'

# a-fake-server
save a-fake-server src/app/planner-store.spec.ts
cap '~/planner' "$T | grep -E '✓.*planner-store|Tests '"
cap '~/planner' "sed -i 's|^    TestBed.tick();|    // TestBed.tick();|' src/app/planner-store.spec.ts"
cap '~/planner' "$T | grep -E 'FAIL|Error|Tests '"
cap '~/planner' "sed -i 's|^    // TestBed.tick();|    TestBed.tick();|' src/app/planner-store.spec.ts"

# components
save components src/app/course-sessions/course-sessions.spec.ts
cap '~/planner' "$T | grep -E '✓.*course-sessions|Tests '"
save components src/app/week-summary/week-summary.spec.ts
cap '~/planner' "$T | grep -E '✓.*week-summary|Tests '"

# harnesses
save harnesses src/app/course-sessions/course-sessions.spec.ts
cap '~/planner' "$T | grep -E '✓.*course-sessions|Tests '"

# from-karma
save from-karma src/app/minutes-pipe.jasmine.spec.ts
cap '~/planner' "$T | grep -A4 ERROR"
cap '~/planner' 'npx ng generate @schematics/angular:refactor-jasmine-vitest --include src/app/minutes-pipe.jasmine.spec.ts'
cap '~/planner' 'cat src/app/minutes-pipe.jasmine.spec.ts'
cap '~/planner' "$T | grep -E '✓.*jasmine|Tests '"
cap '~/planner' 'rm src/app/minutes-pipe.jasmine.spec.ts jasmine-vitest-*.md'

# what-goes-where
cap '~/planner' "npx ng test --watch=false --coverage 2>&1 | tail -3"
cap '~/planner' 'git add -A && git commit -q -m "Tests: the arithmetic, the store against a fake server, a component and a harness"'

snapshot le-ydq5jhh3
