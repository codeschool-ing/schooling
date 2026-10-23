# Secret scanning: every commit the repository holds, not only the files as
# they are now, because a secret deleted in a later commit is still in the
# history. A finding breaks the build. .gitleaksignore lists the findings
# that were rotated and are dead.
set -euo pipefail
gitleaks git --no-banner --no-color --redact --verbose .
