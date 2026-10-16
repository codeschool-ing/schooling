#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: the preview's kustomization
# and release.yaml are copied out of the lesson's .md by `shown`; the keys, the
# signatures and the allowed-signers file are made by the commands the lesson
# shows. What is STAGED:
#   - the state at the end of lesson 7 (`lab.sh up`, `stage1`, `stage2`,
#     `stage4` to `stage7`);
#   - every pull request to fleet, through `lab.sh merge`, as in lesson 3;
#   - the chart 0.1.1 that nobody signed, published here the way lesson 7
#     publishes 0.1.0, so that Flux has something to refuse.
#
# Sigstore's public services are out of this machine's reach, so every
# `cosign sign` here prints a WARNING that it could not fetch the trust root
# from Sigstore's TUF repository; a machine with internet access fetches it
# and prints nothing of the kind. The signing itself uses only the key.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2, Flux 2.9.6 and cosign 3.1.3,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
lab up && lab stage1 && lab stage2 && lab stage4 && lab stage5 && lab stage6 && lab stage7 || exit 1
settle staging production
INDEX='Accept: application/vnd.oci.image.index.v1+json'
digest() { curl -sI -H "$INDEX" "localhost:5001/v2/$1/manifests/$2" | tr -d '\r' | awk 'tolower($1) == "docker-content-digest:" { print $2 }'; }
# The lessons install every tool into /usr/local/bin; the lab keeps its own
# copies in /opt/gitops/bin, first on the PATH, so the cosign the lesson
# downloads is moved aside after it is checked.
rm -f /usr/local/bin/cosign

block install
mkdir -p /home/ana/setup && cd /home/ana/setup
run 'ARCH=$(dpkg --print-architecture)'
run 'curl -fsSLO https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign-linux-$ARCH'
run 'curl -fsSL https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign_checksums.txt | grep " cosign-linux-$ARCH$" | sha256sum --check'
run 'sudo install -m 0755 cosign-linux-$ARCH /usr/local/bin/cosign && rm cosign-linux-$ARCH'
run 'cosign version | grep GitVersion'

block key-pair
rm -rf /home/ana/signing /home/ana/cosign.password
mkdir -p /home/ana/signing && cd /home/ana/signing
run 'openssl rand -base64 24 > ~/cosign.password && chmod 600 ~/cosign.password'
run 'export COSIGN_PASSWORD=$(cat ~/cosign.password)'
run 'cosign generate-key-pair'
run "stat -c '%A %n' cosign.key cosign.pub"
run 'cat cosign.pub'

block offline
run 'cosign signing-config create --out offline.json'
run 'jq . offline.json'

block sign
run 'DIGEST=$(curl -sI -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5001/v2/bulletin/manifests/1.2 | tr -d "\r" | awk "tolower(\$1) == \"docker-content-digest:\" { print \$2 }"); echo $DIGEST'
run 'cosign sign --key cosign.key --signing-config offline.json -y localhost:5001/bulletin@$DIGEST'
run 'curl -s localhost:5001/v2/bulletin/tags/list | jq -c .tags'

block verify
run 'cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin@$DIGEST | jq .'

block verify-tag
run 'cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin:1.2 > /dev/null'

block fail-unsigned
run 'cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin:1.1'

block fail-other-key
mkdir -p /tmp/other && cd /tmp/other
quiet 'COSIGN_PASSWORD= cosign generate-key-pair'
cd /home/ana/signing
run 'cosign verify --key /tmp/other/cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin@$DIGEST'
rm -rf /tmp/other

block provenance
run "docker buildx imagetools inspect localhost:5001/bulletin:1.2 --format '{{json .Provenance.SLSA}}' | jq '.buildDefinition.externalParameters.request.root.request.args'"
run 'git -C ~/bulletin rev-parse v1.2'

