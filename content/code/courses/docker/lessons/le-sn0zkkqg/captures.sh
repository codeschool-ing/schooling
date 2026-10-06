#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: alpine:3.22 is pulled before the first command.
# The lab machine runs cgroup v1, which is why the limits are read from
# /sys/fs/cgroup/memory/docker/... and not from a single unified tree; the
# lesson says what a cgroup v2 machine shows instead, without a transcript.
# Process numbers, container ids and snapshot numbers are this run's.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
export LAB_IMAGES="alpine:3.22"
. "$(dirname "$0")/../../capture.sh"

block start
run 'docker run -d --name web --hostname web alpine:3.22 sleep 600'
run 'PID=$(docker inspect -f "{{.State.Pid}}" web); echo $PID'
block ns-compare
run 'sudo readlink /proc/$PID/ns/pid /proc/$PID/ns/net /proc/$PID/ns/uts /proc/$PID/ns/mnt'
run 'readlink /proc/$$/ns/pid /proc/$$/ns/net /proc/$$/ns/uts /proc/$$/ns/mnt'
block lsns
run 'sudo lsns -p $PID'
block uts
run 'hostname'
run 'docker exec web hostname'
block net
run 'docker exec web ls /sys/class/net'
run 'ls /sys/class/net'
block nsenter
run 'sudo nsenter --target $PID --uts --net sh -c "hostname; ip -brief addr"'

block cg-start
run 'docker run -d --name capped --memory 64m --cpus 0.5 --pids-limit 20 alpine:3.22 sleep 600'
run 'ID=$(docker inspect -f "{{.Id}}" capped); grep -E ":(memory|pids|cpu):" /proc/$(docker inspect -f "{{.State.Pid}}" capped)/cgroup'
block cg-files
run 'cat /sys/fs/cgroup/memory/docker/$ID/memory.limit_in_bytes'
run 'cat /sys/fs/cgroup/cpu/docker/$ID/cpu.cfs_quota_us /sys/fs/cgroup/cpu/docker/$ID/cpu.cfs_period_us'
run 'cat /sys/fs/cgroup/pids/docker/$ID/pids.max'
block pids
run 'docker exec capped sh -c "for i in \$(seq 30); do sleep 5 & done; wait" 2>&1 | tail -3'
run 'cat /sys/fs/cgroup/pids/docker/$ID/pids.current'
block oom
run 'docker run --name hog --memory 64m alpine:3.22 sh -c "x=a; while true; do x=\$x\$x; done"'
run 'echo $?'
run 'docker inspect -f "OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}}" hog'

block overlay-mount
run 'docker exec web sh -c "echo hello > /tmp/new.txt; rm /etc/motd"'
run 'findmnt -no OPTIONS /var/lib/docker/rootfs/overlayfs/$(docker inspect -f "{{.Id}}" web) | tr "," "\n"'
OPTS=$(findmnt -no OPTIONS /var/lib/docker/rootfs/overlayfs/$(docker inspect -f "{{.Id}}" web))
UNUM=$(printf '%s' "$OPTS" | sed -n 's/.*upperdir=[^,]*snapshots\/\([0-9]*\)\/fs.*/\1/p')
INUM=$(printf '%s' "$OPTS" | sed -n 's/.*lowerdir=[^:]*snapshots\/\([0-9]*\)\/fs:.*/\1/p')
block upper
run 'SNAP=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots'
run "sudo find \$SNAP/$UNUM/fs -mindepth 1 -printf '%P\n'"
run "sudo ls -l \$SNAP/$UNUM/fs/etc"
block init-layer
run "sudo find \$SNAP/$INUM/fs -type f -printf '%P\n'"
block image-untouched
run 'docker run --rm alpine:3.22 ls /tmp /etc/motd'
