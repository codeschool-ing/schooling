#!/usr/bin/env bash
# Lesson 15 of portfolio-project: the server, and a deploy that stays up.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
# THE LAB IS TWO MACHINES. laptop is where ana writes the project; srv is the
# server she deploys it to, built in the lesson's first section from srv.yaml.
# Both run Ubuntu 24.04 and share a private network (laptop is 10.20.0.10, srv
# is 10.20.0.20). A line that starts with ana@laptop ran on laptop, and one that
# starts with ana@srv ran on srv, reached with ssh from laptop. The path after
# the colon is the directory the command ran in.
#
#   sudo bash captures.sh          # on the recording computer, which has Docker
#
# THIS SCRIPT RUNS ON THE RECORDING COMPUTER, not on laptop: it builds both
# machines as Docker containers on one network, because srv has to be born
# from the srv.yaml the lesson shows, with the key laptop has just made.
#   - laptop is an image of Ubuntu 24.04 (debootstrap, minbase, with git,
#     OpenSSH, Python 3, curl and openssl) running `sleep infinity`, with an
#     account ana that may sudo. Commands run with umask 002, Ubuntu's own
#     for an account with a group of its own, and laptop has no name server,
#     so that `srv` means nothing until ~/.ssh/config says what it is: Docker
#     would otherwise answer for it.
#   - srv is the same image plus cloud-init, booted with systemd as its first
#     process. srv.yaml is CUT OUT OF the-server.md below, the one line the
#     lesson tells the student to replace is replaced with ana's public key,
#     and the result is handed to cloud-init as a NoCloud seed, which is what
#     Multipass hands a virtual machine. Everything srv.yaml asks for, the
#     account, the key and the packages, is then done by cloud-init itself.
#   - A virtual machine was not used because the recording computer has no
#     hardware virtualisation; the multipass commands in the lesson were not
#     run, and the lesson says so.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - python:3.12-slim is loaded into srv's Podman from the recording
#     computer, and tagged with the name the Containerfile uses: Docker Hub
#     refused the recording computer's anonymous pulls (429), and a mirror of
#     the same image served it.
#   - ~/loanbook is rebuilt at step 20 on laptop (lab.sh, copied into laptop
#     at /var/tmp/lab.sh).
#   - The "rebuilt srv" of the failures section is srv with new host keys
#     (ssh-keygen -A after deleting them), which is what ssh sees when a
#     machine is built again at the same address.
#   - A reboot was not recorded: srv is a container, and one that reboots does
#     not come back on its own.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with Python 3.12, git 2.43, OpenSSH 9.6, Podman 4.9,
# Caddy 2.6 and cloud-init 24, TZ=America/Sao_Paulo on laptop and UTC on srv.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
IMAGE=${IMAGE:-lab/noble:base}           # the debootstrapped Ubuntu 24.04
SRV_IMAGE=${SRV_IMAGE:-lab/noble:srv}    # the same, plus cloud-init
PYIMAGE=${PYIMAGE:-mirror.gcr.io/library/python:3.12-slim}

