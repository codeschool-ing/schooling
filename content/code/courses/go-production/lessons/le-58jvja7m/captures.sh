#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# the lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - THE VULNERABILITY DATABASE. This sandbox cannot reach vuln.go.dev, so
#     block db builds a copy of the same database in ~ana/vulndb, and every
#     govulncheck in the lesson is given `-db file:///home/ana/vulndb`. The
#     copy is built from the module golang.org/x/vulndb at
#       v0.0.0-20261011002159-d5e0cfac5d26
#     (commit d5e0cfac5d26, 2026-10-11), fetched through the module proxy and
#     checked against the checksum database like any module. Its data/osv
#     directory holds the OSV entries vuln.go.dev serves, and its own command
#     cmd/indexdb writes them out in the layout the -db flag expects (index/
#     and ID/). One difference, visible in the JSON of block reports: the
#     entries in the repository carry no dates, because the published database
#     takes them from the repository's git history, so db_last_modified is
#     0001-01-01. The lesson says the lab used a local copy and why, once.
#   - the files of ~/langs, placed from section reachable-or-not, and of
#     ~/vuln-hits, placed from lesson 1 (le-03nqvqms).
#   - `go mod init` in ~/vuln-hits, which lesson 1 shows.
# The timings in block scan are real and vary from run to run.
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
DB='-db file:///home/ana/vulndb'

block db
VULNDB=golang.org/x/vulndb@v0.0.0-20261011002159-d5e0cfac5d26
WORK=$(mktemp -d)
src=$(cd "$WORK" && go mod download -json "$VULNDB" | python3 -c 'import json,sys; print(json.load(sys.stdin)["Dir"])')
(cd "$WORK" && GOTOOLCHAIN=local go run "golang.org/x/vulndb/cmd/indexdb@${VULNDB#*@}" -vulns "$src/data/osv" -out "$WORK/db") >/dev/null 2>&1
lab fresh vulndb
cp -r "$WORK/db/." /home/ana/vulndb/
chown -R ana:ana /home/ana/vulndb
rm -rf "$WORK"
ls /home/ana/vulndb /home/ana/vulndb/index
ls /home/ana/vulndb/ID | grep -c '\.json$'

block install
lab fresh langs
on langs 'go install golang.org/x/vuln/cmd/govulncheck@v1.9.0'
on langs 'govulncheck -version'

block entry
on langs "jq '{id, aliases, summary, affected}' ~/vulndb/ID/GO-2022-1059.json"

block setup
place reachable-or-not accept/main.go langs
place reachable-or-not tag/main.go langs
on langs 'go mod init example.com/langs'
on langs 'go get golang.org/x/text@v0.3.7'
on langs 'go mod tidy && cat go.mod'
on langs 'go run ./accept "pt-BR,pt;q=0.9,en;q=0.5"'
on langs 'go run ./tag EN-us'

block scan
on langs "time govulncheck $DB ./accept; echo \$?"
on langs "govulncheck $DB ./tag; echo \$?"

block traces
on langs "govulncheck $DB -show traces ./accept"

block verbose
on langs "govulncheck $DB -show verbose ./tag | head -n 42"
on langs "govulncheck $DB -show verbose ./tag | grep -c '^Vulnerability #'"

block levels
on langs "govulncheck $DB -scan package ./tag | tail -n 5; echo \${PIPESTATUS[0]}"
lab fresh vuln-hits
lab place le-03nqvqms arguments tools/genlog/main.go vuln-hits >/dev/null
lab place le-03nqvqms subcommands internal/tally/tally.go vuln-hits >/dev/null
lab place le-03nqvqms subcommands main.go vuln-hits >/dev/null
quiet vuln-hits 'go mod init example.com/hits'
on vuln-hits "govulncheck $DB ./... | tail -n 5; echo \${PIPESTATUS[0]}"
on vuln-hits "govulncheck $DB -scan module | tail -n 4; echo \${PIPESTATUS[0]}"

block binary
on langs 'go build -o accept-bin ./accept && go build -o tag-bin ./tag'
on langs 'go version -m accept-bin | head -n 4'
on langs "govulncheck $DB -mode binary accept-bin; echo \$?"
on langs "govulncheck $DB -mode binary tag-bin | tail -n 6; echo \${PIPESTATUS[0]}"

block stripped
on langs 'go build -ldflags="-s -w" -o accept-small ./accept && stat -c "%s bytes  %n" accept-bin accept-small'
on langs "govulncheck $DB -mode binary accept-small | tail -n 4; echo \${PIPESTATUS[0]}"
on langs "govulncheck $DB -mode binary accept-small | grep -c '^Vulnerability #'"

block reports
on langs "govulncheck $DB -format json ./accept > scan.json; echo \$?"
on langs "jq -r 'keys[0]' scan.json | sort | uniq -c"
on langs "jq -c 'select(.finding.trace[0].function) | .finding | {osv, fixed_version, trace: [.trace[].function]}' scan.json"
on langs "jq -c 'select(.config) | .config | {scan_level, scan_mode, go_version}' scan.json"
on langs "govulncheck $DB -format sarif ./accept > scan.sarif; echo \$?"
on langs "jq -r '.runs[0].results[].level' scan.sarif | sort | uniq -c"
on langs "jq '.runs[0].results[] | select(.level == \"error\") | .message.text' scan.sarif"

block fix
on langs 'go mod why -m golang.org/x/text'
on langs 'go list -m -u golang.org/x/text'
on langs 'go get golang.org/x/text@v0.3.8'
on langs "govulncheck $DB ./...; echo \$?"
on langs 'go get golang.org/x/text@latest && go mod tidy && cat go.mod'
on langs "govulncheck $DB ./...; echo \$?"
on langs "go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 $DB ./... | tail -n 5; echo \${PIPESTATUS[0]}"
on langs "govulncheck $DB -mode binary accept-bin | grep -E 'Found in|Your code'; echo \${PIPESTATUS[0]}"
on langs 'go build -o accept-bin ./accept'
on langs "govulncheck $DB -mode binary accept-bin | grep 'Your code'; echo \${PIPESTATUS[0]}"

block stdlib
on vuln-hits "govulncheck $DB -show verbose ./... | grep 'Fixed in' | sort | uniq -c"
on vuln-hits 'GOTOOLCHAIN=go1.27.2 go version'
on vuln-hits "GOTOOLCHAIN=go1.27.2 govulncheck $DB ./...; echo \$?"
on langs "GOTOOLCHAIN=go1.27.2 govulncheck $DB ./...; echo \$?"
