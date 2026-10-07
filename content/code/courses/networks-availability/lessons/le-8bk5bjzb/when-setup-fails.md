---
title: When the setup fails
version: 1
---

Most people who give up on a course like this one give up here, on an error about a network they have
not finished building. These are the failures that actually happen, roughly in the order you would
meet them, with the message each one prints and what it means.

**The virtual machine will not start, and the message mentions virtualisation, VT-x, AMD-V or SVM.**
The processor's virtualisation support is switched off in the computer's firmware. It is a setting in
the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and many laptops ship with it
off. No program can switch it on for you. On Windows, Hyper-V and the Windows Subsystem for Linux can
also hold it, and then VirtualBox runs slowly or not at all.

**`multipass launch` times out.** The first launch downloads an Ubuntu image of several hundred
megabytes, and a slow connection takes longer than the default wait. Add `--timeout 1800` and let it
finish.

**`apt-get` says it could not get a lock.** Ubuntu installs its own updates in the first minutes after
a machine boots, and only one program may install at a time. Wait until `ps aux | grep -c [a]pt` prints
0, then run the command again. Deleting the lock file is the advice you will find online, and it is
how a package database gets corrupted.

**`run it with sudo, from your own account: sudo bash netlab.sh up`.** The script was run without
`sudo`, or from a root shell, where it cannot tell whose home to make on each machine. Run it exactly
as the message says, from your own prompt.

**`install first: sudo apt-get install mtr-tiny`.** A package from the list in the first section is
missing, here `mtr-tiny`. The message names every missing one; install them and run `up` again.

**`netlab.sh: line 242: syntax error: unexpected end of file`.** The paste stopped early, and bash
reached the end of the file in the middle of a function. The number is wherever your copy ended. The
whole script is 377 lines, and `wc -l netlab.sh` should say so; if it says fewer, copy it again
with the button rather than by selecting the text.

**`Cannot open network namespace "hq3": No such file or directory`.** There is no machine by that
name. Either the name has a typo, and `ip netns list` shows the real ones, or the network is not built:
a reboot of the virtual machine removes every namespace, and `sudo bash netlab.sh up` puts them back.

**`setsid: failed to execute tunnel.py: No such file or directory`.** The tunnel program of the section
on IP-in-IP is not installed where the machines look for it. That section says how to save it.

**`RTNETLINK answers: File exists`.** A command that adds an address or a route was typed twice; the
first time already did it. It is harmless. If a lesson's state has drifted so far that you are no
longer sure what is there, that is what `reset` is for.

**A program stopped on every machine at once.** The machines share one process table, so `sudo pkill nginx`
typed on `web1` also stops the nginx of `web2` and `web3`. Stop a program on one machine with
`sudo bash netlab.sh kill web1 nginx`, typed on the virtual machine itself; the lessons do it that way.

**And when nothing else works**, `sudo bash netlab.sh reset` builds the whole network again in about ten
seconds. Past that, delete the virtual machine with `multipass delete --purge netlab` and start the
first section again; the slow part is the download. It feels like giving up. It is what
professionals do with a machine whose state nobody can explain any more, and it is why this course
builds everything from a script you can read.
