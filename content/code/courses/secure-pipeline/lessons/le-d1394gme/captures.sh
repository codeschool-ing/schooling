#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the start of lesson 11
# (stages 1 to 10) and the registry, empty. The kind cluster of lesson 10 is
# made off-screen from ~/kind.yaml with k8s/linkbox.yaml applied, and
# deleted at the end; the scan reads the Deployment and its image, so
# whether the pod is running does not change what it reports. The scratch
# files the lesson shows (~/scratch/old/requirements.txt) are written on
# screen. Nessus, OpenVAS and Qualys are not run anywhere in this lesson.
# The container's id and the SBOM's serial number differ between runs.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
lab project 11 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
bash "$COURSE/lab.sh" as sh -c 'rm -rf ~/scratch; kind delete cluster --name linkbox' >/dev/null 2>&1

block pipeline
run 'cd linkbox'
run 'CI_COMMIT=$(git rev-parse --short=7 HEAD) CI_BRANCH=main ci/pipeline.sh'

block outside
run 'docker run -d --rm --name linkbox-scan -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=scan-only localhost:5000/linkbox:main'
quiet 'for i in $(seq 30); do curl -s -o /dev/null http://127.0.0.1:8000/ && break; sleep 1; done'
run 'curl -sI "http://127.0.0.1:8000/search?q=x"'
run 'docker rm -f linkbox-scan'

block inside
run 'trivy image -q --table-mode summary localhost:5000/linkbox:main'

block image-count
run 'trivy image -q --format json localhost:5000/linkbox:main | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"'

block rootfs
run 'mkdir -p ~/scratch/rootfs'
run 'docker create --name linkbox-rootfs localhost:5000/linkbox:main'
run 'docker export linkbox-rootfs | tar -xf - -C ~/scratch/rootfs'
run 'docker rm linkbox-rootfs'
run 'ls ~/scratch/rootfs'
run 'trivy rootfs -q --format json ~/scratch/rootfs | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"'

block sbom
run 'trivy image -q --format cyclonedx -o ~/scratch/linkbox.cdx.json localhost:5000/linkbox:main'
run 'trivy sbom -q --format json ~/scratch/linkbox.cdx.json | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"'

block fs
run 'trivy fs -q --table-mode summary .'

block k8s-setup
quiet 'kind create cluster --name linkbox --config ~/kind.yaml >/dev/null 2>&1'
quiet 'kubectl apply -f k8s/linkbox.yaml >/dev/null'
block k8s
run 'kubectl get deployments -n linkbox'
run 'trivy k8s -q --include-namespaces linkbox --report summary'
quiet 'kind delete cluster --name linkbox >/dev/null 2>&1'

block config
run 'trivy config -q --table-mode summary .'

block config-dockerfile
run 'trivy config -q Dockerfile'

block user
run 'docker inspect --format "{{.Config.User}}" localhost:5000/linkbox:main'
run 'tail -n 9 Dockerfile'

block config-k8s
run 'trivy config -q --severity MEDIUM k8s/'

block two-tools
run 'mkdir -p ~/scratch/old && cd ~/scratch/old'
run 'printf "gunicorn==21.2.0\n" > requirements.txt'
run 'trivy fs -q --format json . | jq -r ".Results[].Vulnerabilities[] | [.VulnerabilityID, .Severity, .FixedVersion] | @tsv"'
run 'pip-audit --aliases on -r requirements.txt'

block end
quiet 'cd ~ && rm -rf ~/scratch'
exit 0
