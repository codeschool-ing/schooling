#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file compiled here is lifted out of this lesson's .md by ../../lab.sh,
# so the file compiled is the block the student copies.
#
# What is STAGED rather than typed:
#   - the-lab and when-setup-fails run on the BARE machine, a stock Ubuntu
#     24.04 before anything of this course was installed, and throw it away
#     between failures with `rebare`;
#   - fail-path runs in one interactive terminal that was open before
#     ~/.bashrc gained its line (`ibare` in ../../lab.sh);
#   - fail-cut cuts a copy of the downloaded archive to 300 MB with
#     `truncate`, which is what a connection that dropped halfway leaves;
#   - fail-deps starts again from a fresh bare machine and skips the `apt`
#     line, as a student who jumps straight to the download does; its
#     archive is copied in from the installed machine rather than fetched a
#     second time, and it is the same file, checked in `verify`.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
URL=https://download.swift.org/swift-6.4.2-release/ubuntu2404/swift-6.4.2-RELEASE
T=swift-6.4.2-RELEASE-ubuntu24.04

DEPS="binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev curl"

# ---- the-lab, on the bare machine
rebare
block install
bare 'swift --version; echo $?'
bare "sudo apt install -y $DEPS 2>&1 | grep -E '^(Need to get|After this operation)'"

block download
bare 'mkdir -p ~/downloads ~/.local/share && cd ~/downloads'
BARE_D=downloads
bare "curl -fsSLO -C - --retry 5 --retry-all-errors $URL/$T.tar.gz"
bare "curl -fsSLO $URL/$T.tar.gz.sig"
bare 'ls -lh'

block verify
bare 'curl -fsSL https://www.swift.org/keys/all-keys.asc | gpg --import -'
bare "gpg --verify $T.tar.gz.sig"

block unpack
bare "tar xzf $T.tar.gz -C ~/.local/share"
bare "echo 'export PATH=\"\$HOME/.local/share/$T/usr/bin:\$PATH\"' >> ~/.bashrc"
bare 'source ~/.bashrc'
bare "du -sh ~/.local/share/$T"
unset BARE_D

block check
bare 'swift --version'
bare 'which swift'

# ---- when-setup-fails
block fail-path
ibare 'swift --version' 'echo $?' 'source ~/.bashrc' 'swift --version'

block fail-cut
BARE_D=downloads
bare_quiet "cp $T.tar.gz cut.tar.gz && truncate -s 300M cut.tar.gz"
bare 'ls -lh cut.tar.gz'
bare "gpg --verify $T.tar.gz.sig cut.tar.gz"
bare 'tar xzf cut.tar.gz -C /tmp; echo $?'
bare_quiet 'rm cut.tar.gz'
unset BARE_D

block fail-deps
rebare
bare_quiet "mkdir -p ~/downloads ~/.local/share"
cp /var/lib/machines/ios-lab/home/ana/downloads/$T.tar.gz /var/lib/machines/ios-bare/home/ana/downloads/
chown 1000:1000 /var/lib/machines/ios-bare/home/ana/downloads/$T.tar.gz
BARE_D=downloads
bare "tar xzf $T.tar.gz -C ~/.local/share"
bare "echo 'export PATH=\"\$HOME/.local/share/$T/usr/bin:\$PATH\"' >> ~/.bashrc"
bare 'source ~/.bashrc; swift --version'
unset BARE_D
rebare

MD=$HERE/the-package.md
at .; quiet "rm -rf ~/planner"
at .
block layout
run 'mkdir -p planner/Sources/PlannerCore planner/Sources/week planner/Tests/PlannerCoreTests'
run 'cd planner'
at planner
for f in Package.swift Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift \
         Sources/week/main.swift Tests/PlannerCoreTests/PlanTests.swift; do put "$MD" "$f"; done
block build
run 'find Sources Tests -type f | sort'
run 'swift build'
run '.build/debug/week'
block test
run 'swift test'

# ---- info-plist
MD=$HERE/info-plist.md
fresh plist
put "$MD" Info.plist
put "$MD" check.swift
block plist
run 'swift check.swift Info.plist'
run "sed -e 's/com.example.planner/com.example.study_planner/' -e 's|<string>1.0</string>|<string>1.0 beta</string>|' Info.plist > Broken.plist"
run 'diff Info.plist Broken.plist'
run 'swift check.swift Broken.plist'
