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
# alpine:3.22 is pulled before the first command, for the two failures the
# last section shows. The TLS one is this machine's own: its traffic leaves
# through a proxy that re-signs TLS, which a container does not trust, and
# that is exactly what a student on a company or school network meets.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="alpine:3.22"
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

block tools
run 'jq --version && psql --version && git --version'
run 'id -nG'
block tls
run 'docker run --rm alpine:3.22 wget -q -O /dev/null https://dl-cdn.alpinelinux.org/alpine/'
block port
quiet 'docker container prune -f'
run 'docker run -d --name one -p 127.0.0.1:8080:8080 alpine:3.22 sleep 600'
run 'docker run -d --name two -p 127.0.0.1:8080:8080 alpine:3.22 sleep 600'
run 'docker ps -a --format "{{.Names}}  {{.Status}}  {{.Ports}}"'
run 'docker rm -f one two'
