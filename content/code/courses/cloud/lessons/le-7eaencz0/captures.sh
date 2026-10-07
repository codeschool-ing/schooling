#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of cloud, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, block by block.
#
#   AWS_CLI=/path/to/aws CLOUD_INIT=/path/to/cloud-init bash captures.sh
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE, and nothing below reaches one.
#
# - prices.py (read out of lesson 1, which prints it) reads the AWS public price list, which AWS
#   publishes as JSON with no account and no key, at the offer versions pinned
#   inside it. Nothing here is a bill.
# - The AWS CLI v2 runs with an EMPTY environment and an empty home directory, so
#   it has no credentials, no configuration and no region of its own. What it
#   prints here it prints from the laptop: its version, the skeleton of a
#   request, and the refusal of a call it cannot sign. AWS_EC2_METADATA_DISABLED
#   is set so that it does not even look for credentials on the local network.
# - cloud-init is not packaged for pip. It is run from its own source tree
#   (canonical/cloud-init, tag 26.2, commit 525e9cc) through a two-line wrapper
#   called cloud-init on the PATH, in a virtualenv holding its dependencies. It
#   only VALIDATES the file against its schema: nothing was booted.
# - estimate.py and web.yaml are written by this script, from the same text the
#   lesson prints.
#
# What is STAGED rather than typed, and not shown in the lesson: the price cache,
# filled by an earlier run of prices.py; the wrapper and the virtualenv above;
# and the working directory, shown as ~/cloud.
#
# Recorded 2026-09-28 on Ubuntu 24.04, Python 3.11, no cloud account and no
# credentials, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
COURSE=$(cd "$(dirname "$0")/../.." && pwd)
WORK=$(mktemp -d)
. "$(cd "$(dirname "$0")/../.." && pwd)/from-lessons.sh"   # prices_py: the program as lesson 1 prints it
prices_py "$WORK" || exit 1
cd "$WORK" || exit 1
BIN=$(mktemp -d)
trap 'rm -rf "$WORK" "$BIN"' EXIT
ln -s "${AWS_CLI:?set AWS_CLI to the aws binary}" "$BIN/aws"
ln -s "${CLOUD_INIT:?set CLOUD_INIT to a cloud-init command}" "$BIN/cloud-init"
# What ana typed at her prompt, and everything it printed.
run() { printf 'ana@laptop:~/cloud$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
# The same for the two tools that talk about clouds. The environment is emptied
# and the home directory is a fresh one, so nothing of the machine that runs
# this, credentials least of all, reaches them.
bare() {
  printf 'ana@laptop:~/cloud$ %s\n' "$*"
  env -i HOME="$(mktemp -d)" PATH="$BIN:/usr/bin:/bin" LC_ALL=C.UTF-8 \
    AWS_EC2_METADATA_DISABLED=true bash -c "$*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

cat > estimate.py <<'PY'
HOURS_PER_MONTH = 8760 / 12        # 365 days x 24 hours, over 12 months

# sa-east-1, Linux, on demand, USD per hour, from prices.py
per_hour = {
    "m7i.large": 0.16065,
    "m7i.xlarge": 0.32130,
    "m7g.large": 0.13010,
}

for name, price in per_hour.items():
    month = price * HOURS_PER_MONTH
    print(f"{name:10}  {price:.5f} x {HOURS_PER_MONTH:.0f} h = {month:6.2f} USD")
PY

cat > web.yaml <<'YAML'
#cloud-config
package_update: true
packages:
  - nginx

users:
  - default
  - name: ana
    groups: [sudo]
    shell: /bin/bash
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoLEfVeFZ0GWJ/mCzAhS1R8EN1CAw6s4HI4sjd7Yuay ana@laptop

write_files:
  - path: /var/www/html/index.html
    content: |
      <h1>served by HOST</h1>
    permissions: "0644"
    defer: true

runcmd:
  - sed -i "s/HOST/$(hostname)/" /var/www/html/index.html
YAML
sed 's/ssh_authorized_keys/ssh_authorised_keys/' web.yaml > typo.yaml

block sheet
run 'python3 prices.py ec2 | sed -n 1,17p'

block estimate
run 'python3 estimate.py'

block reserved
run "python3 prices.py ec2 | grep -E 'sa-east-1|on demand|reserved|m7i.large'"

block cli
bare 'aws --version'
bare 'aws ec2 run-instances --generate-cli-skeleton | jq "keys | length"'
bare 'aws ec2 run-instances --generate-cli-skeleton | jq "{ImageId, InstanceType, SubnetId, SecurityGroupIds, KeyName, UserData}"'
bare 'aws ec2 describe-instances --region sa-east-1'

block cloud-init
bare 'cloud-init schema -c web.yaml'
bare 'cloud-init schema -c typo.yaml 2>&1 | cut -c1-120'
