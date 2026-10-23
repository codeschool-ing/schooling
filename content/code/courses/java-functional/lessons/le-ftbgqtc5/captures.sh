#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of java-functional, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program it
# runs is taken out of the lesson's own English .md, so the file the student
# copies is the file that ran.
#
#   sudo bash ../../lab.sh setup      # once: OpenJDK 25, Maven and ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana saved, written by src, and
# STOREPASS, which the lesson has the student type with read -rs; here it is
# set in the environment of each command that uses it. The keys, IVs and
# fingerprints are new on every run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

# onp CMD: as on, with STOREPASS in the environment, as the student set it
onp() { printf 'ana@vm:~/%s$ %s\n' "$DIR" "$*"; lab exec "$DIR" "export STOREPASS=lab-only-password; timeout 300 bash -c $(printf '%q' "$*") 2>&1 < /dev/null" || true; }

at fp/crypto

block fingerprint
src Fingerprint.java digests.md
on 'java Fingerprint.java'
on "printf 'Dune by Frank Herbert' | sha256sum"

block seal
src Seal.java symmetric-encryption.md
on 'java Seal.java'

block sign
src Sign.java signatures.md
on 'java Sign.java'

block keytool
onp 'keytool -genkeypair -alias library -keyalg Ed25519 -dname "CN=library.example" -validity 365 -keystore library.p12 -storetype PKCS12 -storepass:env STOREPASS'
onp 'keytool -list -keystore library.p12 -storepass:env STOREPASS'

block store
src Store.java keystores.md
onp 'java Store.java'
on 'STOREPASS=wrong java Store.java 2>&1 | head -2'
