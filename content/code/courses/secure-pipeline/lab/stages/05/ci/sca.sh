# Composition analysis: every dependency the two requirements files pin,
# against the advisories PyPI publishes. A dependency with a known
# vulnerability breaks the build, and so does one pip-audit could not check.
set -euo pipefail
pip-audit --strict -r requirements.txt -r requirements-dev.txt
