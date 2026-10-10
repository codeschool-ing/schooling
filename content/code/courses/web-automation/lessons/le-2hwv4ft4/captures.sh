#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `installing`, `a-first-spec`,
# `intercept` and `limits` show every file this lesson adds whole, and
# ../../lab.sh builds the project from those very blocks, so the two cannot
# differ.
#
# CYPRESS ITSELF WAS NOT RUN. Its binary is a separate download from
# download.cypress.io, which this machine cannot reach, so npm installs the
# package with CYPRESS_INSTALL_BINARY=0 (../../lab.sh does that for every
# install, and "npm-install" prints the variable on the command line because it
# was really set). Every block below that names Cypress shows the package
# without its binary: its version, `verify`, `run` and `install` failing, and
# its help text, which needs no binary. The spec files were type-checked
# against node_modules/cypress/types (TypeScript 5.6.3, checkJs, outside the
# project) and never executed. What is STAGED rather than typed:
#   - ~/.cache/Cypress removed first, so the machine is one where the binary
#     was never downloaded;
#   - in "cypress-install-fails", CI=1 on the command line, which makes the
#     installer print plain lines instead of a spinner drawn with characters
#     the lesson's font does not have; the download fails because ana's shell
#     has no network at all, which is the honest form of "cannot reach it".
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0, Chromium 141.0.7390.37 and the cypress package 16.1.1,
# TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 9 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
rm -rf "$ANA_HOME/.cache/Cypress"

block npm-install
rm -rf node_modules package-lock.json
printf 'ana@laptop:~/quitanda$ CYPRESS_INSTALL_BINARY=0 npm install\n'
npm_in "$P" install 2>&1

block cypress-version
run 'npx cypress --version'

block cypress-verify
run 'npx cypress verify'

block cypress-install-fails
run 'CI=1 npx cypress install'

block cypress-run-missing
run 'npx cypress run --spec cypress/e2e/shop.cy.js'

block run-help
run "npx cypress run --help | grep -E -- '--(browser|parallel|record) '"
run "grep '\"license\"' node_modules/cypress/package.json"

block origins
start_app
run 'node origins.mjs'
stop_app
rm -rf "$ANA_HOME/.cache/Cypress"
