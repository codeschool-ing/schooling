# Dynamic analysis: the image this run built, started on a network of its
# own the way it runs everywhere, read-only and with no privileges, and ZAP's
# baseline scan against it from a second container. The scan only looks: it
# reads what the application answers and sends it nothing meant to break it.
# ZAP's own exit status is the verdict: a rule set to FAIL in
# ci/zap-rules.conf breaks the build, a WARN is a warning, and a scan that
# could not finish breaks the build too.
set -uo pipefail
net=linkbox-staging-$$
docker network create "$net" >/dev/null
trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
docker run -d --rm --name "$net-app" --network "$net" \
  --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 \
  --cap-drop ALL --security-opt no-new-privileges \
  -e LINKBOX_TOKEN="$(head -c 18 /dev/urandom | base64)" "linkbox:${CI_COMMIT:-dev}" >/dev/null
sleep 2
docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
  zap-baseline.py -t "http://$net-app:8000" -c zap-rules.conf -z -silent
case $? in
  0) exit 0 ;;
  2) exit 3 ;;
  *) exit 1 ;;
esac
