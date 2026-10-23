---
title: When the lab does not come up
version: 1
---

Most people who give up on a course like this one give up here, before the first real lesson, on an
error about a machine they have not built yet. These are the failures that happen, in the order you
would meet them. The ones with a transcript were produced on purpose, on the computer the course was
recorded on.

**The virtual machine will not start, and the message mentions virtualisation, VT-x, AMD-V or
SVM.** The processor's virtualisation support is switched off in the computer's firmware. It is a
setting in the BIOS or UEFI menu, often under *Advanced* or *CPU configuration*, and many laptops
ship with it off. No software can turn it on for you. On Windows, Hyper-V and the Windows Subsystem
for Linux can also hold it, and then VirtualBox runs slowly or not at all.

**`apt-get` says it could not get a lock.** Ubuntu installs its own updates in the first minutes
after a machine boots, and only one program may install packages at a time. Wait a few minutes and
run the command again. Deleting the lock file is the advice you will find online, and it is how a
package database gets corrupted.

**`build` stops with `Failed getting release file` or `Temporary failure resolving`.** The computer
cannot reach `archive.ubuntu.com`. `build` is the only step that needs the internet; check that
`curl -I http://archive.ubuntu.com/ubuntu/` answers, and run `build` again. It starts from nothing
every time, so a half-finished build is never a problem.

**The script says to run it with `sudo`.** Building containers needs root, and the script also
needs to know whose account to put on the machines, which `sudo` tells it:

```
$ bash hostlab.sh up; echo "exit $?"
run it with sudo, from your own account
exit 1
```

Running it from a root shell has the same answer, for the same reason: there is no account to give
the machines. Run it from your own account, with `sudo` in front.

**The first line fails with something that makes no sense.** A file saved with Windows line endings
puts an invisible carriage return at the end of every line, and `bash` reads it as part of the
command. The error then names whatever happened to be on the first line it ran:

```
$ sudo bash windows.sh up 2>&1 | cat -v | head -3; file windows.sh
windows.sh: line 9: set: pipefail^M: invalid option name
windows.sh: Bourne-Again shell script, Unicode text, UTF-8 text executable, with CRLF line terminators
$ sed -i "s/\r$//" windows.sh; cmp windows.sh hostlab.sh && echo same
same
```

`cat -v` shows the carriage return as `^M`, and `file` names the cause. The `sed` line removes it.
This happens when the script is pasted into an editor on Windows and copied across.

**A shell says the machine is not running.** Every machine is gone after `down`, after a reboot of
your computer, or before the first `up`, and the script names the command that brings it back:

```
$ sudo bash hostlab.sh sh web; echo "exit $?"
web is not running: sudo bash hostlab.sh up web
exit 1
```

**A machine says `degraded` instead of `running`.** One of its services failed to start. Open a
shell on it and ask which: `systemctl --failed` names the unit, and `journalctl -u` followed by
that name says why. Nothing in the lab should be degraded after a plain `up`, so a degraded machine
there means the image is not the one the course was recorded with: run `build` again.

**The disk is full.** The images take 1.4 GB and the seven machines 4.9 GB, and each `up` replaces
them rather than adding to them. A virtual machine created with less than 20 GB fills up the first
time every machine runs at once. `sudo bash hostlab.sh up web` starts one machine and the switch;
`sudo rm -rf /var/lib/hostlab/machines` frees the space the copies take, after a `down`.
