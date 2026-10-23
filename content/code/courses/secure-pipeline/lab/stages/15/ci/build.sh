# The image, built with no network. The wheels come first, each checked
# against its hash in requirements.txt; then the build, which can read only
# what this directory hands it.
set -euo pipefail
rm -rf wheels
uv venv -q --seed .build
.build/bin/pip download -q --no-deps --only-binary=:all: --require-hashes \
  -r requirements.txt -d wheels
docker build -q --network none -t "linkbox:${CI_COMMIT:-dev}" .
