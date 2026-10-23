#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the end of lesson 13 (one
# commit per lesson, fixed dates), the registry on localhost:5000, and the
# image of that last commit already built and pushed by the CI server, whose
# runs were then removed. The keys are made on screen. ci/sign.sh,
# ci/provenance.py, ci/stages and the two policies are copied out of the
# lesson's own fences (`place`), so what runs here is what the student saves.
#
# Sigstore's public services are out of this machine's reach, so every
# `cosign sign` and `cosign attest` prints a WARNING that the trust root could
# not be fetched from Sigstore's TUF repository; a machine with internet access
# fetches it and prints nothing of the kind. The digests, image ids, times and
# the commit of lesson 14 differ on every run.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1 and cosign 3.1.3, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-nxd0eyta
lab project 14 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }

block tags
run 'cd linkbox'
run 'git log --oneline -1'
run 'curl -s localhost:5000/v2/linkbox/tags/list | jq -c .tags'
run 'for tag in $(git rev-parse --short HEAD) main; do curl -sI -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/$tag | grep -i ^docker-content-digest; done'

block manifest-hash
run 'curl -s -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/main | sha256sum'
run 'curl -s -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/main | jq -c ".manifests[] | {digest, platform: .platform.architecture, type: .annotations.\"vnd.docker.reference.type\"}"'

block tag-moves
run 'printf "FROM localhost:5000/linkbox:main\nLABEL note=rebuilt\n" | docker build -q -t localhost:5000/linkbox:main -'
run 'docker push -q localhost:5000/linkbox:main'
run 'for tag in $(git rev-parse --short HEAD) main; do curl -sI -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/$tag | grep -i ^docker-content-digest; done'

block keys
run 'mkdir -p ~/ci/keys && cd ~/ci/keys'
run 'openssl rand -base64 24 > password && chmod 600 password'
run 'COSIGN_PASSWORD=$(cat password) cosign generate-key-pair'
run 'cosign signing-config create --out offline.json'
run 'jq . offline.json'
run 'ls -l'
run 'cd ~/linkbox'

block sign
run 'REF=$(docker inspect --format "{{range .RepoDigests}}{{println .}}{{end}}" localhost:5000/linkbox:$(git rev-parse --short HEAD) | grep ^localhost:5000/); echo $REF'
run 'export COSIGN_PASSWORD=$(cat ~/ci/keys/password)'
run 'cosign sign --yes --key ~/ci/keys/cosign.key --signing-config ~/ci/keys/offline.json $REF'
run 'unset COSIGN_PASSWORD'
run 'curl -s localhost:5000/v2/linkbox/tags/list | jq -c .tags'

block verify
run 'cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true $REF | jq .'

block moved
run 'cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true localhost:5000/linkbox:main; echo "exit status $?"'

run 'cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true localhost:5000/linkbox:$(git rev-parse --short HEAD) > /dev/null'

block other-key
run 'mkdir ~/other-key && cd ~/other-key && COSIGN_PASSWORD= cosign generate-key-pair && cd ~/linkbox'
run 'cosign verify --key ~/other-key/cosign.pub --insecure-ignore-tlog=true $REF; echo "exit status $?"'
quiet 'rm -rf ~/other-key'

block pipeline
place "$MD/in-the-pipeline.md" ci/sign.sh
place "$MD/in-the-pipeline.md" ci/provenance.py
place "$MD/in-the-pipeline.md" ci/stages
run 'git add ci'
run 'git commit -q -m "every pushed image signed, with its bill of materials and its provenance attested"'
run 'git push ci main'

block sign-log
run 'grep -v ^WARNING ~/ci/runs/1/logs/sign.log'

block tree
run 'REF=$(docker inspect --format "{{range .RepoDigests}}{{println .}}{{end}}" localhost:5000/linkbox:main | grep ^localhost:5000/); echo $REF'
run 'cosign tree $REF 2>/dev/null | grep -o "https://[^ ]*"'

block sbom-attestation
run 'cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type cyclonedx $REF > ~/sbom.att.json'
run 'jq -r .payload ~/sbom.att.json | base64 -d | jq -c "{_type, predicateType, subject}"'
run 'jq -r .payload ~/sbom.att.json | base64 -d | jq ".predicate.components | length"'
run 'jq ".components | length" ~/ci/runs/1/logs/sbom.cdx.json'

block provenance
run 'cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 $REF 2>/dev/null | jq -r .payload | base64 -d | jq .predicate'
run 'git rev-parse HEAD'

block policy
place "$MD/attestations.md" "~/deploy.cue"
place "$MD/attestations.md" "~/hosted.cue"
run 'cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 --policy ~/deploy.cue $REF > /dev/null'
run 'cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 --policy ~/hosted.cue $REF > /dev/null; echo "exit status $?"'

block deploy
run 'cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true $REF > /dev/null 2>&1 && docker pull -q $REF'

block end
quiet 'rm -f ~/sbom.att.json ~/deploy.cue ~/hosted.cue'
docker rmi -f $(docker images -q 'linkbox') $(docker images -q 'localhost:5000/linkbox') >/dev/null 2>&1
docker image prune -f >/dev/null 2>&1
exit 0
