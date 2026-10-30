#!/usr/bin/env bash
# The laptop every transcript in azure-operations was recorded on. Not for the
# student, who builds the same environment from lesson 1 and never sees this.
#
# THERE IS NO AZURE SUBSCRIPTION IN THIS COURSE, and nothing on this machine
# imitates Azure Resource Manager. What runs: the Azure CLI 2.91.0 from PyPI in
# ~/azure/venv, Azurite 3.37.0 (Blob, Queue, Table) in a container, the Bicep
# CLI 0.48.1, Terraform 1.16.4 with the azurerm provider 5.12.0 from the
# registry, and the Kusto emulator (kustainer-linux) in a container. Region
# brazilsouth in every example, working directory ~/azure, prompt ana@laptop.
#
#   bash lab.sh student    # ~/azure built from lesson 1's own fences
#   bash lab.sh tools      # what later lessons install, from their own fences
#
# Both read the commands out of the lessons (capture.sh, `fence`), so what is
# recorded is what the student is told to type.
#
# WHAT IS STAGED, and why:
#   - the recording machine's `python3` is 3.13; Ubuntu 24.04's is 3.12.
#     PYTHON3_DIR names a directory with a `python3` link to python3.12, put
#     first on the path. On a stock Ubuntu 24.04 leave it unset.
#   - the transcripts run as root with HOME=/home/ana, and the prompt is printed
#     as ana@laptop by capture.sh rather than by a shell. Docker runs without
#     the `docker` group, because root needs none.
#   - Microsoft's Retail Prices API (prices.azure.com) was not reachable from the
#     recording machine. No price in the course was read from it; lesson 1 says
#     so, and the arithmetic uses round prices it calls illustrative.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, from 2026-10-30.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"

case "${1:-}" in
  student)
    [ -e "$HOME/azure" ] && { echo "$HOME/azure exists: this builds the lab from nothing"; exit 1; }
    # shellcheck source=capture.sh
    . "$COURSE/capture.sh"
    fence "$COURSE/lessons/le-y5gx206b/environment.md" 2   # the first is apt-get, which needs sudo
    ;;
  tools)
    # shellcheck source=capture.sh
    . "$COURSE/capture.sh"
    fence "$COURSE/lessons/le-5ckszpkn/install.md" 1      # Bicep
    ;;
  *)
    echo "usage: bash lab.sh student|tools" >&2
    exit 2
    ;;
esac
