#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of api-mobile-automation, as the
# script that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT RAN AND WHAT COULD NOT. Section `setting-up` has the student install
# Android Studio, which brings the SDK, and create an emulator. Android Studio
# is a desktop program that cannot run in this sandbox, and the sandbox has no
# hardware virtualisation, so no emulator can start here. What is recorded:
#   - the SDK's command-line tools, `adb` and `emulator`, from the SDK that
#     ../../lab.sh describes (copied out of the cimg/android:2025.10 image), on
#     the PATH the lesson's ~/.bashrc lines give, answering for their version;
#   - `adb devices` and `emulator -list-avds` with no device and no emulator;
#   - `emulator -accel-check`, which is the refusal a computer without
#     virtualisation gives, and which section `when-setup-fails` quotes;
# and, before any of it, the app the lesson shows is extracted from its
# blocks and compiled against Android 35 (`lab.sh appcheck`): resources linked
# by aapt2, Kotlin compiled by the Kotlin compiler. It was not built by Gradle
# and was not run, and the lesson says so. STAGED: adb's server is stopped at
# the end, so the next run starts it again and prints the same first lines.
#
# Recorded 2026-10-10 on Ubuntu 24.04, platform-tools 36.0.0, emulator 36.1.9,
# TZ=America/Sao_Paulo, as user ana.

source "$(dirname "$0")/../../lab.sh"
project 14 /home/ana/boxoffice
lab_appcheck /home/ana/boxoffice >&2 || { echo "captures: the app does not compile" >&2; exit 1; }
quiet 'adb kill-server'
here /home/ana

block tools
run 'adb version'
run 'emulator -version | head -1'

block devices
run 'adb devices'
run 'emulator -list-avds'

block accel
run 'emulator -accel-check'

quiet 'adb kill-server'
