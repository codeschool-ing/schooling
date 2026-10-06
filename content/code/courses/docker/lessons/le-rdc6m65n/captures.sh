#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: the four images below are pulled before the first
# command, so no transcript here is a download. Lesson 9 shows a pull. The
# database password is a lab value and protects nothing.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="golang:1.25 postgres:16 postgres:17 alpine:3.22"
. "$(dirname "$0")/../../capture.sh"

block no-go
run 'env go version'
block go-in-a-container
run 'docker run --rm golang:1.25 go version'
block two-postgres
run 'docker run --rm postgres:16 postgres --version'
run 'docker run --rm postgres:17 postgres --version'

block start-db
run 'docker run -d --name db -e POSTGRES_PASSWORD=lab-only postgres:17'
quiet 'sleep 4'
block ps
run 'docker ps'
block host-ps
run 'ps -o pid,ppid,uid,cmd -C postgres'
block docker-top
run 'docker top db -o pid,ppid,uid,args'
run 'docker exec db id postgres'
block inside-pid
run 'docker exec db cat /proc/1/status | grep -E "^(Name|Pid|PPid):"'

block images
run 'docker image ls'
block two-containers
run 'docker run -d --name one alpine:3.22 sleep 600'
run 'docker run -d --name two alpine:3.22 sleep 600'
run 'docker exec one sh -c "echo from one > /note"'
run 'docker exec one cat /note'
run 'docker exec two cat /note'
block ps-all
run 'docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
block rm-keeps-image
run 'docker rm -f one two db'
run 'docker image ls alpine'
