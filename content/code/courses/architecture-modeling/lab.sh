#!/usr/bin/env bash
# The lab every command in architecture-modeling ran on. Only lesson 12 has one:
# the other thirteen lessons have no runtime, and say so.
#
# ONE LINUX MACHINE, CALLED vm, WITH A NORMAL USER CALLED ana, AND THE THREE
# RUNTIMES LESSON 12's "Your lab" TELLS A STUDENT TO INSTALL: Node.js 22, a Java 21
# runtime and Docker. The script checks them rather than installing them, because
# how they are installed differs per system and the lesson sends the student to
# each project's own instructions; it refuses to run if a version is wrong.
#
# STAGED, AND NOT SHOWN IN THE LESSON:
#   - the user ana, a member of the docker group;
#   - ana's ~/.profile carries this sandbox's outbound proxy and its certificate
#     (HTTPS_PROXY, NO_PROXY, NODE_EXTRA_CA_CERTS, CURL_CA_BUNDLE), so that npm, the
#     browser download and curl can reach the internet from here. A student's own
#     machine needs none of it, and the lesson's section on failures says what to
#     set behind a company proxy;
#   - the Docker daemon, started here by hand, and the Structurizr image, pulled
#     before the recording so that the lesson's transcript is not a page of pull
#     progress.
#
#   sudo bash lab.sh up       the user, the profile, the daemon and the image
#   sudo bash lab.sh reset    an empty ~ana/diagrams (the browser cache is kept)
#   sudo bash lab.sh down     remove ana's lesson folder
set -euo pipefail

IMAGE=structurizr/structurizr:2026.09.19

need() {
  node --version | grep -q '^v22\.' || { echo "need Node.js 22" >&2; exit 1; }
  env -u JAVA_TOOL_OPTIONS java -version 2>&1 | grep -q 'version "21' || { echo "need Java 21" >&2; exit 1; }
  docker --version >/dev/null || { echo "need Docker" >&2; exit 1; }
}

up() {
  need
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  getent group docker >/dev/null || groupadd docker
  usermod -aG docker ana
  if ! docker info >/dev/null 2>&1; then
    (setsid dockerd >/var/tmp/dockerd.log 2>&1 </dev/null &)
    for _ in $(seq 1 30); do docker info >/dev/null 2>&1 && break; sleep 1; done
  fi
  chgrp docker /var/run/docker.sock && chmod g+rw /var/run/docker.sock
  install -o ana -m 644 "${CA_BUNDLE:-/root/.ccr/ca-bundle.crt}" /home/ana/.lab-ca.crt
  cat > /home/ana/.profile <<PROFILE
# lab plumbing: this sandbox's outbound proxy, which a student's machine does not have
export HTTPS_PROXY='${HTTPS_PROXY:-}' HTTP_PROXY='${HTTP_PROXY:-}' NO_PROXY='${NO_PROXY:-}'
export NODE_EXTRA_CA_CERTS=\$HOME/.lab-ca.crt CURL_CA_BUNDLE=\$HOME/.lab-ca.crt
export PATH=$(dirname "$(command -v node)"):\$PATH
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
PROFILE
  chown ana /home/ana/.profile
  docker image inspect "$IMAGE" >/dev/null 2>&1 || docker pull -q "$IMAGE"
}

reset() { rm -rf /home/ana/diagrams; }
down() { reset; }

"${1:-up}"