# L 'command': run a command on laptop as ana, in her home.
L() {
  docker exec -u ana -w /home/ana -e HOME=/home/ana -e USER=ana -e TZ=America/Sao_Paulo \
    -e LC_ALL=C.UTF-8 -e PAGER=cat -e GIT_PAGER=cat -e COLUMNS=100 laptop bash -c "umask 002; $1"
}
# on MACHINE DIR 'command': what ana typed at her prompt, in DIR (relative to
# her home, "~" for the home itself), on laptop or on srv through ssh, and
# everything it printed.
on() {
  local h=$1 d=$2; shift 2
  local shown=$([ "$d" = "~" ] && echo "~" || echo "~/$d")
  local cd=$([ "$d" = "~" ] && echo "cd" || echo "cd \$HOME/$d")
  printf 'ana@%s:%s$ %s\n' "$h" "$shown" "$*"
  if [ "$h" = laptop ]; then L "$cd && $*" 2>&1 || true
  else L "ssh srv $(printf %q "$cd && $*")" 2>&1 || true; fi
}
# The same, not shown: the lab's own housekeeping.
quiet() {
  local h=$1 d=$2; shift 2
  local cd=$([ "$d" = "~" ] && echo "cd" || echo "cd \$HOME/$d")
  if [ "$h" = laptop ]; then L "$cd && $*" >/dev/null 2>&1 || true
  else L "ssh srv $(printf %q "$cd && $*")" >/dev/null 2>&1 || true; fi
}
# typed MACHINE 'command' 'answer': a command that asks a question on the
# terminal, answered with ANSWER, run on laptop through a terminal so the
# question and the answer show as they did.
typed() {
  printf 'ana@laptop:~$ %s\n' "$1"
  L "(sleep 3; printf '%s\n' $(printf %q "$2")) | script -qec $(printf %q "$1") /dev/null" 2>&1 | tr -d '\r' || true
}
block() { printf '##### %s\n' "$1"; }

# ---- the machines
docker rm -f laptop srv >/dev/null 2>&1
docker network inspect labnet >/dev/null 2>&1 ||
  docker network create --subnet 10.20.0.0/24 labnet >/dev/null
docker run -d --name laptop --hostname laptop --network labnet --ip 10.20.0.10 \
  "$IMAGE" sleep infinity >/dev/null
docker exec laptop bash -c '
  useradd -m -s /bin/bash -G sudo ana
  echo "ana ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ana && chmod 440 /etc/sudoers.d/ana
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
  : > /etc/resolv.conf'
docker cp "$LAB" laptop:/var/tmp/lab.sh
L 'git config --global user.name "Ana Lima" && git config --global user.email ana@example.org'
lab() { L "bash /var/tmp/lab.sh $*" >/dev/null 2>&1; }

# ---- the key, and srv born from srv.yaml with it
block key
on laptop '~' 'ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519'
on laptop '~' 'cat ~/.ssh/id_ed25519.pub'

seed=$(mktemp -d)
awk '/^```yaml$/{f=1; next} /^```$/{if (f) exit} f' "$HERE/the-server.md" > "$seed/srv.yaml"
grep -q '^#cloud-config$' "$seed/srv.yaml" || { echo "no srv.yaml in the-server.md" >&2; exit 1; }
key=$(L 'cat ~/.ssh/id_ed25519.pub')
placeholder='      - paste the line from ~/.ssh/id_ed25519.pub here'
grep -qxF -- "$placeholder" "$seed/srv.yaml" || { echo "srv.yaml lost its placeholder" >&2; exit 1; }
awk -v p="$placeholder" -v k="      - $key" '$0 == p {print k; next} {print}' "$seed/srv.yaml" > "$seed/user-data"
printf 'instance-id: srv-1\nlocal-hostname: srv\n' > "$seed/meta-data"
docker run --rm -v "$seed:/x" "$SRV_IMAGE" cloud-init schema -c /x/user-data >&2
docker create --name srv --hostname srv --network labnet --ip 10.20.0.20 --privileged \
  --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw --tmpfs /run --tmpfs /run/lock \
  "$SRV_IMAGE" /sbin/init >/dev/null
mkdir -p "$seed/cloud/seed/nocloud" && cp "$seed/user-data" "$seed/meta-data" "$seed/cloud/seed/nocloud/"
docker cp "$seed/cloud/." srv:/var/lib/cloud/
docker start srv >/dev/null 2>&1

block noname
on laptop '~' 'ssh srv true'
block config
on laptop '~' "printf 'Host srv\n    HostName 10.20.0.20\n    User ana\n' >> ~/.ssh/config"
on laptop '~' 'cat ~/.ssh/config'
for _ in $(seq 60); do L 'exec 3<>/dev/tcp/10.20.0.20/22' 2>/dev/null && break; sleep 1; done
block hostkey
typed 'ssh srv hostname' 'yes'
block early
on laptop '~' 'ssh srv cloud-init status'
on laptop '~' 'ssh srv podman --version'
block wait
on laptop '~' 'ssh srv cloud-init status --wait'
on laptop '~' 'ssh srv "podman --version; caddy version; git --version; python3 --version"'
block wronguser
on laptop '~' 'ssh ubuntu@srv true'

