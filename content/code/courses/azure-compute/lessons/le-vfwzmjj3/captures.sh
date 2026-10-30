#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of azure-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-vfwzmjj3/captures.sh
#
# Every block runs in one fresh lab, in order. The four Bicep files the lesson
# shows whole (db.bicep, disk.bicep, web.bicep, files.bicep) are taken from
# the lesson, so what was compiled is what the student reads.
#
# What is STAGED rather than typed:
#   - Each deliberate mistake is made with sed on a copy of the file, and the
#     copy is compiled; the student makes the same change in an editor, in the
#     file itself, and puts it back afterwards.
#   - Azurite's help is asked of the image with `docker run --rm`, which pulls
#     nothing: the image is the one the lab already has.
#
# Nothing here reaches Azure: there is no account. Nothing creates a disk, a
# virtual machine or a file share; the compiler checks the declarations, and
# every number about performance is quoted from Microsoft's documentation.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

block help-disk
run 'az disk create --help | tr -s "[:space:]" " " | grep -o "\-\-sku : [^.]*\. Allowed values: [A-Za-z0-9_, ]*"'
run 'az vm disk attach --help | tr -s "[:space:]" " " | grep -o "\-\-caching : [^.]*\. Allowed values: [A-Za-z, ]*"'
run 'az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-os-disk-caching : [^.]*\. Default: [A-Za-z]*\. Allowed values: [A-Za-z, ]*"'

block db-build
from_lesson "$HERE/managed-disks.md" db.bicep > db.bicep
run 'bicep build db.bicep'
run 'jq -c ".resources[] | {type, name, zones, sku: .sku.name, size: .properties.diskSizeGB}" db.json'
run 'jq ".resources[2].properties.storageProfile.dataDisks" db.json'
run 'jq -c ".resources[2].dependsOn" db.json'

block db-mistakes
quiet "sed \"s/caching: 'None'/caching: 'none'/\" db.bicep > db-typo.bicep"
run 'bicep build db-typo.bicep'
quiet "sed \"0,/'1'/s//'2'/\" db.bicep > db-zone.bicep"
run 'bicep build db-zone.bicep'
run 'jq -c ".resources[] | [.name, .zones]" db-zone.json'
quiet 'rm -f db-typo.* db-zone.*'

block snapshot-help
run 'az snapshot create --help | tr -s "[:space:]" " " | grep -o "\-\-incremental : [^.]*\.[^-]*"'

block v2-help
run 'az disk create --help | tr -s "[:space:]" " " | grep -o "\-\-disk-[a-z]*-read-write : [^.]*\.[^.]*\."'

block v2-build
from_lesson "$HERE/disk-types.md" disk.bicep > disk.bicep
run 'bicep build disk.bicep'
run 'jq ".resources[0] | {sku, zones, properties}" disk.json'

block v2-mistakes
quiet "sed \"s/PremiumV2_LRS/Premium_V2_LRS/\" disk.bicep > disk-sku.bicep"
run 'bicep build disk-sku.bicep'
run 'jq -r ".resources[0].sku.name" disk-sku.json'
quiet "sed \"s/diskMBpsReadWrite: 145/diskMBpsReadWrite: '145'/\" disk.bicep > disk-text.bicep"
run 'bicep build disk-text.bicep'
quiet "sed \"s/diskSizeGB: 256/diskSizeGB: 8/\" disk.bicep > disk-small.bicep"
run 'bicep build disk-small.bicep'
run 'jq -c ".resources[0].properties | {diskSizeGB, diskIOPSReadWrite, diskMBpsReadWrite}" disk-small.json'
quiet 'rm -f disk-sku.* disk-text.* disk-small.*'

block ephemeral-help
run 'az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-ephemeral-os-disk : [^.]*\.[^-]*"'
run 'az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-ephemeral-os-disk-placement --ephemeral-placement : [^.]*\.[^.]*\.[^-]*"'

block web-build
from_lesson "$HERE/ephemeral-os-disks.md" web.bicep > web.bicep
run 'bicep build web.bicep'
run 'jq ".resources[0].properties.storageProfile.osDisk" web.json'

block web-mistakes
quiet "sed \"s/caching: 'ReadOnly'/caching: 'ReadWrite'/; s/'ResourceDisk'/'TempDisk'/\" web.bicep > web-wrong.bicep"
run 'bicep build web-wrong.bicep'
run 'jq -c ".resources[0].properties.storageProfile.osDisk | {caching, diffDiskSettings}" web-wrong.json'
quiet "sed \"s/placement: 'ResourceDisk'/&\n          enableFullCaching: true/\" web.bicep > web-full.bicep"
run 'grep -n -A1 "placement" web-full.bicep'
run 'bicep build web-full.bicep'
quiet "sed \"s/@2024-07-01/@2025-04-01/\" web-full.bicep > web-full-2504.bicep"
run 'bicep build web-full-2504.bicep'
quiet "sed \"s/@2024-07-01/@2025-11-01/\" web-full.bicep > web-full-2511.bicep"
run 'bicep build web-full-2511.bicep'
quiet 'rm -f web-wrong.* web-full.* web-full-2504.* web-full-2511.*'

block azurite
run 'docker run --rm mcr.microsoft.com/azure-storage/azurite:3.37.0 azurite --help | grep -o -- "--[a-z]*Port <n> .*"'

block share-help
run 'az storage share-rm create --help | tr -s "[:space:]" " " | grep -o "\-\-enabled-protocols : [^.]*\.[^.]*\.[^-]*"'

block files-build
from_lesson "$HERE/azure-files.md" files.bicep > files.bicep
run 'bicep build files.bicep'
run 'jq -c ".resources[] | {type, kind, sku: .sku.name}" files.json'
run 'jq ".resources[2].properties" files.json'

block files-mistakes
quiet "sed \"s/'NFS'/'NFSv4'/\" files.bicep > files-proto.bicep"
run 'bicep build files-proto.bicep'
run 'jq -r ".resources[2].properties.enabledProtocols" files-proto.json'
quiet 'rm -f files-proto.*'
