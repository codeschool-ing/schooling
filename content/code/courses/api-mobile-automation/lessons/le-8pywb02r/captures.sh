#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of api-mobile-automation, as the
# script that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT RAN AND WHAT COULD NOT. The two scripts of the lesson ran, on the
# project as lessons 1 to 20 leave it: matrix/coverage.mjs over the invented
# analytics export matrix/sessions.csv, once per column, and
# matrix/pairwise.mjs. No device cloud was used: each needs an account, so
# the Appium session against a cloud's server and the Firebase Test Lab
# commands of section `running-remotely` were not run, and the lesson says
# so. Nothing is STAGED: no server is started and no network is used.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0,
# TZ=America/Sao_Paulo, as user ana.

source "$(dirname "$0")/../../lab.sh"
project 20 /home/ana/boxoffice
here /home/ana/boxoffice

block android
run 'node matrix/coverage.mjs android'

block maker
run 'node matrix/coverage.mjs maker'

block model
run 'node matrix/coverage.mjs model'

block pairwise
run 'node matrix/pairwise.mjs'
