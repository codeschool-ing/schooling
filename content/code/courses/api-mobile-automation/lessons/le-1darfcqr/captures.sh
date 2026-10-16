#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of api-mobile-automation, as the
# script that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT RAN AND WHAT COULD NOT. A React Native app is built by Gradle with
# libraries from Google's Maven repository, which this sandbox cannot reach,
# and run on an emulator, which cannot start here (lesson 14). So the app was
# never built or run, and Detox never drove it. What is recorded, all of it
# real:
#   - the React Native project, created from npm with the command the lesson
#     shows, and what it contains;
#   - the lesson's App.tsx type-checked by the project's own TypeScript;
#   - Detox installed from npm, its version, `detox init` and the files it
#     wrote, and its Android library inside the package;
#   - `detox test` with the lesson's configuration on this machine, where no
#     emulator exists: the refusal it gives.
# What is STAGED rather than typed:
#   - the project command's own output. Its progress lines are drawn with
#     symbols the course's font has no glyph for, so it runs quietly here and
#     the lesson shows the command and then what it made;
#   - the files the lesson saves in tickets-rn (App.tsx, .detoxrc.js and
#     e2e/tickets.test.js). ../../lab.sh writes them from the lesson before
#     anything runs, and the project command refuses a folder that is not
#     empty, so they are moved aside and put back at the point the lesson
#     saves each one;
#   - the network once more: the project command asks the npm registry with
#     Node's own fetch, which ignores HTTPS_PROXY unless NODE_USE_ENV_PROXY=1
#     says otherwise, so that variable is set for that one command. A student's
#     machine has no proxy and needs nothing;
#   - adb's server, which Detox starts while it looks for the emulator, is
#     stopped at the end, as lesson 14's captures do.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# @react-native-community/cli 20.2.0, React Native 0.86.3, Detox 20.51.4 and
# platform-tools 36.0.0, TZ=America/Sao_Paulo, as user ana.

source "$(dirname "$0")/../../lab.sh"
project 17 /home/ana/boxoffice
here /home/ana/boxoffice
quiet 'adb kill-server'

SAVED=/tmp/lab-rn-saved
rm -rf "$SAVED"; mv /home/ana/boxoffice/tickets-rn "$SAVED"
put() { cp "$SAVED/$1" "/home/ana/boxoffice/tickets-rn/$1"; chown ana:ana "/home/ana/boxoffice/tickets-rn/$1"; }

LAB_EXTRA=NODE_USE_ENV_PROXY=1 quiet 'npx --yes @react-native-community/cli@20.2.0 init TicketsRN --version 0.86.3 --directory tickets-rn --pm npm --skip-git-init'
[ -f /home/ana/boxoffice/tickets-rn/package.json ] || { echo "captures: the project was not created" >&2; exit 1; }

block rn-files
run 'ls tickets-rn'
run 'ls tickets-rn/android/app/src/main/java/com/ticketsrn'

put App.tsx
block tsc
go tickets-rn
run 'npx tsc --noEmit; echo "exit $?"'

block detox-install
run 'npm install --save-dev --save-exact detox@20.51.4'

block detox-version
run 'npx detox --version'

block detox-init
run 'npx detox init'

block detox-android
run 'ls node_modules/detox/Detox-android'

put .detoxrc.js
mkdir -p /home/ana/boxoffice/tickets-rn/e2e; put e2e/tickets.test.js
block starter
run 'rm e2e/starter.test.js'
run 'ls e2e'

block detox-test
run 'npx detox test -c android.emu.debug'

quiet 'adb kill-server'
rm -rf "$SAVED"
