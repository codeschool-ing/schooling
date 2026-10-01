#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of cloud (identity and access), as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   AWS=/path/to/aws bash captures.sh      # AWS: the AWS CLI v2 binary
#
# THERE IS NO CLOUD ACCOUNT AND NO CREDENTIAL. The CLI runs under `env -i` with
# a fresh, empty HOME, so nothing of the machine's own environment or files
# reaches it. Nothing here can reach an AWS account: with no credentials the
# CLI refuses before it signs a request, which is the point of the capture.
#
# What is STAGED rather than typed, and not shown in the lesson:
# the empty HOME itself; and, for the last block, a ~/.aws/credentials file
# holding the example key pair that AWS prints in its own documentation
# (AKIAIOSFODNN7EXAMPLE), which belongs to nobody. `aws configure list` only
# reads files and prints; it sends nothing anywhere.
#
# On the machine it was recorded on, the two steps of the credential chain that
# ask the instance metadata address (169.254.169.254) were answered by the
# sandbox's own network proxy with a refusal; on a laptop with no such proxy
# the request simply finds nothing. The `grep` keeps only the lines naming the
# sources, so that detail does not reach the lesson.
#
# Recorded 2026-09-28 on Ubuntu 24.04, no cloud account, no credentials,
# aws-cli/2.37.4.

set -uo pipefail
AWS=${AWS:?set AWS to the aws binary}
BIN=$(dirname "$AWS")
H=$(mktemp -d)
trap 'rm -rf "$H"' EXIT

# on 'command': what ana typed at her prompt, and everything it printed.
on() {
  printf 'ana@laptop:~/cloud$ %s\n' "$*"
  env -i HOME="$H" PATH="$BIN:/usr/bin:/bin" bash -c "$*" 2>&1 || true
}

echo '### nothing configured'
on 'aws --version'
on 'aws configure list'
on 'aws sts get-caller-identity'
echo
echo '### the chain, in the order the CLI searched it'
on "aws sts get-caller-identity --debug 2>&1 | grep -o 'Looking for credentials via: .*'"
echo
echo '### a long-lived key in a file'
mkdir -p "$H/.aws"
printf '[default]\naws_access_key_id = AKIAIOSFODNN7EXAMPLE\naws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY\n' > "$H/.aws/credentials"
on 'cat ~/.aws/credentials'
on 'aws configure list'
