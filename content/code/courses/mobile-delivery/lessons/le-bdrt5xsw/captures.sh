#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of mobile-delivery, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine, with Ubuntu's ruby-full, ruby-bundler and
# build-essential, and ~/planner as lessons 1 to 6 leave it: preflight.ts
# still stops on the listing and the certificate. Gemfile and Fastfile are
# taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The five FASTLANE_* variables of section "Installing it" are exported by
#     RUNENV, as the lesson tells the student to put them in ~/.profile.
#   - bundle install runs quietly: its output is a hundred gem names.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
RUNENV='export FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_HIDE_TIMESTAMP=1 FASTLANE_DISABLE_COLORS=1 FASTLANE_DISABLE_OUTPUT_FORMAT=1 FASTLANE_OPT_OUT_USAGE=1'
LAB as 'rm -rf ~/planner/fastlane ~/planner/Gemfile ~/planner/Gemfile.lock ~/planner/.bundle'

put installing-it.md Gemfile $P/Gemfile
quiet $P 'bundle config set --local path vendor/bundle && bundle install --quiet'

block version
run $P 'bundle exec fastlane --version'

block lanes
put the-first-lanes.md Fastfile $P/fastlane/Fastfile
run $P 'bundle exec fastlane lanes'

block checks
run $P "bundle exec fastlane checks 2>&1 | sed -n '/Step: cd/,/reason(s)/p'; echo \"exit status \${PIPESTATUS[0]}\""
