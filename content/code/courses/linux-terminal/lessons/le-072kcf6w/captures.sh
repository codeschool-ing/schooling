#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript of the lesson into a real bash, as the user and in the directory the
# prompt names, and prints the fences whose output differs.
#
#   sudo bash captures.sh
#
# alpine-and-containers needs a Docker daemon that can reach Docker Hub, with
# `alpine` and `ubuntu:24.04` pulled. It was captured on 2026-10-07 with Docker
# 29.8.2 started by hand (`dockerd &`: the sandbox has no systemd); `apk add`
# could not be, because the proxy refuses dl-cdn.alpinelinux.org.
# debian-ubuntu's sources.list.d and which-am-i-on's kernel are the capture
# machine's own and differ on any other.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" $sections
