#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1's "building-the-lab" and
# "working-in-the-lab" and "when-it-fails", as a script that produces them.
#
# UNLIKE captures.sh, THIS DOES NOT RUN IN THE LAB. It installs the lab, so it
# needs what the lab is built not to have: the network, apt and sudo. It runs
# on an Ubuntu 24.04 machine, as ana, in a home directory emptied first.
#
#   sudo bash captures-setup.sh
#
# THE TWO SCRIPTS ana RUNS ARE TAKEN FROM THE LESSON, not kept here:
# from_lesson reads the fence of building-the-lab.md that names the file, so
# the script the student reads is the very file this ran.
#
# What root does first, and why none of it is in the lesson:
#   - removes Terraform and HashiCorp's repository if a previous run left them,
#     so the run starts from a machine that has neither;
#   - gives ana passwordless sudo, because a capture cannot type a password;
#   - points apt at the recording machine's HTTPS proxy, and passes the proxy
#     to ana's shell. That proxy is the recording machine's way out and not
#     part of anybody's lab; it prints nothing in any transcript;
#   - installs apt-utils and whiptail, which a stock Ubuntu Server has and a
#     container image does not; without them apt's configuration step prints
#     lines about its missing frontends that nobody else sees;
#   - puts Ubuntu's own Python 3.12 first on ana's PATH, because this machine's
#     python3 was replaced with 3.13 and a stock Ubuntu 24.04 has 3.12.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ "$(id -u)" = 0 ]; then
  apt-get install -y -qq apt-utils whiptail >/dev/null 2>&1
  apt-get remove -y -qq terraform >/dev/null 2>&1 || true
  rm -f /etc/apt/sources.list.d/hashicorp.list /usr/share/keyrings/hashicorp.gpg
  id ana >/dev/null 2>&1 || useradd -m -u 1500 -s /bin/bash ana
  gpasswd -d ana docker >/dev/null 2>&1 || true
  rm -rf /home/ana && mkdir /home/ana && cp -r /etc/skel/. /home/ana
  mkdir -p /home/ana/.stock-bin && ln -sf /usr/bin/python3.12 /home/ana/.stock-bin/python3
  chown -R ana: /home/ana
  echo 'ana ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ana-recording
  if [ -n "${HTTPS_PROXY:-}" ]; then
    printf 'Acquire::https::Proxy "%s";\n' "$HTTPS_PROXY" > /etc/apt/apt.conf.d/90recording-proxy
  fi
  pkill -u ana -f moto_server 2>/dev/null || true
  status=0
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    PATH=/home/ana/.stock-bin:/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat TERM=xterm-256color \
    HTTPS_PROXY="${HTTPS_PROXY:-}" https_proxy="${HTTPS_PROXY:-}" NO_PROXY="${NO_PROXY:-}" no_proxy="${NO_PROXY:-}" \
    IN_LAB=1 bash "$HERE/$(basename "$0")" || status=$?
  pkill -u ana -f moto_server 2>/dev/null || true
  rm -f /etc/sudoers.d/ana-recording /etc/apt/apt.conf.d/90recording-proxy
  exit $status
fi

. "$HERE/../../capture.sh"
LESSON=$HERE/building-the-lab.md
from_lesson "$LESSON" '~/setup-iac.sh' > ~/setup-iac.sh
from_lesson "$LESSON" '~/iac-env.sh' > ~/iac-env.sh
from_lesson "$HERE/working-in-the-lab.md" '~/fresh-lesson.sh' > ~/fresh-lesson.sh

# term CMD: as run, but on a terminal, as the student's is. Without one apt's
# configuration step explains at length that it has no terminal to ask on, and
# a shell reading a script words "not found" differently from one at a prompt.
term() {
  prompt "$1"
  # -E never: nobody types here, and at the end of its empty input script
  # would otherwise echo a ^@ into the transcript
  script -q -E never -ec "bash -ic '$1'" /dev/null < /dev/null | tr -d '\r'  | decolour
}

block setup
term 'sh setup-iac.sh'

# Before iac-env.sh has been read: the two ways a terminal goes wrong.
block not-sourced
term 'aws sts get-caller-identity'
block venv-only
# a . line changes this shell, so it is printed and done here rather than
# through run, whose pipe would give it a shell of its own
prompt '. ~/iac-venv/bin/activate'; . ~/iac-venv/bin/activate
run 'aws sts get-caller-identity'
deactivate

block moto
# The second terminal: moto in the background, its first lines shown as they
# appeared, then left running for the rest of the script.
prompt '. ~/iac-env.sh'
prompt 'moto_server -p 4566'
( . ~/iac-env.sh; exec moto_server -p 4566 ) > ~/.moto-out 2>&1 < /dev/null &
for i in $(seq 50); do curl -s -o /dev/null localhost:4566 && break; sleep 0.2; done
sleep 1
grep -v '^ *$' ~/.moto-out | grep -v '"GET / HTTP' | head -n 3

block check
prompt '. ~/iac-env.sh'; . ~/iac-env.sh
run 'env | grep ^AWS_ | sort'
run 'aws sts get-caller-identity'
run 'aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text'

block not-listening
run 'AWS_ENDPOINT_URL=http://localhost:4567 aws sts get-caller-identity'

block fresh
# STAGED: the directories lesson 1's own transcripts leave in a home directory
quiet 'mkdir -p ~/shop ~/shop-tf ~/lookup'
run 'sh ~/fresh-lesson.sh'
term 'ls'
