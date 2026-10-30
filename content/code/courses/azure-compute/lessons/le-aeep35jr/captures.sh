#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of azure-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-aeep35jr/captures.sh
#
# Every block runs in one fresh lab, in order, so a file written in one block
# (vm.bicep) is still there in the next, as it is in the student's ~/azure
# when the sections are followed in order. The three files the lesson shows
# whole (vm.bicep, cloud-init.yaml, gallery.bicep) are taken from the lesson.
#
# What is STAGED rather than typed:
#   - `custom-data` adds one line to vm.bicep with sed; the student adds the
#     same line in an editor, as the section shows it.
#   - The two WARNING lines of `az vm image list` say the CLI could not fetch
#     its alias document: this machine is refused that host. A machine on the
#     open internet fetches it and prints neither line, and the lesson says
#     what the fetched document holds (read on GitHub, 2026-10-30).
#
# Nothing here reaches Azure: there is no account, and every command that
# would need one is shown refusing.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

block help-image
run 'az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-image : [^.]*\.[^.]*\."'

block help-security
run 'az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-security-type : [^.]*\. Allowed values: [A-Za-z, ]*"'

block list
run 'az vm image list --output table'

block list-canonical
run 'az vm image list --publisher Canonical --output table'

block refused
run 'az vm image list --all --publisher Canonical --offer ubuntu-24_04-lts --output table'
run 'az vm image show --urn Canonical:ubuntu-24_04-lts:server:latest'

block vm-build
from_lesson "$HERE/marketplace-images.md" vm.bicep > vm.bicep
run 'bicep build vm.bicep'
run 'jq ".resources[0].properties.storageProfile.imageReference" vm.json'

block vm-typo
run 'sed -i "s/TrustedLaunch/TrustedLaunh/" vm.bicep'
run 'bicep build vm.bicep'
run 'jq ".resources[0].properties.securityProfile" vm.json'
run 'sed -i "s/TrustedLaunh/TrustedLaunch/" vm.bicep'

block custom-data
from_lesson "$HERE/your-own-image.md" cloud-init.yaml > cloud-init.yaml
quiet "sed -i \"s|^      adminUsername: adminUsername\$|&\n      customData: loadFileAsBase64('cloud-init.yaml')|\" vm.bicep"
run 'grep -n -B1 customData vm.bicep'
run 'bicep build vm.bicep'
run 'jq ".resources[0].properties.osProfile.customData" vm.json'
run "jq -r '.variables[\"\$fxv#0\"]' vm.json | base64 -d | head -n 3"
run 'wc -c cloud-init.yaml'

block gallery-build
from_lesson "$HERE/the-compute-gallery.md" gallery.bicep > gallery.bicep
run 'bicep build gallery.bicep'
run 'jq -r ".resources[] | [.type, .name] | @tsv" gallery.json'

block gallery-typo
run 'sed -i "s/Generalized/Generalised/; s/V2/v2/" gallery.bicep'
run 'bicep build gallery.bicep'
run 'sed -i "s/Generalised/Generalized/; s/v2/V2/" gallery.bicep'
