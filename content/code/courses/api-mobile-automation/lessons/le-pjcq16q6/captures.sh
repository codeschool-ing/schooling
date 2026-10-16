#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of api-mobile-automation, as the
# script that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT RAN AND WHAT COULD NOT. This lesson compares an emulator, a simulator
# and a real device, and none of the three exists here: the sandbox has no
# hardware virtualisation (lesson 14), no Mac and no phone. What is recorded
# is what the Android emulator says about itself without starting, from the
# SDK that ../../lab.sh describes:
#   - three entries of the emulator's own list of the hardware a virtual
#     device can declare (emulator/lib/hardware-properties.ini, which the SDK
#     ships), showing that a GPS, a battery and an accelerometer are each a
#     yes-or-no property;
#   - `emulator -help-camera-back`, the modes of the emulated camera;
#   - the head of `emulator -help-gpu`, the renderers a virtual GPU uses.
# Nothing is STAGED: no server is started and no device is involved.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with emulator 36.1.9,
# TZ=America/Sao_Paulo, as user ana.

source "$(dirname "$0")/../../lab.sh"
here /home/ana

block hardware
run "grep -A4 -E '^name += hw\.(gps|battery|accelerometer)$' ~/Android/Sdk/emulator/lib/hardware-properties.ini"

block camera
run 'emulator -help-camera-back'

block gpu
run 'emulator -help-gpu | head -16'
