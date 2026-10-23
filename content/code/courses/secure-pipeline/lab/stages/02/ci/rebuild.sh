# The image built from nothing. Every push reuses the layers already built,
# so a change that arrives without a commit, in the base image or in a
# package, never reaches it; this build has no cache to reuse.
set -euo pipefail
docker build -q --no-cache -t "linkbox:nightly" .