block sign-chart
run 'CHART=$(curl -sI -H "Accept: application/vnd.oci.image.manifest.v1+json" localhost:5001/v2/charts/bulletin/manifests/0.1.0 | tr -d "\r" | awk "tolower(\$1) == \"docker-content-digest:\" { print \$2 }"); echo $CHART'
run 'cosign sign --key cosign.key --signing-config offline.json -y localhost:5001/charts/bulletin@$CHART'

block flux-verify
cd /home/ana/fleet
run 'git switch --quiet -c preview-verify'
run 'cp ~/signing/cosign.pub apps/bulletin/preview/'
shown "$HERE/flux-verifies.md" 'apps/bulletin/preview/kustomization.yaml' apps/bulletin/preview/kustomization.yaml
shown "$HERE/flux-verifies.md" 'apps/bulletin/preview/release.yaml' apps/bulletin/preview/release.yaml
run "git diff | grep '^[-+] '"
at 2026-10-09T22:00:00-03:00 run 'git add apps && git commit --quiet -m "preview: only a signed chart"'
lab merge preview-verify "preview: only a signed chart" >/dev/null || exit 1
quiet 'flux reconcile kustomization preview --with-source'
for i in $(seq 60); do kubectl -n preview get ocirepository bulletin-chart -o jsonpath='{.status.conditions[?(@.type=="SourceVerified")].status}' 2>/dev/null | grep -q True && break; sleep 2; done
run 'flux get sources oci -n preview'
run "kubectl -n preview get ocirepository bulletin-chart -o jsonpath='{.status.conditions[?(@.type==\"SourceVerified\")].message}'; echo"

block fail-flux
cd /home/ana/fleet
quiet "sed -i 's/^version: 0.1.0$/version: 0.1.1/' charts/bulletin/Chart.yaml"
quiet 'helm package charts/bulletin && helm push bulletin-0.1.1.tgz oci://localhost:5001/charts --plain-http'
quiet 'rm -f bulletin-0.1.1.tgz && git checkout charts/bulletin/Chart.yaml'
run 'git switch --quiet -c preview-0.1.1'
quiet "sed -i 's/    tag: 0.1.0/    tag: 0.1.1/' apps/bulletin/preview/release.yaml"
run "git diff | grep '^[-+] '"
at 2026-10-09T22:10:00-03:00 run 'git commit --quiet -am "preview: chart 0.1.1"'
lab merge preview-0.1.1 "preview: chart 0.1.1" >/dev/null || exit 1
quiet 'flux reconcile kustomization preview --with-source'
for i in $(seq 60); do kubectl -n preview get ocirepository bulletin-chart -o jsonpath='{.status.conditions[?(@.type=="Ready")].reason}' 2>/dev/null | grep -qi verif && break; sleep 2; done
run 'flux get sources oci -n preview'
run 'helm list -n preview'

block ssh-key
cd /home/ana
quiet 'rm -f ~/.ssh/signing ~/.ssh/signing.pub ~/.ssh/allowed_signers; mkdir -p ~/.ssh && chmod 700 ~/.ssh'
run 'ssh-keygen -q -t ed25519 -N "" -C "ana@example.org" -f ~/.ssh/signing'
run 'git config --global gpg.format ssh'
run 'git config --global user.signingkey ~/.ssh/signing.pub'
run 'echo "ana@example.org $(cat ~/.ssh/signing.pub)" > ~/.ssh/allowed_signers'
run 'git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers'

block signed
cd /home/ana/fleet
run 'git switch --quiet -c preview-0.1.0'
quiet "sed -i 's/    tag: 0.1.1/    tag: 0.1.0/' apps/bulletin/preview/release.yaml"
at 2026-10-09T22:20:00-03:00 run 'git commit --quiet -S -am "preview: back to the signed chart"'
run 'git log --show-signature -2 --format="%h %an %s"'
lab merge preview-0.1.0 "preview: back to the signed chart" >/dev/null || exit 1

echo FINISHED
