#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the start of lesson 8
# (lessons 1 to 7, one commit each, fixed dates), with no registry running:
# the lesson starts it on screen. The files the lesson has the student save
# are copied out of its own fences (`place`), the scratch ones too: count.jq
# and the two Dockerfiles of "what-it-reads".
#
# Trivy's database: the lab downloaded it once, on the day of the recording,
# and every scan here reads that one copy (TRIVY_SKIP_DB_UPDATE=true in ana's
# environment), so every count in the lesson comes from the same database.
# The download shown in "db" goes to a directory of its own, which the script
# deletes, so it does not replace that copy.
#
# What differs between runs: the commit hashes of the commits made on screen
# (they carry the time they were made), the image ids, the timings.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-zg3gy5bf
runh() { run "$(cat)"; } # the command from a heredoc, quotes and all
lab project 8 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
docker rm -f registry linkbox >/dev/null 2>&1
docker rmi -f blind:code blind:listed >/dev/null 2>&1

block db
run 'TRIVY_SKIP_DB_UPDATE=false trivy image --no-progress --cache-dir /tmp/trivy-db --download-db-only'
run 'trivy version --cache-dir /tmp/trivy-db'
quiet 'rm -rf /tmp/trivy-db'

block scans
run 'mkdir ~/scans && cd ~/scans'
run 'trivy image --quiet --format json -o full.json python:3.13'
run 'trivy image --quiet --format json -o slim.json python:3.13-slim'
run 'trivy image --quiet --format json -o distroless.json gcr.io/distroless/python3-debian13:nonroot'
place "$MD/what-it-reads.md" "~/scans/count.jq"

block reads
runh <<'EOF'
jq -r '.Results[] | "\(.Target)  \(.Packages | length) packages"' distroless.json
EOF
run "jq -r '.Results[].Packages[] | .AnalyzedBy' full.json | sort | uniq -c"

block bom
runh <<'EOF'
docker run --rm --entrypoint cat python:3.13-slim /usr/local/lib/python3.13/site-packages/pip/_vendor/bom.cdx.json | jq -r '.components[] | select(.name == "urllib3") | "\(.name) \(.version)"'
EOF

block blind
place "$MD/what-it-reads.md" "~/blind/Dockerfile.code"
place "$MD/what-it-reads.md" "~/blind/Dockerfile.listed"
run 'cd ~/blind'
run 'docker build -q -f Dockerfile.code -t blind:code . >/dev/null'
run 'docker build -q -f Dockerfile.listed -t blind:listed . >/dev/null'
run 'trivy image --quiet --format json blind:code | jq -r -f ~/scans/count.jq'
run 'trivy image --quiet --format json blind:listed | jq -r -f ~/scans/count.jq'
quiet 'cd ~ && rm -rf ~/blind && docker rmi -f blind:code blind:listed >/dev/null'

block counts
run 'cd ~/scans'
run 'for f in full slim distroless; do echo "== $f"; jq -r -f count.jq $f.json; done'
run 'docker images --format "{{.Repository}}:{{.Tag}}  {{.Size}}" | grep -E "^(python|gcr.io)"'

block fixable
runh <<'EOF'
jq -r '.Results[] | select(.Type == "python-pkg") | .Vulnerabilities[] | "\(.PkgName) \(.InstalledVersion) \(.Severity) fixed in \(.FixedVersion)"' slim.json
EOF
runh <<'EOF'
jq -r '.Results[] | select(.Type == "python-pkg") | .Packages[] | "\(.Name) \(.Version)  \(.FilePath)"' slim.json
EOF

block gate-bases
run 'for i in python:3.13 python:3.13-slim gcr.io/distroless/python3-debian13:nonroot; do trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --format json -o /dev/null $i; echo "$i: exit $?"; done'

block statuses
runh <<'EOF'
jq -r '[.Results[].Vulnerabilities[].Status] | group_by(.) | map("\(length) \(.[0])")[]' distroless.json
EOF
runh <<'EOF'
jq -r '.Results[].Vulnerabilities[] | select(.Status != "affected") | "\(.Status)  \(.PkgName)  \(.VulnerabilityID)  \(.Severity)"' distroless.json | sort | head -n 13
EOF

block duplicates
run 'jq "[.Results[].Vulnerabilities[].VulnerabilityID] | unique | length" distroless.json'
runh <<'EOF'
jq -r '.Results[].Vulnerabilities[] | select(.VulnerabilityID == "CVE-2024-26458") | "\(.PkgName) \(.InstalledVersion) \(.Status)"' distroless.json
EOF
runh <<'EOF'
jq -r '.Results[].Packages[] | select(.SrcName == "krb5") | "\(.Name) is built from \(.SrcName)"' distroless.json
EOF
runh <<'EOF'
jq -r '(.Results[0].Packages | map({(.Name): .SrcName}) | add) as $src | [.Results[0].Vulnerabilities[] | $src[.PkgName]] | group_by(.) | map("\(length) \(.[0])")[]' distroless.json | sort -rn
EOF

block build
run 'cd ~/linkbox'
place "$MD/two-stages.md" Dockerfile
run 'docker build -q -t linkbox:dev .'
run 'docker images --format "{{.Repository}}:{{.Tag}}  {{.Size}}" linkbox:dev'
run 'docker image inspect --format "{{.Config.User}}" linkbox:dev'

block inside
run 'docker run --rm --entrypoint sh linkbox:dev'
run 'docker run --rm --entrypoint python3 linkbox:dev -m pip --version'
run 'docker run --rm --entrypoint python3 linkbox:dev -c "import os; print(os.getuid(), os.getgid())"'

block runs
run 'docker run -d --name linkbox -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev'
quiet 'sleep 2'
run 'curl -s -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links'
run 'docker logs linkbox 2>&1 | head -n 4'
run 'docker rm -f linkbox'

block scan-linkbox
run 'trivy image --quiet --format json linkbox:dev | jq -r -f ~/scans/count.jq'

block registry
run 'docker run -d --restart=always -p 127.0.0.1:5000:5000 --name registry registry:3.1.2'
quiet 'sleep 2'
run 'curl -s http://localhost:5000/v2/_catalog'

block commit
for f in ci/image.sh ci/push.sh ci/stages; do
  place "$MD/in-the-pipeline.md" "$f"
done
run 'git add Dockerfile ci'
run 'git commit -q -m "a two-stage image on a distroless base, scanned and pushed to the registry"'
run 'git push ci main'

block after-run
run 'cat ~/ci/runs/1/logs/image.log'
run 'curl -s http://localhost:5000/v2/linkbox/tags/list'

block no-image
run 'CI_COMMIT=0000000 bash ci/image.sh; echo "exit $?"'

block old-base
run 'git switch -q -c old-base'
run 'git checkout main~1 -- Dockerfile'
run 'git commit -q -m "the single-stage image, to see what the gate says"'
runh <<'EOF'
git push ci old-base 2>&1 | grep -v '[│├└┌]'
EOF
runh <<'EOF'
trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed --format json linkbox:$(git rev-parse --short HEAD) | jq -r '.Results[].Vulnerabilities[]? | "\(.PkgName) \(.InstalledVersion)  \(.VulnerabilityID)  \(.Severity)  fixed in \(.FixedVersion)"'
EOF

block end
quiet 'git switch -q main'
docker rm -f linkbox >/dev/null 2>&1
docker rmi -f $(docker images -q linkbox) $(docker images -q localhost:5000/linkbox) >/dev/null 2>&1
docker image prune -f >/dev/null 2>&1
bash "$COURSE/lab.sh" as sh -c 'rm -rf ~/scans'
exit 0
