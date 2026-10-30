#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of gcp-operations.
#
#   bash captures.sh     # after lesson 1's captures, which leave ~/gcp/shop
#
# cosign is Sigstore's signing tool, run from its own image as the lesson
# defines it (the `cosign` function is read out of signing.md). It signs and
# verifies against the local registry of lesson 2. NOTHING HERE IS BINARY
# AUTHORIZATION: no policy is enforced, the lesson says so.
# STAGED: the key pair has an empty password (COSIGN_PASSWORD=), as the lesson
# says; transparency-log upload is off, and verification is run --offline,
# because the recording machine's containers have no route to Sigstore's
# servers. cosign prints a warning about that on stderr, which the lesson's
# command filters with grep and explains.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp/shop" || exit 1
docker rm -f registry > /dev/null 2>&1
rm -f cosign.key cosign.pub
from_lesson "$HERE/../le-01vpqvde/the-build.md" shop/api/app.py > api/app.py
docker run -d --rm --name registry -p 5000:5000 mirror.gcr.io/library/registry:3.0.0 > /dev/null
sleep 2
quiet 'docker build -q -t localhost:5000/shop/api:a1b2c3d api'
quiet 'docker push -q localhost:5000/shop/api:a1b2c3d'
# shellcheck disable=SC1090
. <(python3 - "$HERE/signing.md" <<'PY'
import re, sys
print(re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)[0])
PY
)
export COSIGN_PASSWORD=

block keys
run 'cosign generate-key-pair'
run 'ls cosign.*'
D=$(docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:a1b2c3d)

block sign
run "cosign sign --key cosign.key --tlog-upload=false --yes $D"
run 'curl -s localhost:5000/v2/shop/api/tags/list; echo'

block verify
run "cosign verify --key cosign.pub --insecure-ignore-tlog --offline $D 2>&1 | grep -v 'Could not fetch'"

block moved
sed -i 's|    {"id": "p-002", "name": "Pencil case", "price_cents": 1890},|&\n    {"id": "p-003", "name": "Eraser", "price_cents": 390},|' api/app.py
quiet 'docker build -q -t localhost:5000/shop/api:a1b2c3d api'
quiet 'docker push -q localhost:5000/shop/api:a1b2c3d'
run "cosign verify --key cosign.pub --insecure-ignore-tlog --offline localhost:5000/shop/api:a1b2c3d 2>&1 | grep -v 'Could not fetch'"
from_lesson "$HERE/../le-01vpqvde/the-build.md" shop/api/app.py > api/app.py
quiet 'docker rm -f registry'
