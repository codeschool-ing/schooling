# The unit tests, in a fresh virtual environment with the pinned
# dependencies, each one checked against its hash before it is installed.
set -euo pipefail
uv venv -q .venv
uv pip install -q --require-hashes -r requirements.txt -r requirements-dev.txt
.venv/bin/python -m pytest -q
