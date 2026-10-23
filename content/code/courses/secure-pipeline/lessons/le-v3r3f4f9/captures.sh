#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the start of lesson 19
# (`lab project 19`: stages 1 to 18, the registry and the signing keys). Every
# file the lesson has the student save is copied out of the lesson's own
# fences (`place`), so what runs here is what the student saves.
#   - conftest 0.71.0 was already in ~/.local/bin, installed by the lab from the
#     same release; the "install" block downloads it again, checks it and
#     installs the same bytes over it.
#   - Trivy's checks bundle is fetched once, off screen, before the first
#     `trivy config` (a quiet run whose output is thrown away), so the blocks
#     show the findings and not a download.
# What differs between runs: the commit hashes, the run numbers and the
# timings of the pipeline's stages.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-v3r3f4f9
lab project 19 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }

block install
run 'curl -fsSLO https://github.com/open-policy-agent/conftest/releases/download/v0.71.0/conftest_0.71.0_Linux_x86_64.tar.gz'
run "curl -fsSL https://github.com/open-policy-agent/conftest/releases/download/v0.71.0/checksums.txt | grep ' conftest_0.71.0_Linux_x86_64.tar.gz\$' | sha256sum --check"
run 'tar -xzf conftest_0.71.0_Linux_x86_64.tar.gz conftest'
run 'install -m 755 conftest ~/.local/bin/'
run 'rm conftest conftest_0.71.0_Linux_x86_64.tar.gz'
run 'conftest --version'

block parse
run 'cd ~/linkbox'
run "conftest parse Dockerfile | jq -c '.[][] | select(.Cmd != \"comment\") | [.Stage, .Cmd, .Value]'"

block first-test
run 'mkdir policy'
place "$MD/rego.md" policy/docker.rego
run 'conftest test --no-color --namespace docker Dockerfile; echo "exit status $?"'

block base-user
run "docker image inspect --format '{{.Config.User}}' gcr.io/distroless/python3-debian13:nonroot"

block trivy-ds
quiet 'trivy config --quiet . >/dev/null 2>&1'
run "trivy config --quiet --format json Dockerfile | jq -r '.Results[].Misconfigurations[]? | \"\\(.ID) \\(.Severity) \\(.Title)\"'"

block fixed
place "$MD/rego.md" Dockerfile
run 'conftest test --no-color --namespace docker Dockerfile'

block k8s
place "$MD/manifests.md" policy/kubernetes.rego
run 'conftest test --no-color --namespace kubernetes k8s/'

block k8s-bad
run "sed -i 's/readOnlyRootFilesystem: true/readOnlyRootFilesystem: false/; s|localhost:5000/linkbox:main|linkbox:latest|' k8s/linkbox.yaml"
run 'git diff --unified=0 k8s/'
run 'conftest test --no-color --namespace kubernetes k8s/'

block k8s-restore
run 'git checkout k8s/linkbox.yaml'
run 'conftest test --no-color --namespace kubernetes k8s/'

block commit-policies
run 'git add Dockerfile policy'
run 'git commit -q -m "policy as code: the Dockerfile and the manifests"'

block verify
place "$MD/testing.md" policy/docker_test.rego
place "$MD/testing.md" policy/kubernetes_test.rego
run 'conftest verify --no-color'

block broken
run "sed -i 's/not contains(parts\\[count(parts) - 1\\], \":\")/not contains(image, \":\")/' policy/kubernetes.rego"
run 'git diff --unified=0 policy/'
run 'conftest test --no-color --namespace kubernetes k8s/'
run 'conftest verify --no-color'

block unbroken
run 'git checkout policy/kubernetes.rego'
run 'conftest verify --no-color'

block commit-tests
run 'git add policy'
run 'git commit -q -m "tests for the policies"'

block trivy
run "trivy config --quiet --format json . | jq -r '.Results[] | .Target as \$t | .Misconfigurations[]? | \"\\(\$t)  \\(.ID) \\(.Severity) \\(.Title)\"'"

block trivy-pass
run "trivy config --quiet --include-non-failures --format json k8s/linkbox.yaml | jq -r '.Results[].Misconfigurations[] | select(.Status == \"PASS\") | \"\\(.ID) \\(.Title)\"' | grep -E '^KSV-00(12|13|14|18) '"

block local
place "$MD/in-the-pipeline.md" ci/policy.sh
place "$MD/in-the-pipeline.md" ci/stages
run 'bash ci/policy.sh'

block push
run 'git add ci'
run 'git commit -q -m "the policies on every push"'
run 'git push ci main'

block weaken
run 'git switch -q -c debug-admission'
run "sed -i 's/validationActions: \\[\"Deny\"\\]/validationActions: [\"Warn\"]/' k8s/admission.yaml"
run 'git diff --unified=0'
run 'git commit -q -am "admission: warn while debugging"'
run 'git push ci debug-admission'

block discard
run 'git switch -q main'
run 'git branch -D debug-admission'

block end
quiet 'cd ~'
for t in $(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '^(localhost:5000/)?linkbox:'); do docker rmi -f "$t" >/dev/null 2>&1; done
docker image prune -f >/dev/null 2>&1
exit 0
