#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of docker, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged rather than typed: alpine:3.22 is pulled before the first command.
# The digests are Docker Hub's for that tag on the day of the run, and move
# when Alpine publishes a new 3.22 build.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, runc 1.5, TZ=America/Sao_Paulo.
export LAB_IMAGES="alpine:3.22"
. "$(dirname "$0")/../../capture.sh"

block runtime
run 'docker info --format "{{.DefaultRuntime}}"'
run 'runc --version'

block save
run 'docker save alpine:3.22 -o alpine.tar'
run 'mkdir alpine && tar -xf alpine.tar -C alpine'
run 'ls alpine'
run 'jq -c . alpine/oci-layout'
block index
run 'jq . alpine/index.json'
IDX=$(jq -r '.manifests[0].digest' alpine/index.json | cut -d: -f2)
block platforms
run "jq -c '.manifests[] | {platform, digest}' alpine/blobs/sha256/$IDX"
MAN=$(jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest' alpine/blobs/sha256/$IDX | cut -d: -f2)
block manifest
run "jq . alpine/blobs/sha256/$MAN"
CFG=$(jq -r '.config.digest' alpine/blobs/sha256/$MAN | cut -d: -f2)
LAY=$(jq -r '.layers[0].digest' alpine/blobs/sha256/$MAN | cut -d: -f2)
block config
run "jq '{architecture, os, config: {Env: .config.Env, Cmd: .config.Cmd}, rootfs}' alpine/blobs/sha256/$CFG"
block layer
run "tar -tzf alpine/blobs/sha256/$LAY | head -8"
run "tar -tzf alpine/blobs/sha256/$LAY | wc -l"
block addressed
run "sha256sum alpine/blobs/sha256/$LAY"
block tamper
quiet "cp alpine/blobs/sha256/$LAY layer.tar.gz && chmod u+w layer.tar.gz"
run 'printf x >> layer.tar.gz'
run 'sha256sum layer.tar.gz'

block bundle
run 'mkdir -p bundle/rootfs'
run 'docker export $(docker create alpine:3.22) | tar -x -C bundle/rootfs'
run 'ls bundle/rootfs'
block spec
run 'cd bundle && runc spec --rootless && ls'
run "jq '{ociVersion, process: {terminal: .process.terminal, args: .process.args, cwd: .process.cwd}, root, hostname}' config.json"
block namespaces
run "jq -c '.linux.namespaces' config.json"
block runc-run
run "jq '.process.terminal = false | .process.args = [\"sh\", \"-c\", \"hostname; cat /etc/alpine-release; ps\"]' config.json > c.json && mv c.json config.json"
run 'runc --root /tmp/runc-ana run demo'
run 'echo $?'
