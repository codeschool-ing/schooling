#!/usr/bin/env bash
# The terminal session quoted in lesson 12 of azure-foundations, as a script
# that produces it. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# WHAT REACHES THE INTERNET: two requests to Microsoft Entra ID's public
# getuserrealm.srf at login.microsoftonline.com, for a domain reserved for
# examples and for microsoft.com. No sign-in, no key; the answer is the one
# Microsoft's sign-in page receives before it shows a password box.
#
# NOT PRODUCED HERE, and said so in the prose: everything about Active
# Directory, Connect Sync, Cloud Sync, password hash synchronisation,
# pass-through authentication and federation, which need a directory and a
# tenant.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

block realm
run "curl -sS 'https://login.microsoftonline.com/getuserrealm.srf?login=ana@shop.example&json=1' | jq '{NameSpaceType, DomainName}'"
run "curl -sS 'https://login.microsoftonline.com/getuserrealm.srf?login=ana@microsoft.com&json=1' | jq '{NameSpaceType, DomainName}'"
