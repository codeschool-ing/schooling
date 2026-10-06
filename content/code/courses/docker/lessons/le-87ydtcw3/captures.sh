#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the images below are pulled before the first
# command. The arm64 variant of alpine is not; the command that asks for it
# fetches it, and with the containerd image store it says nothing while doing
# so. The `exec format error` is the proof it tried an arm64 binary. The lab
# machine is itself a virtual machine with no hypervisor available inside it,
# so no transcript here starts one; the lesson says so where it matters.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="alpine:3.22 debian:trixie-slim"
. "$(dirname "$0")/../../capture.sh"

block kernels
run 'uname -r'
run 'docker run --rm alpine:3.22 uname -r'
run 'docker run --rm debian:trixie-slim uname -r'
block distros
run 'grep PRETTY_NAME /etc/os-release'
run 'docker run --rm alpine:3.22 grep PRETTY_NAME /etc/os-release'
run 'docker run --rm debian:trixie-slim grep PRETTY_NAME /etc/os-release'
block start-time
run 'time docker run --rm alpine:3.22 true'
block idle
run 'docker run -d --name idle alpine:3.22 sleep 600'
run 'docker stats --no-stream idle'
block free
run 'free -m'
run 'docker run --rm --memory 256m alpine:3.22 free -m'
block nproc
run 'nproc'
run 'docker run --rm --cpus 1 alpine:3.22 nproc'
block arch
run 'docker info --format "{{.OSType}}/{{.Architecture}}"'
run 'docker run --rm --platform linux/arm64 alpine:3.22 uname -m'
