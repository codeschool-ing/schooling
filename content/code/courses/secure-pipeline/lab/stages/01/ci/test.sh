# The unit tests, in a fresh virtual environment with the pinned dependencies.
set -euo pipefail
uv venv -q .venv
uv pip install -q -r requirements.txt -r requirements-dev.txt
.venv/bin/python -m pytest -q
