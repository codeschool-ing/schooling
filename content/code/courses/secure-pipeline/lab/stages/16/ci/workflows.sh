# The workflows and the bots' settings under .github, audited by zizmor with
# no network: what it can judge from the files alone. Any finding it reports
# breaks the build.
set -euo pipefail
zizmor --quiet --offline .github
