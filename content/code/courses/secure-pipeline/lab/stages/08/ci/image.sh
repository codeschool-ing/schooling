# The image this run built, scanned before it goes anywhere. A high or
# critical vulnerability that already has a fixed version breaks the build.
# The rest, which no rebuild can fix yet, is counted in the log for whoever
# reviews the base image.
set -uo pipefail
image=linkbox:${CI_COMMIT:-dev}
trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 "$image" || exit 1
echo "everything else, fixed or not:"
trivy image --quiet "$image" | grep '^Total'
exit 0
