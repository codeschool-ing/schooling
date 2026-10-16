#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# IT BUILDS THE STUDENT'S LAB FROM THE LESSON ITSELF, into an empty home. The
# section "setting-up" is read out of its ```sh fences and run as it stands:
# fence 2 installs the AWS CLI, fence 3 moto, fence 4 writes ~/aws/env.sh,
# fence 5 is the line typed into every terminal and fence 6 starts moto. The
# first fence, apt-get, needs sudo and is not run: the script checks that its
# packages are installed and stops if one is missing. price.py is read out of
# the example in "crossing-costs". The lab this leaves behind is the one every
# other lesson's capture runs in.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - moto runs in the background with its output in a file, rather than in a
#     second terminal; the block `moto-terminal` prints that file under the
#     command that started it, which is what the first terminal shows;
#   - werkzeug colours two lines of moto's banner; the colour codes are removed,
#     which is what a terminal does with them on the screen;
#   - this lesson's moto is not seeded, since nothing here quotes an id it made.
#
# TWO COMMANDS REACH AWS ITSELF, on purpose and with no key: the block
# `failure-endpoint` sends moto's placeholder credentials to the real STS and
# quotes the refusal, and price.py downloads the public price list.
#
# NOT PRODUCED HERE, and said so in the prose: the missing python3-venv (the
# machine has the package and the failure needs it absent), and everything in
# "a-real-account", which needs an AWS account.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
SETUP="$HERE/setting-up.md"
SCRATCH=$(mktemp -d)

exec 9>"$LAB_ROOT/capture.lock"
flock 9
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_REGION \
  AWS_DEFAULT_REGION AWS_CONFIG_FILE AWS_SHARED_CREDENTIALS_FILE AWS_ENDPOINT_URL AWS_CA_BUNDLE
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
export PATH="${PYTHON3_DIR:+$PYTHON3_DIR:}/usr/local/bin:/usr/bin:/bin"
moto_stop
rm -rf "$LAB_HOME" && mkdir -p "$LAB_HOME" && export HOME=$LAB_HOME
cd "$HOME" || exit 1

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }
for p in python3 python3.12-venv curl jq unzip; do
  installed "$p" || { echo "install first, as in the first fence: $p"; exit 1; }
done

fence() {
  sh_fences "$SETUP" "$1" > "$SCRATCH/fence-$1.sh" || exit 1
  bash -e "$SCRATCH/fence-$1.sh" > "$SCRATCH/fence-$1.log" 2>&1 \
    || { echo "fence $1 of setting-up.md failed:"; cat "$SCRATCH/fence-$1.log"; exit 1; }
}

# ---- the lab, built by the section's own commands ---------------------------
fence 2          # the AWS CLI
fence 3          # moto
fence 4          # env.sh
cd ~/aws || exit 1

block failure-path
# a new terminal, which opens in the home directory and has not read env.sh
cd ~ && at '~'
run 'aws --version'
cd ~/aws && at '~/aws'

# shellcheck disable=SC1090
. <(sh_fences "$SETUP" 5)
cd ~/aws || exit 1

block failure-noserver
run 'aws sts get-caller-identity'

# fence 6, in the background: what the first terminal would show goes to a file
[ "$(sh_fences "$SETUP" 6)" = 'moto_server -p 4567' ] || { echo "fence 6 changed"; exit 1; }
setsid bash -c 'echo $$ > "$0/moto.pid"; exec moto_server -p 4567' "$LAB_ROOT" \
  </dev/null >"$SCRATCH/moto.log" 2>&1 &
for _ in $(seq 80); do curl -s -o /dev/null http://127.0.0.1:4567/moto-api/ && break; sleep 0.25; done
trap 'moto_stop; rm -rf "$SCRATCH"' EXIT
: > "$SCRATCH/moto.log.mark"; sleep 0.5; cp "$SCRATCH/moto.log" "$SCRATCH/banner.log"

block check
run 'aws --version'
run "python3 -c 'import moto; print(moto.__version__)'"
run 'aws sts get-caller-identity'
run 'aws configure list'
run 'cd ~ && du -sh aws .local/aws-cli'
run 'ps -C moto_server -o rss=,comm='

block moto-terminal
sleep 0.5
printf 'ana@laptop:~/aws$ moto_server -p 4567\n'
# the werkzeug banner, then one line for each request the block `check` sent
grep -v '/moto-api/' "$SCRATCH/moto.log" | sed 's/\x1b\[[0-9;]*m//g'

block failure-port
run 'timeout 10 moto_server -p 4567'

block failure-endpoint
run 'unset AWS_ENDPOINT_URL; aws sts get-caller-identity'

block regions
run 'aws ec2 describe-regions --query "length(Regions)"'
run 'aws ec2 describe-regions --query "Regions[?starts_with(RegionName, \`sa-\`) || starts_with(RegionName, \`us-east\`)].[RegionName,Endpoint]" --output text'
run 'aws ec2 describe-availability-zones --query "AvailabilityZones[].[ZoneName,ZoneId,ZoneType,State]" --output text'
run 'aws ec2 describe-availability-zones --region us-east-1 --query "AvailabilityZones[].[ZoneName,ZoneId]" --output text'

block local-zones
run 'aws ec2 describe-availability-zones --region us-west-2 --all-availability-zones --query "AvailabilityZones[].[ZoneName,ZoneType]" --output text'

# ---- the price list ---------------------------------------------------------
example "$HERE/crossing-costs.md" price.py > ~/aws/price.py || exit 1
rm -rf ~/.cache/aws-prices
block price-sa
run 'python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-DataTransfer-Regional-Bytes SAE1-USE1-AWS-Out-Bytes SAE1-DataTransfer-Out-Bytes SAE1-DataTransfer-In-Bytes'
block price-us
run 'python3 price.py AWSDataTransfer 20260916132208 us-east-1 USE1-SAE1-AWS-Out-Bytes DataTransfer-Out-Bytes'
run 'ls ~/.cache/aws-prices'
