# Static analysis. A finding of medium severity or worse breaks the build,
# and a low one is a warning.
set -uo pipefail
semgrep scan --metrics=off --quiet --error --emacs --config .semgrep.yml . || exit 1
bandit -q -r . -c bandit.yaml --severity-level medium || exit 1
bandit -q -r . -c bandit.yaml --severity-level low || exit 3
