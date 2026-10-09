#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript into a real bash and prints the fences whose output differs.
# --setup-home runs the `sh` fences that begin in ~: spin.sh and fill.sh, started
# and stopped where each section says, the small filesystem of disk-space, the
# deleted-but-open big.log, hog.py, inside.sh and throttle.sh. --no-job-control
# keeps a load that ends from printing `[1]+ Done` into the next transcript.
#
# Two machines. Most sections ran on the capture machine (cgroup v1, no systemd,
# four cores, 16 GB, sysstat and iproute2 installed). out-of-memory, and the two
# systemd-run transcripts of containers-lie (numbers 2 and 5), ran on an Ubuntu
# 24.04 cloud image under QEMU, reached by ssh: set REPLAY_SSH to the ssh command
# that logs in there, with ana and root accepting its key.
#
#   sudo bash captures.sh                    # the capture machine
#   REPLAY_SSH=... bash captures.sh guest    # the guest
#
# Expected to differ: everything measured — load averages, vmstat and iostat
# rows, PIDs, free memory, timings, steal — and the cgroup path of this shell.
# Pause or stop anything else heavy on the host first: an emulated guest running
# beside the capture shows up in every processor and memory figure. Recaptured on
# 2026-10-07 after lessons 1 to 10.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
if [ "${1:-}" = guest ]; then
  python3 "$LAB/replay.py" --setup-home out-of-memory.md
  python3 "$LAB/replay.py" --setup-home --select 2,5 containers-lie.md
  exit
fi
bash "$LAB/upto.sh" 11
python3 "$LAB/replay.py" --setup-home --no-job-control four-resources.md load-average.md cpu.md \
  memory.md swap.md disk-space.md disk-io.md which-process.md network.md sampling-and-counters.md
python3 "$LAB/replay.py" --setup-home --no-job-control --select 1,3,4,6 containers-lie.md
