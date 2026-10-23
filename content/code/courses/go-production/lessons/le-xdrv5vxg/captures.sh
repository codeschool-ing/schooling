#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# a lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the four files of hits, placed from lesson 1 (le-03nqvqms) into ~/small,
#     with `go mod init example.com/hits` and access.log written by genlog
#     -n 20000, exactly as lesson 1 shows them.
#   - .gitignore and version.go, placed from this lesson's stamping-a-version
#     section; the three programs of ~/sizes, placed from beyond-the-flags, and
#     `go mod init example.com/sizes` there, which the lesson names.
#   - the two git commits run with GIT_AUTHOR_NAME/EMAIL and fixed
#     GIT_AUTHOR_DATE/GIT_COMMITTER_DATE in the environment (on_git below), so
#     that the revisions are the same on every run. The command shown is the
#     command run; only the environment is added. A reader's revisions differ.
#   - gdb and upx-ucl, installed on the lab machine from Ubuntu's archive before
#     this script runs; podman 4.9.3 likewise. The lesson shows the apt lines.
#   - in block subid, a throwaway user, ben, created here with his lines taken
#     out of /etc/subuid and /etc/subgid, so that the failure can be shown
#     without touching ana's; the fix is shown in the lesson as a sudo line and
#     run here as root. ben, his processes and his home are deleted at the
#     end.
#   - /tmp/small-v1.1.0 is removed before the run, so that `mkdir` succeeds.
# The timings are the `time` lines of block upx and block inline; they vary
# between runs, and the lesson quotes ratios.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }
GITENV='export GIT_AUTHOR_NAME=Ana GIT_AUTHOR_EMAIL=ana@example.com GIT_COMMITTER_NAME=Ana GIT_COMMITTER_EMAIL=ana@example.com'
on_git() { local d=$1 when=$2; shift 2; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$GITENV GIT_AUTHOR_DATE=$when GIT_COMMITTER_DATE=$when; $*" 2>&1 || true; }
BENENV="HOME=/home/ben USER=ben LOGNAME=ben SHELL=/bin/bash PATH=/usr/local/bin:/usr/bin:/bin LC_ALL=C.UTF-8 TZ=America/Sao_Paulo"
for v in HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy; do
  [ -n "${!v:-}" ] && BENENV="$BENENV $v=${!v}"
done
[ -r /usr/local/share/golab-ca.crt ] && BENENV="$BENENV SSL_CERT_FILE=/usr/local/share/golab-ca.crt"
ben() { printf 'ben@vm:~$ %s\n' "$*"; runuser -u ben -- env -i $BENENV bash -c "cd ~ && $*" 2>&1 || true; }

block setup
rm -rf /tmp/small-v1.1.0
lab fresh small
lab place le-03nqvqms arguments tools/genlog/main.go small
lab place le-03nqvqms subcommands internal/tally/tally.go small
lab place le-03nqvqms subcommands main.go small
lab place le-03nqvqms output-and-exit-codes main_test.go small
quiet small 'go mod init example.com/hits'
quiet small 'go run ./tools/genlog -n 20000 > access.log'

block baseline
on small 'go build -o hits . && stat -c "%s bytes  %n" hits'
on small 'file hits | cut -d, -f1,2,7,8'

block sections
on small 'size -A hits'
on small 'readelf -S -W hits | grep -E "debug_info|symtab|strtab"'

block nm
on small 'go tool nm hits | wc -l'
on small 'go tool nm -size -sort size hits | sed -n 1,8p'
on small 'go tool nm -size hits | grep -E " T (main|example.com/hits)"'
on small 'for p in runtime encoding/json time fmt example.com/hits main.; do go tool nm -size hits | awk -v p=$p '"'"'$3 ~ /^[Tt]$/ && index($4, p) == 1 { s += $2 } END { print s, p }'"'"'; done'

block flags
on small 'go build -ldflags="-w" -o hits-w . && go build -ldflags="-s" -o hits-s . && go build -ldflags="-s -w" -o hits-sw .'
on small 'go build -trimpath -o hits-trim . && go build -trimpath -ldflags="-s -w" -o hits-small .'
on small 'stat -c "%s bytes  %n" hits hits-w hits-s hits-sw hits-trim hits-small'
on small 'go doc cmd/link | grep -A2 "^    -s$"'
on small 'go build -ldflags="-s -w=0" -o hits-dwarf . && stat -c "%s bytes  %n" hits-dwarf'
on small 'file hits-small | cut -d, -f1,2,7'

block lose
on small 'go tool nm hits-small'
on small 'gdb -batch -ex "info line example.com/hits/internal/tally.Parse" ./hits 2>&1 | tail -1'
on small 'gdb -batch -ex "info line example.com/hits/internal/tally.Parse" ./hits-small 2>&1 | tail -1'
on small 'sleep 3 | timeout -s QUIT 1 ./hits-small count 2>&1 | grep -A1 -E "^(main|example)"'
on small 'sleep 3 | timeout -s QUIT 1 ./hits count 2>&1 | grep -A1 "^main.main"'
on small 'strings hits | grep -c /home/ana; strings hits-trim | grep -c /home/ana'
on small 'go version -m hits-small | head -3'

block git
place stamping-a-version .gitignore small
on_git small 2026-10-01T12:00:00Z 'git init -q && git add . && git commit -q -m "hits as lesson 1 left it" && git tag v1.0.0'
on small 'git log --oneline --decorate'
on small 'go build -o hits . && go version -m hits'

block version
place stamping-a-version version.go small
on small "sed -i '/case \"help\"/i\\\\tcase \"version\":\\n\\t\\treturn printVersion(stdout)' main.go"
on small 'git diff'
on small 'go build -o hits . && ./hits version'
on small 'go build -ldflags="-X main.version=v1.1.0" -o hits . && ./hits version'
on small 'go build -ldflags="-X main.Version=v1.1.0" -o hits . && ./hits version | head -1'
on_git small 2026-10-02T12:00:00Z 'git add . && git commit -q -m "hits version" && git tag v1.1.0'
on small 'go build -o hits . && ./hits version'

block archive
on small 'mkdir /tmp/small-v1.1.0 && git archive v1.1.0 | tar -x -C /tmp/small-v1.1.0'
on small 'cd /tmp/small-v1.1.0 && go build -o hits . && ./hits version'
on small 'cd /tmp/small-v1.1.0 && go build -ldflags="-X main.version=v1.1.0" -o hits . && ./hits version'

block release
on small 'git describe --tags'
on small 'go build -trimpath -ldflags="-s -w -X main.version=$(git describe --tags)" -o hits . && ./hits version'
on small 'stat -c "%s bytes  %n" hits'

block upx
on small 'upx --version | head -1'
on small 'upx --best -q -o hits-upx hits'
on small 'stat -c "%s bytes  %n" hits hits-upx'
on small './hits-upx top -n 2 access.log'
on small 'go version -m hits-upx; echo $?'
on small 'gzip -9 -c hits | wc -c; gzip -9 -c hits-upx | wc -c'
on small 'time (for i in $(seq 100); do ./hits version > /dev/null; done)'
on small 'time (for i in $(seq 100); do ./hits-upx version > /dev/null; done)'

block inline
on small 'go build -trimpath -gcflags=all=-l -ldflags="-s -w" -o hits-noinline . && stat -c "%s bytes  %n" hits hits-noinline'
on small 'go build -o hits-default . && go build -gcflags="all=-N -l" -o hits-debug . && stat -c "%s bytes  %n" hits-default hits-debug'
on small 'go run ./tools/genlog -n 1000000 > big.log; wc -l big.log'
on small 'time ./hits count big.log > /dev/null'
on small 'time ./hits-noinline count big.log > /dev/null'
quiet small 'rm big.log'

block sizes
lab fresh sizes
place beyond-the-flags none/main.go sizes
place beyond-the-flags fmtonly/main.go sizes
place beyond-the-flags withjson/main.go sizes
quiet sizes 'go mod init example.com/sizes'
on sizes 'for p in none fmtonly withjson; do go build -ldflags="-s -w" -o $p.bin ./$p; done'
on sizes 'stat -c "%s bytes  %n" none.bin fmtonly.bin withjson.bin'
on sizes 'for p in none fmtonly withjson; do echo "$(go list -deps ./$p | wc -l) $p"; done'

block podman
on small 'podman --version'
on small 'podman info --format "{{.Host.Security.Rootless}}"'
on small 'grep ana /etc/subuid /etc/subgid'
on small 'apt-cache depends podman | grep -E "uidmap|slirp4netns"'
on small 'podman run --rm --network=none docker.io/library/busybox:1.36 echo ok'
on small 'podman run --rm docker.io/library/busybox:1.36 echo ok; echo $?'
on small 'stat -c "%A %U %n" /dev/net/tun'
on small 'dpkg-query -W -f="\${Installed-Size} KB  \${Package} \${Version}\n" podman'
on small 'apt-cache show --no-all-versions docker.io containerd | grep -E "^(Package|Version|Installed-Size)"'

block subid
pkill -KILL -u ben >/dev/null 2>&1 || true
userdel -r ben >/dev/null 2>&1 || true
rm -rf /home/ben
useradd -m -s /bin/bash ben
sed -i '/^ben:/d' /etc/subuid /etc/subgid
ben 'grep ben /etc/subuid /etc/subgid; echo $?'
ben 'podman run --rm --network=none docker.io/library/busybox:1.36 echo ok 2>&1 | sed "s/^time=\"[^\"]*\" //"'
usermod --add-subuids 231072-296607 --add-subgids 231072-296607 ben
ben 'grep ben /etc/subuid /etc/subgid'
ben 'podman system migrate'
ben 'podman run --rm --network=none docker.io/library/busybox:1.36 echo ok 2>&1 | sed "s/^time=\"[^\"]*\" //"'
runuser -u ben -- env -i $BENENV bash -c 'podman system reset -f' >/dev/null 2>&1 || true
pkill -KILL -u ben >/dev/null 2>&1 || true
sleep 1
userdel -r ben >/dev/null 2>&1 || true
rm -rf /home/ben
sed -i '/^ben:/d' /etc/subuid /etc/subgid
