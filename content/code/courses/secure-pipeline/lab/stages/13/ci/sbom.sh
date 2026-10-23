# The bill of materials of the image this run pushed, in CycloneDX and in
# SPDX, kept beside the run's logs.
set -euo pipefail
out=${CI_LOGS:-ci-logs}
syft -q "localhost:5000/linkbox:${CI_COMMIT:-dev}" \
  -o cyclonedx-json="$out/sbom.cdx.json" -o spdx-json="$out/sbom.spdx.json"
