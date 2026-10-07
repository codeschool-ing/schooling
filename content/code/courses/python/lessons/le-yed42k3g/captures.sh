#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of python, section `when-it-fails`,
# as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# that section was copied from running it:
#
#   bash captures.sh            # needs docker, and the network for apt
#
# The machine is a fresh Ubuntu 24.04, which is what section `three-ways` has a
# student install in a virtual machine, named `lab`, with one user, `ana`, in
# the group `sudo` as the first user of an Ubuntu Server install is. It runs in
# a container rather than a virtual machine because the userland is the same
# and a container starts clean every time.
#
# What is STAGED rather than typed: the packages Ubuntu Server ships and the
# container image leaves out (python3, command-not-found, sudo), and the file
# ~/.sudo_as_admin_successful, without which every new shell of a sudo user
# opens with a two-line note about sudo — true once on a real machine, noise
# in a transcript. The apt line is the one section `getting-one` gives, with
# `-y` because nobody is there to answer its question.
#
# APT_PROXY and APT_CA, when set, point apt inside the container at an HTTPS
# proxy and its certificate; they are this recording machine's, not a step of
# the lesson.
#
# Recorded on Ubuntu 24.04 (python3 3.12.3-0ubuntu2.1), on 2026-10-07.
set -uo pipefail

guest=$(cat <<'GUEST'
set -e
export DEBIAN_FRONTEND=noninteractive
if [ -n "${APT_PROXY:-}" ]; then
  sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources
  printf 'Acquire::https::Proxy "%s";\nAcquire::https::CAInfo "/ca.crt";\n' "$APT_PROXY" \
    > /etc/apt/apt.conf.d/99proxy
fi
apt-get update -qq >/dev/null
apt-get install -y -qq python3 command-not-found sudo >/dev/null 2>&1
apt-get update -qq >/dev/null              # command-not-found's index
useradd -m -s /bin/bash -G sudo ana
echo 'ana ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ana
touch /home/ana/.sudo_as_admin_successful

# One interactive bash per command, in a terminal, so command-not-found answers
# as it does at a real prompt.
on() {
  printf 'ana@lab:~$ %s\n' "$1"
  runuser -u ana -- script -qec "cd ~ && bash -ic '$1'" /dev/null 2>&1 \
    | tr -d '\r' | grep -v '^bash: \(cannot set terminal\|no job control\)' || true
}
block() { printf '##### %s\n' "$1"; }

block not-python
on 'python'
on 'python3 --version'

block no-pip
on 'pip --version'
on 'python3 -m venv .venv'

block after-apt
on 'sudo apt install -y python3-venv python3-pip' >/dev/null
on 'python3 -m venv .venv'
on 'ls .venv'
on 'pip --version'

block disk
on 'du -sh /usr/lib/python3.12'
GUEST
)

args=(--rm --hostname lab)
if [ -n "${APT_PROXY:-}" ]; then
  args+=(--network host -e "APT_PROXY=$APT_PROXY" -v "${APT_CA:?APT_CA with APT_PROXY}:/ca.crt:ro")
fi
docker run "${args[@]}" ubuntu:24.04 bash -c "$guest"
