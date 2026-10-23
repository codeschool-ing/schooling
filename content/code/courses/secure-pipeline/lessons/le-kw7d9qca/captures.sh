#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the end of lesson 4
# (four commits with fixed dates, and a CI server with no runs yet). Every
# file the lesson changes is copied out of the lesson's own fences (`place`),
# so what runs here is what the student saves. The scratch files the lesson
# writes (/tmp/audit.json, /tmp/cves.txt, /tmp/one) are written by commands
# shown on screen.
#
# The advisories come from PyPI and the KEV catalogue from CISA's repository
# on GitHub, both on the day of the recording; Trivy reads the database the
# lab downloaded that same day. A later run finds more advisories, never the
# same list. Stage timings and commit hashes differ on every run.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-kw7d9qca
lab project 5 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }

block tree
run 'cd linkbox'
run 'uv venv -q && uv pip install -q -r requirements.txt -r requirements-dev.txt'
run 'uv pip tree'

block audit
run 'pip-audit --version'
run 'pip-audit -r requirements.txt; echo "exit status $?"'

block pypi
run 'curl -s https://pypi.org/pypi/flask/3.0.0/json | jq ".vulnerabilities[] | {id, aliases, fixed_in, source}"'

block count
run 'pip-audit -r requirements.txt -f json -o /tmp/audit.json'
run 'jq "[.dependencies[].vulns[]] | length" /tmp/audit.json'
run 'jq -r "[.dependencies[].vulns[].aliases[] | select(startswith(\"CVE-\"))] | unique[]" /tmp/audit.json > /tmp/cves.txt'
run 'wc -l < /tmp/cves.txt'

block flask
run 'jq -r ".dependencies[] | select(.name == \"flask\") | .vulns[0].description" /tmp/audit.json'

block kev
run 'curl -sSfo /tmp/kev.json https://raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json'
run 'jq -r ".catalogVersion, .count" /tmp/kev.json'
run 'jq -r ".vulnerabilities[].cveID" /tmp/kev.json | grep -cxFf /tmp/cves.txt'

block cvss
run 'trivy fs -q --scanners vuln -f json requirements.txt > /tmp/trivy.json'
run 'jq ".Results[].Vulnerabilities[] | select(.VulnerabilityID == \"CVE-2024-1135\") | {Severity, CVSS}" /tmp/trivy.json'

block trivy
run 'jq -r ".Results[].Vulnerabilities[] | [.PkgName, .InstalledVersion, .VulnerabilityID, .Severity, .FixedVersion] | @tsv" /tmp/trivy.json'
run 'trivy fs -q --scanners vuln requirements-dev.txt'

block one
run 'mkdir -p /tmp/one && echo "flask==3.0.0" > /tmp/one/requirements.txt'
run 'pip-audit -r /tmp/one/requirements.txt -f json 2>/dev/null | jq -r ".dependencies[] | \"\(.name) \(.version)\""'
run 'trivy fs -q --scanners vuln --list-all-pkgs -f json /tmp/one | jq -r ".Results[].Packages[] | \"\(.Name) \(.Version)\""'

block move
run 'sed -i -e "s/^flask==.*/flask==3.1.3/" -e "s/^werkzeug==.*/werkzeug==3.1.9/" -e "s/^jinja2==.*/jinja2==3.1.6/" -e "s/^gunicorn==.*/gunicorn==22.0.0/" requirements.txt'
run 'curl -s https://pypi.org/pypi/flask/3.1.3/json | jq -r ".info.requires_dist[]"'

block moved
place "$MD/the-move.md" requirements.txt
run 'git diff requirements.txt'
run 'uv pip install -q -r requirements.txt -r requirements-dev.txt'
run '.venv/bin/python -m pytest -q'
run 'pip-audit -r requirements.txt; echo "exit status $?"'

block pipeline
place "$MD/the-move.md" ci/sca.sh
place "$MD/the-move.md" ci/stages
run 'git add requirements.txt ci'
run 'git commit -q -m "dependencies moved past their advisories, and composition analysis in the pipeline"'
run 'git push ci main'

block pytest-desc
run 'pip-audit -r requirements-dev.txt -f json 2>/dev/null | jq -r ".dependencies[] | select(.name == \"pytest\") | .vulns[0].description"'

block dev
place "$MD/the-move.md" requirements-dev.txt
run 'uv pip install -q -r requirements-dev.txt && .venv/bin/python -m pytest -q'
run 'git commit -qam "pytest moved past its advisory"'
run 'git push ci main'

block end
quiet 'rm -rf /tmp/audit.json /tmp/cves.txt /tmp/kev.json /tmp/trivy.json /tmp/one'
docker rmi -f $(docker images -q linkbox) >/dev/null 2>&1
docker image prune -f >/dev/null 2>&1
exit 0
