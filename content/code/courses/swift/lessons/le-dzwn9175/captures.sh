#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of this lesson's .md by ../../lab.sh,
# so the file compiled is the block the student copies.
#
# STAGED:
#   - Before `platforms`, any static Linux SDK left by an earlier run is
#     removed, so the list starts empty and `static` installs it as the
#     lesson does.
#   - `server` runs the server in the background with its output in
#     server.log, and prints that log under the command that started it: on
#     the student's machine the server runs in one terminal and curl in a
#     second, and the log is what the first terminal shows. The server is
#     stopped by its process id at the end.
#   - `static` ends on a second, fresh copy of the bare machine (the Ubuntu
#     of lesson 1 before anything was installed). The two `week` binaries are
#     copied into ~ana there by this script, as `scp` would put them on
#     another computer; the lesson says so.
#   - The Hummingbird server is fetched from GitHub through the recording
#     proxy (lab.sh says how); on the student's machine git reaches GitHub
#     directly. Its build takes about two minutes in debug and three and a
#     half in release with the static SDK; the times printed are this
#     machine's.
#   - The server listens on 127.0.0.1:8090.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2 and Hummingbird 2.28.0,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SDK=swift-6.4.2-RELEASE_static-linux-0.1.0
SDKURL=https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/$SDK.artifactbundle.tar.gz
SDKSUM=3786b179936d9cc9e266dd506bd1654176358d7b25288e243359f4d17cc4dc5a

fresh sw/l20
quiet "swift sdk remove $SDK"

block platforms
run 'swift --version'
run "curl -s https://www.swift.org/api/v1/install/releases.json | python3 -c 'import json, sys; r = [x for x in json.load(sys.stdin) if x[\"name\"] == \"6.4.2\"][0]; print(\"\\n\".join(p[\"name\"] for p in r[\"platforms\"]))'"
run 'swift sdk list'

MD=$HERE/foundation.md
sr Where.swift where
se Fetch.swift fetch-refused
block fetch-fixed
put "$MD" FetchFixed.swift
run 'swiftc FetchFixed.swift -o fetchfixed && ./fetchfixed'

MD=$HERE/server.md
fresh sw/l20/server
put "$MD" Package.swift
put "$MD" Sources/PlannerServer/main.swift
block server-build
run 'swift build 2>&1 | tail -2'
run 'ls .build/checkouts | wc -l'
block server-run
_prompt "$_D" '.build/debug/PlannerServer'
quiet '.build/debug/PlannerServer > server.log 2>&1 < /dev/null & echo $! > server.pid'
quiet 'for i in $(seq 1 60); do grep -q "listening" server.log && break; sleep 1; done'
bash "$LAB_SH" exec "$_D" 'cat server.log'
block server-curl
run 'curl -s -i localhost:8090/week'
run 'curl -s localhost:8090/sessions; echo'
run 'curl -s -i localhost:8090/semana'
block server-client
put "$HERE/server.md" Client.swift
run 'swift Client.swift'
quiet 'kill $(cat server.pid); sleep 1; pkill -x PlannerServer; rm -f server.pid server.log'

MD=$HERE/static.md
fresh sw/l20/week
put "$MD" Package.swift
put "$MD" Sources/week/main.swift
block sdk-install
run "swift sdk install $SDKURL --checksum $SDKSUM | grep -v '%: Downloading'"
run 'swift sdk list'
block static-build
run 'swift build -c release 2>&1 | tail -1'
run 'swift build -c release --swift-sdk x86_64-swift-linux-musl 2>&1 | tail -1'
run 'ls -l .build/out/Products/*/week'
block static-file
run 'file -b .build/out/Products/Release-linux-x86_64/week | cut -d, -f1-4'
run 'file -b .build/out/Products/Release-staticlinux-x86_64/week | cut -d, -f1-4'
run 'ldd .build/out/Products/Release-staticlinux-x86_64/week'
run 'strip -o week-static .build/out/Products/Release-staticlinux-x86_64/week && ls -l week-static'
block static-elsewhere
rebare
P=/var/lib/machines/swift-lab/home/ana/sw/l20/week/.build/out/Products
B=/var/lib/machines/swift-bare/home/ana
cp "$P/Release-linux-x86_64/week" "$B/week-dynamic"
cp /var/lib/machines/swift-lab/home/ana/sw/l20/week/week-static "$B/week-static"
chown 1000:1000 "$B"/week-*
bare 'which swift; ls ~'
bare './week-dynamic 45 30 60'
bare './week-static 45 30 60'
rebare
block server-static
at sw/l20/server
run 'swift build -c release --swift-sdk x86_64-swift-linux-musl 2>&1 | tail -1'
run 'ls -l .build/out/Products/Release-staticlinux-x86_64/PlannerServer'
