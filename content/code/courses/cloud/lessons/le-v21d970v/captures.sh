#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of cloud, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   bash captures.sh            # from anywhere; prices.py is read out of lesson 1
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE, and nothing below reaches one. The
# address arithmetic is Python's own ipaddress module on a laptop: it knows what
# 10.0.0.0/16 means and nothing about any provider. prices.py reads the AWS public
# price list at the offer versions pinned inside it, from the cache in
# ~/.cache/cloud-prices. The AWS CLI is only asked for a skeleton, which it
# prints from its own model of the API without a network call; it runs with an
# empty environment and an empty home, so no credentials of any kind can reach it.
#
# What is STAGED rather than typed, and not shown in the lesson: the price cache,
# already filled by an earlier run of prices.py, and the AWS CLI v2 installed
# where AWS_CLI points. The prompt shows the course directory as ~/cloud, which
# is where a student would keep prices.py.
#
# Recorded 2026-09-28 on Ubuntu 24.04, Python 3.11, aws-cli 2.37.4, no cloud
# account and no credentials, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
. "$(cd "$(dirname "$0")/../.." && pwd)/from-lessons.sh"   # prices_py: the program as lesson 1 prints it
SHEET=$(mktemp -d)   # the student's ~/cloud, holding prices.py
trap 'rm -rf "$SHEET"' EXIT
prices_py "$SHEET" || exit 1
cd "$SHEET" || exit 1
AWS_CLI=${AWS_CLI:-$(command -v aws)}
# what ana typed at her prompt, and everything it printed
run() { printf 'ana@laptop:~/cloud$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
# the same for the AWS CLI, run with nothing of this machine's environment
awsrun() {
  printf 'ana@laptop:~/cloud$ aws %s\n' "$*"
  env -i HOME="$(mktemp -d)" PATH="$(dirname "$AWS_CLI"):/usr/bin:/bin" \
    bash -c "aws $*" 2>&1 || true
}
block() { printf '##### %s\n' "$1"; }

block cidr-size
run "python3 -c \"print(2**(32-16), 2**(32-20), 2**(32-24))\""
run "python3 -c \"import ipaddress; print(ipaddress.ip_network('10.0.0.0/16').num_addresses)\""

block cidr-carve
run "python3 -c \"import ipaddress, itertools; vpc = ipaddress.ip_network('10.0.0.0/16'); print(*itertools.islice(vpc.subnets(new_prefix=20), 4), sep='\\n')\""
run "python3 -c \"import ipaddress; print(len(list(ipaddress.ip_network('10.0.0.0/16').subnets(new_prefix=20))))\""
run "python3 -c \"import ipaddress; print(ipaddress.ip_address('10.0.17.5') in ipaddress.ip_network('10.0.16.0/20'))\""

block hostbits
run "python3 -c \"import ipaddress; ipaddress.ip_network('10.0.8.0/20')\" 2>&1 | tail -1"

block ranges
run "python3 -c \"import ipaddress; [print(n, n[0], n[-1], n.num_addresses) for n in map(ipaddress.ip_network, ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'])]\""

block overlap
run "python3 -c \"import ipaddress; vpc = ipaddress.ip_network('10.0.0.0/16'); print(vpc.overlaps(ipaddress.ip_network('10.0.128.0/24')), vpc.overlaps(ipaddress.ip_network('10.1.0.0/16')))\""

block reserved
run "python3 -c \"import ipaddress; s = ipaddress.ip_network('10.0.1.0/24'); print(s[0], s[1], s[2], s[3], s[-1]); print(s.num_addresses - 5)\""
run "python3 -c \"print(2**(32-28) - 5)\""

block ipv4
run "python3 prices.py ec2 | grep -E 'sa-east-1|IPv4'"
run "python3 -c \"print(round(730 * 0.0050, 2))\""

block nat
run "python3 prices.py ec2 | grep -E 'sa-east-1|NAT'"
run "python3 -c \"print(round(730 * 0.0930, 2), round(100 * 0.0930, 2), round(730 * 0.0930 + 100 * 0.0930, 2))\""
run "python3 -c \"print(round(730 * 0.0450, 2), round(100 * 0.0450, 2), round(730 * 0.0450 + 100 * 0.0450, 2))\""

block sg
awsrun "ec2 authorize-security-group-ingress --generate-cli-skeleton | jq '.IpPermissions[0] | keys'"

block alb
run "python3 prices.py ec2 | grep -E 'sa-east-1|ALB'"
run "python3 -c \"print(round(730 * 0.0340, 2), round(730 * 0.0225, 2))\""

block tier
run "python3 -c \"print(round(2 * 730 * 0.0930, 2), round(2 * 730 * 0.0930 + 730 * 0.0340, 2))\""
