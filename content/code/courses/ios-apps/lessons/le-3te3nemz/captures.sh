#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file run here is lifted out of this lesson's .md (or lesson 1's) by
# ../../lab.sh, so the file run is the block the student copies.
#
# What is STAGED rather than typed:
#   - ~/plist/Info.plist is lesson 1's file, put there again from lesson 1's
#     info-plist.md so this lesson does not depend on lesson 1's captures
#     having run first; the lesson's `cp` then copies it as the student does.
#
# Nothing from Xcode, AVFoundation, PhotosUI, Core Location or App Tracking
# Transparency was run: those halves of the lesson are marked not run.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh plist
put "$HERE/../le-r8sx9rjk/info-plist.md" Info.plist

fresh privacy
put "$HERE/usage-strings.md" Info.plist
put "$HERE/privacy-manifest.md" PrivacyInfo.xcprivacy
put "$HERE/privacy-manifest.md" check-privacy.swift
put "$HERE/the-denied-path.md" denied.swift
block privacy
run 'swift check-privacy.swift Info.plist PrivacyInfo.xcprivacy camera userdefaults; echo $?'
run 'cp ~/plist/Info.plist Lesson1.plist'
run 'swift check-privacy.swift Lesson1.plist PrivacyInfo.xcprivacy camera userdefaults; echo $?'
run 'swift check-privacy.swift Info.plist PrivacyInfo.xcprivacy camera userdefaults tracking; echo $?'
block denied
run 'swift denied.swift'