# ---- staged: the base image, and the project at its last step
docker save "$PYIMAGE" | docker exec -i srv podman load >/dev/null
docker exec srv podman tag "$PYIMAGE" docker.io/library/python:3.12-slim
docker exec srv podman untag "$PYIMAGE" "$PYIMAGE" >/dev/null 2>&1
lab stage 20

block remote
on srv '~' 'git init -q --bare -b main loanbook.git'
on laptop loanbook 'git remote add srv srv:loanbook.git'
on laptop loanbook 'git push -q srv main --tags'
on srv '~' 'git clone -q loanbook.git && git -C loanbook log --oneline -1'
on laptop loanbook 'git log --oneline -1'
block build
on srv loanbook 'cat Containerfile'
on srv loanbook 'sudo podman build -t loanbook .'
block unit
on srv loanbook 'cat deploy/loanbook.container'
on srv loanbook 'sudo cp deploy/loanbook.container /etc/containers/systemd/'
on srv loanbook 'sudo systemctl daemon-reload'
on srv loanbook 'sudo systemctl start loanbook'
sleep 3
on srv loanbook 'systemctl status loanbook --no-pager | head -4'
on srv loanbook 'curl -s 127.0.0.1:8000/healthz'
echo
block seed
on srv loanbook 'sudo podman exec systemd-loanbook python3 seed.py'
block caddy
on srv loanbook 'systemctl is-active caddy'
on srv loanbook 'cat deploy/Caddyfile'
on srv loanbook 'sudo cp deploy/Caddyfile /etc/caddy/Caddyfile'
on srv loanbook 'sudo systemctl reload caddy'
sleep 4
block untrusted
on laptop '~' "echo '10.20.0.20 loans.lab' | sudo tee -a /etc/hosts"
on laptop '~' 'curl -sS https://loans.lab/healthz'
block trust
on laptop '~' 'ssh srv sudo cat /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt > lab-root.crt'
on laptop '~' 'openssl x509 -in lab-root.crt -noout -subject -enddate'
on laptop '~' 'sudo cp lab-root.crt /usr/local/share/ca-certificates/loans-lab-root.crt'
on laptop '~' 'sudo update-ca-certificates'
on laptop '~' 'curl -sS https://loans.lab/healthz'
echo
on laptop '~' 'curl -sS https://loans.lab/api/items | python3 -m json.tool | head -12'
block health
on srv '~' 'sudo podman healthcheck run systemd-loanbook && echo healthy'
on srv '~' "sudo podman inspect --format '{{.State.Health.Status}}' systemd-loanbook"
block restart
on srv '~' 'systemctl show -p NRestarts loanbook'
on srv '~' 'sudo podman kill systemd-loanbook'
sleep 6
on srv '~' 'systemctl show -p NRestarts loanbook'
on srv '~' 'systemctl is-active loanbook'
on laptop '~' 'curl -sS https://loans.lab/healthz'
echo
on laptop '~' "curl -sS https://loans.lab/api/items | python3 -c 'import json,sys; print(len(json.load(sys.stdin)), \"items\")'"
block boot
on srv '~' 'systemctl is-enabled loanbook caddy'

# ---- staged: srv built again at the same address, so with new host keys
docker exec srv bash -c 'rm -f /etc/ssh/ssh_host_* && ssh-keygen -A >/dev/null && systemctl restart ssh'
sleep 2
block rebuilt
on laptop '~' 'ssh srv true'
on laptop '~' 'ssh-keygen -R 10.20.0.20'
rm -rf "$seed"
