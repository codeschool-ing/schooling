#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# The lab machine already had Docker Engine installed from Docker's own apt
# repository; the transcripts read that installation rather than repeat it,
# and the lesson marks the install commands as not run here. The machine does
# not boot with systemd, so dockerd is started by lab.sh, its log is a file
# rather than the journal, and `systemctl` says so in a transcript. bruno is a
# second account lab.sh creates outside the docker group, and /srv/payroll is
# a root-only directory lab.sh fills with made-up figures.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="alpine:3.22"
. "$(dirname "$0")/../../capture.sh"

block chain
run 'docker run -d --name web alpine:3.22 sleep 600'
run 'ps -o pid,ppid,args -C dockerd,containerd,containerd-shim-runc-v2,sleep | grep -v defunct'
block socket
run 'ls -l /var/run/docker.sock'
run 'curl -s --unix-socket /var/run/docker.sock http://localhost/containers/json | jq ".[] | {Names, Image, State}"'

block packages
run "dpkg-query -W -f '\${Package} \${Version}\n' docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
run 'cat /etc/apt/sources.list.d/docker.list'
block systemd
run 'systemctl status docker'

block group
run 'id'
run 'getent group docker'
block bruno
run 'sudo -u bruno docker ps'
block root-equivalent
run 'ls /srv/payroll'
run 'docker run --rm -v /srv/payroll:/p alpine:3.22 cat /p/salaries.csv'

block daemon-json
run 'cat /etc/docker/daemon.json'
block info
run 'docker info | grep -E "^ (Server Version|Storage Driver|Logging Driver|Cgroup Driver|Cgroup Version|Docker Root Dir):"'
run 'docker info --format "{{.RegistryConfig.Mirrors}}"'
block root-dir
run 'sudo du -sh /var/lib/docker'
