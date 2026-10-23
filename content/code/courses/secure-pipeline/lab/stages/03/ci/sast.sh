# Static analysis: Semgrep with this project's own rules, then Bandit with
# its built-in ones. A finding of medium severity or worse breaks the build.
set -euo pipefail
semgrep scan --metrics=off --quiet --error --emacs --config .semgrep.yml .
bandit -q -r . -c bandit.yaml --severity-level medium
