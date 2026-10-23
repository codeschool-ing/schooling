#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# IT BUILDS THE STUDENT'S LAB FROM THE LESSON ITSELF, into an empty home. The
# section "setting-up" is read out of its ```sh fences and run as it stands:
# fence 2 installs the AWS CLI, fence 3 moto, fence 4 writes ~/aws/env.sh,
# fence 5 is the line typed into every terminal and fence 6 starts moto. The
# first fence, apt-get, needs sudo and is not run: the script checks that its
# packages are installed and stops if one is missing. appointments.csv is
# written by the first ```sh fence of "one-call-away". The lab this leaves
# behind is the one every other lesson's capture runs in.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - moto runs in the background with its output in a file, rather than in a
#     second terminal; the blocks that start `moto_server -p 4567` print that
#     file under the command that started it, which is what the first terminal
#     shows. Lines for /moto-api/, the control address the script uses to wait
#     for moto and to seed it, are left out: a student's terminal has none;
#   - werkzeug colours two lines of moto's banner; the colour codes are removed,
#     which is what a terminal does with them on the screen;
#   - the moto of "setting-up" is not seeded, since nothing quoted there names
#     an id it made; the one of "one-call-away" is.
#
# ONE COMMAND REACHES AWS ITSELF, on purpose and with no key: the block
# `failure-endpoint` sends moto's placeholder credentials to the real STS and
# quotes the refusal.
#
# NOT PRODUCED HERE, and said so in the prose: the missing python3-venv (the
# machine has the package and the failure needs it absent), the wrong-processor
# installer, and Multipass.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
SETUP="$HERE/setting-up.md"
SCRATCH=$(mktemp -d)
mkdir -p "$LAB_ROOT"

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

moto_terminal() { # what the first terminal shows: the banner and one line a request
  sleep 0.5
  printf 'ana@laptop:~/aws$ moto_server -p 4567\n'
  grep -v '/moto-api/' "$LAB_ROOT/moto.log" | sed 's/\x1b\[[0-9;]*m//g'
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
  </dev/null >"$LAB_ROOT/moto.log" 2>&1 &
for _ in $(seq 80); do curl -s -o /dev/null http://127.0.0.1:4567/moto-api/ && break; sleep 0.25; done
trap 'moto_stop; rm -rf "$SCRATCH"' EXIT

block check
run 'aws --version'
run "python3 -c 'import moto; print(moto.__version__)'"
run 'aws sts get-caller-identity'
run 'cd ~ && du -sh aws .local/aws-cli'

block moto-terminal
moto_terminal

block failure-port
run 'timeout 10 moto_server -p 4567'

block failure-endpoint
run 'unset AWS_ENDPOINT_URL; aws sts get-caller-identity'

# ---- one-call-away -----------------------------------------------------------
moto_fresh

block defaults
run 'aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text'
run 'aws ec2 describe-security-groups --query "SecurityGroups[].[GroupId,GroupName]" --output text'
run 'aws ec2 describe-regions --query "length(Regions)"'
run 'for r in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do aws ec2 describe-vpcs --region "$r" --query "Vpcs[?IsDefault].VpcId" --output text; done | wc -l'

# Ctrl+C and start again, as the prose asks
moto_fresh
trap 'moto_stop; rm -rf "$SCRATCH"; rm -f ~/aws/appointments.csv' EXIT
bash -e <(sh_fences "$HERE/one-call-away.md" 1) || exit 1

block bucket
run 'aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3 cp --no-progress appointments.csv s3://clinic-exports/2026-10-23.csv'

block anonymous
run 'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-exports/2026-10-23.csv'

block public
run "aws s3api put-bucket-policy --bucket clinic-exports --policy '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::clinic-exports/*\"}]}'"
run 'curl -s -w "%{http_code}\n" http://localhost:4567/clinic-exports/2026-10-23.csv'

block moto-terminal-2
moto_terminal

block fix
run 'aws s3api delete-bucket-policy --bucket clinic-exports'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-exports/2026-10-23.csv'
