# The pushed image, signed by digest, and two attestations about it, signed
# with the same key: its bill of materials and the provenance of this run.
# The key and its password belong to the CI server, in ~/ci/keys, and never
# to the repository.
set -euo pipefail
out=${CI_LOGS:-ci-logs}
keys=~/ci/keys
ref=$(docker inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' \
  "localhost:5000/linkbox:${CI_COMMIT:-dev}" | grep '^localhost:5000/')
python3 ci/provenance.py >"$out/provenance.json"
export COSIGN_PASSWORD
COSIGN_PASSWORD=$(cat "$keys/password")
sign() { cosign "$@" --yes --key "$keys/cosign.key" --signing-config "$keys/offline.json"; }
sign sign "$ref"
sign attest --type cyclonedx --predicate "$out/sbom.cdx.json" "$ref"
sign attest --type slsaprovenance1 --predicate "$out/provenance.json" "$ref"
echo "signed $ref"
