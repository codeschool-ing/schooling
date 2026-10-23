# The image, tagged with the commit it was built from.
set -euo pipefail
docker build -q -t "linkbox:${CI_COMMIT:-dev}" .
