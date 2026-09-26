#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of virtualization, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo useradd -m -s /bin/bash -G sudo ana     # once, on a throwaway machine
#   sudo cp ../../lab.sh /var/tmp/lab.sh          # the lab, beside course.json
#   sudo -u ana -i bash /path/to/captures.sh
#
# EVERY MACHINE IN THE LESSON IS PART OF ONE LAB. The computer is called host
# and runs Ubuntu 24.04 with QEMU and libvirt; every other name is one of its
# guests, a real virtual machine made by lab.sh from Ubuntu's minimal cloud
# image. A line that starts with ana@host ran on the computer itself, and one
# that starts with ana@vm1 ran inside the guest called vm1, reached with ssh.
#
# The computer the lab was recorded on is itself a virtual machine without
# nested virtualisation, so QEMU emulates the guests' processor in software
# (--virt-type qemu). With VT-x or AMD-V, the same commands take kvm.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the lab itself, built by lab.sh reset, with podman installed from Ubuntu's
# packages and told not to use cgroups, which the host's own container gives
# it none of to create; the two container images, ubuntu:24.04 and
# nginx:alpine, pulled from Docker Hub in advance; the guest vm1, made by
# lab.sh vm; and thirty seconds after asking vm1 to shut down.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with QEMU 8.2 and libvirt 10.0, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { sudo bash "$LAB_SH" "$@"; }
# on MACHINE 'command': what ana typed at her prompt, on host itself or inside
# one of its guests (reached with ssh), and everything it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  if [ "$h" = host ]; then (cd && bash -c "$*") 2>&1 || true
  else ssh "$h" "$*" 2>&1 || true; fi
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() {
  local h=$1; shift
  if [ "$h" = host ]; then sudo bash -c "$*" >/dev/null 2>&1 || true
  else ssh "$h" "sudo bash -c $(printf %q "$*")" >/dev/null 2>&1 || true; fi
}
block() { printf '##### %s\n' "$1"; }

cd ~
lab reset
quiet host 'printf "[containers]\ncgroups = \"disabled\"\n[engine]\ncgroup_manager = \"cgroupfs\"\n" > /etc/containers/containers.conf'
quiet host 'export HTTPS_PROXY=http://127.0.0.1:33915; podman pull -q docker.io/library/ubuntu:24.04; podman pull -q docker.io/library/nginx:alpine; podman rm -f web'
lab vm vm1

block kernels
on host 'uname -r'
on vm1 'uname -r'
on host 'sudo podman run --rm docker.io/library/ubuntu:24.04 uname -r'

block inside
on host 'sudo podman run --rm docker.io/library/ubuntu:24.04 bash -c "echo my pid is \$\$; hostname; ls /"'

block start-time
on host 'time sudo podman run --rm docker.io/library/ubuntu:24.04 true'
on host 'virsh shutdown vm1'
sleep 30
on host 'time (virsh start vm1 >/dev/null && until ssh -o ConnectTimeout=2 vm1 true 2>/dev/null; do sleep 1; done)'

block from-the-host
on host 'sudo podman run -d --name web -p 8080:80 docker.io/library/nginx:alpine'
on host 'curl -s localhost:8080 | grep "<title>"'
on host 'ps -o pid,user,rss,comm -C nginx'
on host 'ps -o pid,user,rss,comm -C qemu-system-x86_64'
on host 'sudo podman images'

block where-am-i
on host 'systemd-detect-virt --container; systemd-detect-virt --vm'

quiet host 'podman rm -f web'
lab down >/dev/null 2>&1
