#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build             # once
#   sudo bash captures.sh install            # the bare machine, then the install
#   sudo bash ../../lab.sh install           # once, the machine every later lesson uses
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
#
# STAGED: in `fails`, the old terminal is a command run with the PATH a shell
# has before ~/.bashrc was read (PLAIN_PATH=1); the missing libraries are a
# fresh bare machine with the toolchain unpacked and the apt line skipped; the
# damaged download is the real archive cut to 400 MiB with `truncate`, as a
# dropped connection leaves it.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
V=6.4.2
T=swift-$V-RELEASE-ubuntu24.04.tar.gz
U=https://download.swift.org/swift-$V-release/ubuntu2404/swift-$V-RELEASE/$T

if [ "${1:-}" = install ]; then
  rebare
  block install
  bare 'swift --version; echo $?'
  bare "sudo apt install -y binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev curl 2>&1 | grep -E '^(Need to get|After this operation|Setting up (git|gnupg2|curl|binutils|libz3-dev)[: ])'"
  block download
  bare 'mkdir -p ~/downloads ~/.local/share && cd ~/downloads'
  BARE_D=downloads
  bare "curl -fsSLO $U"
  bare "curl -fsSLO $U.sig"
  bare 'curl -fsSL https://www.swift.org/keys/all-keys.asc | gpg --import -'
  bare "gpg --verify $T.sig $T"
  bare 'ls -lh'
  block unpack
  bare "tar -xzf $T -C ~/.local/share"
  bare "echo 'export PATH=\"\$HOME/.local/share/swift-$V-RELEASE-ubuntu24.04/usr/bin:\$PATH\"' >> ~/.bashrc"
  bare 'source ~/.bashrc'
  bare 'ls ~/.local/share'
  bare "du -sh ~/.local/share/swift-$V-RELEASE-ubuntu24.04"
  BARE_D=
  block versions
  bare 'swift --version'
  bare 'which swift swiftc'
  exit 0
fi

block fails-path
at .
PLAIN_PATH=1 run 'swift --version; echo $?'
PLAIN_PATH=1 run "~/.local/share/swift-$V-RELEASE-ubuntu24.04/usr/bin/swift --version"
PLAIN_PATH=1 run 'echo $PATH'

block fails-libs
rebare
B=/var/lib/machines/swift-bare/home/ana
mkdir -p "$B/.local/share" && tar -xzf /var/lib/machines/swift-lab/home/ana/downloads/$T -C "$B/.local/share" && chown -R 1000:1000 "$B/.local"
bare 'swift --version; echo $?'
bare 'ldd $(which swift) | grep "not found"'
rebare

block fails-download
fresh dl
quiet "cp ~/downloads/$T ~/downloads/$T.sig . && truncate -s 400M $T"
run "gpg --verify $T.sig $T; echo \$?"
run "tar -xzf $T -C /tmp; echo \$?"
run "ls -l $T"
quiet "rm -f $T $T.sig"

fresh sw/l01
MD=$HERE/first-program.md
block hello
put "$MD" Hello.swift
run 'swift Hello.swift'
run 'swiftc Hello.swift -o hello'
run './hello'
run 'ls -l Hello.swift hello'
run 'file hello'
MD=$HERE/let-and-var.md
se Goal.swift goal
sc Week.swift week
sc Warn.swift warn
MD=$HERE/inference.md
sr Inference.swift inference
se Annotated.swift annotated
MD=$HERE/strong-types.md
se Mix.swift mix
sr MixFixed.swift mixfixed
block over
put "$MD" Over.swift
run 'swiftc Over.swift -o over'
run './over 2>&1 | head -4'
sr Parse.swift parse
