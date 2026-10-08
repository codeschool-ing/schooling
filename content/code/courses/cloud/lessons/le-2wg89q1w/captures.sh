#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of cloud, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo useradd -m ana                       # a user whose home is empty
#   sudo -iu ana bash /path/to/captures.sh    # the lab, built from nothing
#   sudo -iu ana bash /path/to/captures.sh no-venv   # see below
#
# IT BUILDS THE STUDENT'S LAB FROM THE LESSON ITSELF. The commands of the section
# "setting-up" are read out of its ```sh fences and run as they stand, and
# prices.py is read out of the example in "the-price-sheet" (from-lessons.sh,
# beside course.json). So the setup a student follows is the very one recorded;
# an edit to either section changes what this script runs.
#
# The first fence, the apt-get one, needs sudo and is not run: the script checks
# that its packages are installed instead, and stops if one is missing.
#
# `no-venv` records the one failure that needs a machine in a different state:
# python3-venv NOT installed (sudo apt-get remove python3.12-venv python3-venv),
# which is how Ubuntu 24.04 ships. Run it on its own, then install the package
# again and run the script without the argument.
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE. prices.py reads the AWS public price
# list, with no account and no key, at the offer versions pinned inside it. The
# AWS CLI is installed and asked for its version; nothing calls AWS.
#
# What is STAGED rather than typed:
#   - for the block `lambda`, quoted in "this-course", the price cache already
#     filled, as the block `price-first` fills it;
#   - the AWS_* variables the recording machine's environment carried are
#     unset, so nothing of the author's reaches the student's tools;
#   - python3 is Ubuntu 24.04's own 3.12. The container this was recorded in
#     points `python3` at a newer one through `update-alternatives`, so
#     PYTHON3_DIR names a directory holding a `python3` link to python3.12 and
#     it goes first on the path. On a stock Ubuntu 24.04 leave it unset.
# The prompt is printed as ana@laptop:~/cloud$.
#
# One failure in "when-setup-fails" is quoted and not produced here, because it
# cannot be produced on purpose: the interrupted download. It happened on
# 2026-10-07 while the price cache for this script was first filled, and the
# section quotes the last line of that traceback and says so.
#
# Recorded 2026-10-07 on Ubuntu 24.04, as a user named ana with an empty home,
# no cloud account and no credentials, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_REGION AWS_DEFAULT_REGION
[ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
SETUP="$HERE/setting-up.md"

run() { printf 'ana@laptop:~/cloud$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
# A fence from setting-up.md, run as it stands; its own output is not quoted.
fence() {
  sh_fences "$SETUP" "$1" > "$SCRATCH/fence-$1.sh" || exit 1
  bash -e "$SCRATCH/fence-$1.sh" > "$SCRATCH/fence-$1.log" 2>&1 \
    || { echo "fence $1 of setting-up.md failed:"; cat "$SCRATCH/fence-$1.log"; exit 1; }
}

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

if [ "${1:-}" = no-venv ]; then
  installed python3.12-venv && { echo "python3.12-venv is installed: remove it first"; exit 1; }
  mkdir -p ~/cloud && cd ~/cloud || exit 1
  block failure-venv
  run 'python3 -m venv ~/cloud/venv'
  rm -rf ~/cloud
  exit 0
fi

[ -e ~/cloud ] && { echo "~/cloud exists: this records a lab built from nothing"; exit 1; }
for p in python3 python3-venv curl jq unzip git; do
  installed "$p" || { echo "install first, as in the first fence: $p"; exit 1; }
done

# ---- the lab, built by the section's own commands ---------------------------
fence 2          # the AWS CLI
fence 3          # the virtual environment, moto and cloud-init
cd ~/cloud || exit 1

block failure-path
# a new terminal in which the two lines of the fourth fence were not typed
run 'aws --version'

# shellcheck disable=SC1090
. <(sh_fences "$SETUP" 4)
block check
run 'aws --version'
run 'jq --version'
run 'python3 --version'
run 'moto_server --help | head -1'
run 'cloud-init schema --help | head -1'
run 'du -sh ~/cloud ~/.local/aws-cli'

block failure-port
moto_server -p 5000 > "$SCRATCH/first-moto.log" 2>&1 &
FIRST=$!
for _ in $(seq 40); do curl -s -o /dev/null http://127.0.0.1:5000/ && break; sleep 0.25; done
run 'timeout 10 moto_server -p 5000 2>&1 | tail -3'
kill "$FIRST" 2>/dev/null; wait "$FIRST" 2>/dev/null

# ---- the price sheet, out of the lesson -------------------------------------
prices_py ~/cloud
block price-first
run 'python3 prices.py lambda | tail -6'
run 'ls ~/.cache/cloud-prices'

block price-ec2
run 'time python3 prices.py ec2 | head -12'
run 'du -sh ~/.cache/cloud-prices'
run 'time python3 prices.py ec2 > /dev/null'

# Not quoted: the memory the sheet needs at its peak, which the section states.
block memory
python3 -c "
import resource, runpy, sys
sys.argv = ['prices.py', 'ec2']
sys.stdout = open('/dev/null', 'w')
runpy.run_path('prices.py', run_name='__main__')
print('peak resident memory, MB:', resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024, file=sys.stderr)
"

block lambda
run 'python3 prices.py lambda'
