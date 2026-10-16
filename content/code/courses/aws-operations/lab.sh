#!/usr/bin/env bash
# The laptop every transcript in aws-operations was recorded on. Not for the
# student, who builds the same environment from lesson 1 and never sees this.
#
# THERE IS NO AWS ACCOUNT IN THIS COURSE. The AWS the command line talks to is
# moto 5.2.3, the open-source imitation of the AWS API, on 127.0.0.1:4567. It
# keeps what it is told in memory, runs no machine, carries no traffic, bills
# nothing, and forgets everything when it stops. The four AWS courses share the
# environment: AWS CLI v2 2.37.4 in ~/.local, moto[server]==5.2.3 in
# ~/aws/venv, region sa-east-1, the credentials test/test.
#
#   bash lab.sh student    # ~/aws and ~/.local built from lesson 1's own fences
#   bash lab.sh tools      # what later lessons install, from their own fences
#
# Both read the commands out of the lessons (capture.sh, `fence`), so what is
# recorded is what the student is told to type.
#
# WHAT IS STAGED, and why:
#   - the recording machine is a container whose `python3` is 3.13; Ubuntu
#     24.04's is 3.12. PYTHON3_DIR names a directory with a `python3` link to
#     python3.12, put first on the path. On a stock Ubuntu 24.04 leave it unset.
#   - the transcripts run as root with HOME=/home/ana, and the prompt is printed
#     as ana@laptop by capture.sh rather than by a shell.
#   - the Terraform Registry was not reachable from the recording machine, and
#     releases.hashicorp.com was. So the AWS provider (6.67.0) is downloaded
#     from releases.hashicorp.com, checked against HashiCorp's SHA256SUMS, and
#     served to Terraform from a filesystem mirror named in TF_CLI_CONFIG_FILE.
#     `terraform init` prints the same lines either way; lesson 6 says so.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, from 2026-10-16.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OPT=/opt/awsops
PROVIDER=6.67.0
[ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"

provider_mirror() {
  local name=terraform-provider-aws file=terraform-provider-aws_${PROVIDER}_linux_amd64.zip
  local base=https://releases.hashicorp.com/$name/$PROVIDER
  local dir=$OPT/mirror/registry.terraform.io/hashicorp/aws/$PROVIDER/linux_amd64
  [ -d "$dir" ] && return 0
  mkdir -p "$OPT/dl" "$dir"
  [ -f "$OPT/dl/$file" ] || curl -sSfo "$OPT/dl/$file" "$base/$file"
  curl -sSf "$base/${name}_${PROVIDER}_SHA256SUMS" | grep " $file\$" | (cd "$OPT/dl" && sha256sum -c --quiet)
  unzip -oq "$OPT/dl/$file" -d "$dir"
  cat > "$OPT/terraformrc" <<EOF
provider_installation {
  filesystem_mirror {
    path = "$OPT/mirror"
  }
}
EOF
}

case "${1:-}" in
  student)
    [ -e "$HOME/aws" ] && { echo "$HOME/aws exists: this builds the lab from nothing"; exit 1; }
    # shellcheck source=capture.sh
    . "$COURSE/capture.sh"
    fence "$COURSE/lessons/le-a4hvmgna/environment.md" 2   # the first is apt-get, which needs sudo
    ;;
  tools)
    # shellcheck source=capture.sh
    . "$COURSE/capture.sh"
    fence "$COURSE/lessons/le-c8fyezk9/provider.md" 1     # Terraform
    fence "$COURSE/lessons/le-vmdgmh6n/app.md" 1          # Node.js and the CDK
    fence "$COURSE/lessons/le-htmwc538/anatomy.md" 1      # cfn-lint
    provider_mirror
    ;;
  *)
    echo "usage: bash lab.sh student|tools" >&2
    exit 2
    ;;
esac
