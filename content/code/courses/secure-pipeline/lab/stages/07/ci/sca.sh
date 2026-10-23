# Composition analysis: every dependency the two requirements files pin,
# against the advisories PyPI publishes, judged by ci/gate.py. If pip-audit
# produced no report at all, the gate has nothing to judge and the build
# breaks: a scanner that did not run is not a scanner that found nothing.
# The report goes to a file made empty for this run, so a report left over
# from an earlier run can never stand in for one that was not written.
set -uo pipefail
report=$(mktemp)
trap 'rm -f "$report"' EXIT
pip-audit --strict -r requirements.txt -r requirements-dev.txt -f json -o "$report"
[ -s "$report" ] || exit 1
python3 ci/gate.py <"$report"
