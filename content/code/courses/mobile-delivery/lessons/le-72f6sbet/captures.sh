#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of mobile-delivery, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. make-listing.sh,
# blank.ts and listing.ts are taken from the lesson by lab/extract.py, so the
# files each transcript ran are the ones it prints. Nothing is staged beyond
# lab.sh.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
LAB as 'rm -rf ~/planner/listing'

block make
put the-listing-as-files.md make-listing.sh $P/make-listing.sh
run $P 'bash make-listing.sh'
run $P 'find listing -type f | sort'

block shots
put the-listing-as-files.md blank.ts $P/blank.ts
run $P 'node blank.ts listing/ios/en-US/screenshots/1-week.png 1320 2868'
run $P 'node blank.ts listing/ios/pt-BR/screenshots/1-week.png 1170 2532'
run $P 'node blank.ts listing/android/en-US/screenshots/1-week.png 1080 1920'
run $P 'node blank.ts listing/android/pt-BR/screenshots/1-week.png 1080 2400'

block check
put the-listing-as-files.md listing.ts $P/listing.ts
run $P 'node listing.ts; echo "exit status $?"'
