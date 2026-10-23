#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the start of lesson 13
# (stages 1 to 10, since lessons 11 and 12 change no file) and the registry,
# empty, which is why the second block runs the pipeline on the laptop to put
# main's image in it. ci/sbom.sh and ci/stages are copied out of the lesson
# (`place`). ~/sbom is the lesson's scratch directory, deleted first.
# syft 1.54.1 was already in ~/.local/bin; the install on screen replaces it
# with the same release, checked against its published checksum.
# What differs between runs: the SBOMs' serial numbers, namespaces and
# timestamps, and the order of jq's output where a list is unordered.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-p32yjeec
lab project 13 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
bash "$COURSE/lab.sh" as sh -c 'rm -rf ~/sbom'

block install
run 'curl -fsSLO https://github.com/anchore/syft/releases/download/v1.54.1/syft_1.54.1_linux_amd64.tar.gz'
run 'curl -fsSL https://github.com/anchore/syft/releases/download/v1.54.1/syft_1.54.1_checksums.txt | grep " syft_1.54.1_linux_amd64.tar.gz$" | sha256sum --check'
run 'tar -xzf syft_1.54.1_linux_amd64.tar.gz syft'
run 'install -m 755 syft ~/.local/bin/ && rm syft syft_1.54.1_linux_amd64.tar.gz'
run 'syft --version'

block pipeline
run 'cd linkbox'
run 'CI_COMMIT=$(git rev-parse --short=7 HEAD) CI_BRANCH=main ci/pipeline.sh'

block table
run 'syft -q localhost:5000/linkbox:main | head -n 12'
run 'syft -q localhost:5000/linkbox:main | awk "\$NF == \"deb\"" | wc -l'
run 'syft -q localhost:5000/linkbox:main | grep " python "'

block both
run 'mkdir ~/sbom'
run 'syft -q localhost:5000/linkbox:main -o cyclonedx-json=$HOME/sbom/linkbox.cdx.json -o spdx-json=$HOME/sbom/linkbox.spdx.json'
run 'ls -l ~/sbom'

block cdx-top
run 'jq "del(.components, .dependencies) | .metadata |= {timestamp, component}" ~/sbom/linkbox.cdx.json'

block spdx-top
run 'jq "del(.packages, .files, .relationships, .hasExtractedLicensingInfos)" ~/sbom/linkbox.spdx.json'

block cdx-gunicorn
run 'jq ".components[] | select(.name == \"gunicorn\") | {type, name, version, licenses, purl}" ~/sbom/linkbox.cdx.json'

block spdx-gunicorn
run 'jq ".packages[] | select(.name == \"gunicorn\") | {name, SPDXID, versionInfo, supplier, licenseDeclared, purl: (.externalRefs[] | select(.referenceType == \"purl\") | .referenceLocator)}" ~/sbom/linkbox.spdx.json'

block counts
run 'jq ".components | length" ~/sbom/linkbox.cdx.json'
run 'jq "[.components[].type] | group_by(.) | map({(.[0]): length}) | add" ~/sbom/linkbox.cdx.json'
run 'jq ".packages | length" ~/sbom/linkbox.spdx.json'

block python
run 'jq -r ".components[] | select(.purl // \"\" | startswith(\"pkg:pypi/\")) | \"\(.name) \(.version)\"" ~/sbom/linkbox.cdx.json'

block licences
run 'jq -r ".components[] | select(.purl // \"\" | startswith(\"pkg:pypi/\")) | \"\(.name): \([.licenses[]? | .license.id // .license.name // .expression] | join(\", \"))\"" ~/sbom/linkbox.cdx.json'
run 'jq "[.components[] | .licenses[]? | .license.id // .license.name // .expression] | unique | length" ~/sbom/linkbox.cdx.json'

block packaging
run 'grep -c packaging requirements.txt'
run 'jq -r ".components[] | select(.name == \"packaging\") | .properties[] | select(.name | endswith(\":path\")) | .value" ~/sbom/linkbox.cdx.json'
run 'docker run --rm --entrypoint python3 localhost:5000/linkbox:main -c "from importlib.metadata import requires; print(requires(\"gunicorn\")[0])"'

block affected
run 'jq -r ".components[] | select(.name == \"glibc\" or (.purl // \"\" | contains(\"upstream=glibc\"))) | \"\(.name) \(.version)\"" ~/sbom/linkbox.cdx.json'

block trivy-image
run 'trivy image -q --format json localhost:5000/linkbox:main | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"'

block trivy-sbom
run 'trivy sbom --format json -o ~/sbom/scan.json ~/sbom/linkbox.cdx.json'
run 'jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]" ~/sbom/scan.json'

block why-zero
run 'jq -r ".components[] | select(.name == \"libc6\") | .purl" ~/sbom/linkbox.cdx.json'
run 'trivy image -q --format cyclonedx localhost:5000/linkbox:main | jq -r ".components[] | select(.name == \"libc6\") | .purl, (.properties[] | select(.name == \"aquasecurity:trivy:SrcName\") | .value)"'

block spdx-scan
run 'trivy sbom -q --format json ~/sbom/linkbox.spdx.json | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"'

block commit
place "$MD/in-the-pipeline.md" ci/sbom.sh
place "$MD/in-the-pipeline.md" ci/stages
run 'git add ci/sbom.sh ci/stages'
run 'git commit -q -m "a bill of materials for every image pushed"'

block push
run 'git push ci main'

block run-files
run 'ls ~/ci/runs/1/logs'
run 'jq ".components | length" ~/ci/runs/1/logs/sbom.cdx.json'

block across-runs
run 'for f in ~/ci/runs/*/logs/sbom.cdx.json; do jq -r --arg f "$f" ".components[] | select(.name == \"packaging\") | \"\(\$f): \(.name) \(.version)\"" "$f"; done'

block dir
run 'syft -q dir:. | head -n 14'

block end
quiet 'cd ~ && rm -rf ~/sbom'
exit 0
