#!/usr/bin/env python3
"""Lesson 1, getting-a-linux: `apt` refused while unattended-upgrades holds the lock.

THE AUTHOR'S TOOL. Starts the real unattended-upgrade as root, waits until it holds
dpkg's lock, and only then types the student's command, so the refusal is the one
a freshly booted Ubuntu gives. Prints the transcript to paste.
"""
import subprocess, time, sys
sys.path.insert(0, __file__.rsplit("/", 1)[0])
import replay

holder = subprocess.Popen(["unattended-upgrade", "-v"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
for _ in range(600):
    if subprocess.run(["fuser", "/var/lib/dpkg/lock-frontend"], capture_output=True).returncode == 0:
        break
    time.sleep(0.1)
else:
    sys.exit("unattended-upgrade never took the lock: nothing to upgrade?")
sh = replay.Shell("ana", 100)
out, _ = sh.run("sudo apt install tree")
print("ana@vm:~$ sudo apt install tree")
print("\n".join(l.rstrip() for l in out.rstrip("\n").split("\n")))
sh.close()
holder.wait()
