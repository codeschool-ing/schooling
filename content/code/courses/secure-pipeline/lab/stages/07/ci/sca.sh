# Composition analysis: every dependency the two requirements files pin,
# against the advisories PyPI publishes, judged by ci/gate.py. If pip-audit
# produced no report at all, the gate has nothing to judge and the build
# breaks: a scanner that did not run is not a scanner that found nothing.
set -uo pipefail
pip-audit --strict -r requirements.txt -r requirements-dev.txt -f json -o audit.json
[ -s audit.json ] || exit 1
python3 ci/gate.py <audit.json
