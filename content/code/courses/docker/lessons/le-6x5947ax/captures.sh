#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# This lesson is about Docker Desktop, and nothing here runs it: the lab is a
# Linux server with Docker Engine, and Docker Desktop is a desktop
# application for Windows, macOS and Linux workstations. What IS captured are
# the checks the lesson asks a student to run after installing, which print
# the same kind of answer on either; the lesson says which lines differ and
# shows no Desktop output it did not record.
#
# hello-world is NOT pulled beforehand, so its download is in the transcript.
# The broken DOCKER_HOST is deliberate: it is the error a student sees when
# Docker Desktop is installed and not running.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES=""
. "$(dirname "$0")/../../capture.sh"

block version
run 'docker version'
block hello
run 'docker run hello-world'
block context
run 'docker context ls'
block info
run 'docker info --format "{{.OperatingSystem}} | {{.OSType}}/{{.Architecture}} | {{.NCPU}} CPUs | {{.MemTotal}} bytes"'
block no-daemon
run 'DOCKER_HOST=unix:///run/not-running.sock docker ps'
