#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# OpenSSL 3.0.13 from Ubuntu 24.04's own archive, already on the machine.
# The keys are generated fresh on every run, so no key in this lesson is
# anybody's: the transcripts print subjects, dates and verdicts, never a
# key's bytes. The "Toy" certificate authority is made by the lesson itself
# to show how a chain is checked; it is not Apple's, and the lesson says so.
#
# The other two files run here, Planner.entitlements and allowed.plist, are
# lifted out of entitlements.md. allowed.plist is written by the lesson as an
# example of what a profile allows, not taken from a real profile.
#
# Nothing from Xcode, Keychain Access, the developer website or App Store
# Connect was run. The dates in the transcripts are the day of recording.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh signing
block request
run 'openssl genrsa -out dev.key 2048'
run 'openssl req -new -key dev.key -out dev.certSigningRequest -subj "/emailAddress=ana@example.com/CN=Ana Dev Key/C=BR"'
run 'openssl req -in dev.certSigningRequest -noout -verify -subject'
run 'openssl req -in dev.certSigningRequest -noout -text | grep -E "Public-Key|Signature Algorithm" | sort -u'
run 'ls -l'

block chain
run 'openssl req -x509 -newkey rsa:2048 -nodes -keyout root.key -out root.pem -days 3650 -subj "/CN=Toy Root CA" 2>/dev/null'
run 'openssl req -newkey rsa:2048 -nodes -keyout inter.key -out inter.csr -subj "/CN=Toy Intermediate CA" 2>/dev/null'
run 'printf "basicConstraints=critical,CA:TRUE\n" > ca.ext'
run 'openssl x509 -req -in inter.csr -CA root.pem -CAkey root.key -extfile ca.ext -days 1825 -out inter.pem'
run 'openssl x509 -req -in dev.certSigningRequest -CA inter.pem -CAkey inter.key -days 365 -out dev.pem'
run 'openssl x509 -in dev.pem -noout -subject -issuer -enddate'

block verify
run 'openssl verify -CAfile root.pem -untrusted inter.pem dev.pem'
run 'openssl verify -CAfile root.pem dev.pem'

fresh entitlements
put "$HERE/entitlements.md" Planner.entitlements
put "$HERE/entitlements.md" allowed.plist
put "$HERE/entitlements.md" check-entitlements.swift
block entitlements
run 'swift check-entitlements.swift Planner.entitlements allowed.plist; echo $?'
run "sed 's|<key>aps-environment</key>|<key>com.apple.developer.healthkit</key><true/><key>aps-environment</key>|' Planner.entitlements > More.entitlements"
run 'swift check-entitlements.swift More.entitlements allowed.plist; echo $?'
