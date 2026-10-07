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
setting in the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and many laptops
ship with it off. No software can turn it on for you. On Windows, Hyper-V and the Windows Subsystem
for Linux can also hold it, and then VirtualBox runs slowly or not at all.

**`multipass launch` times out.** The first launch downloads an Ubuntu image of several hundred
megabytes, and a slow connection takes longer than the default wait. `multipass launch` accepts
`--timeout` in seconds; give it 1800 and let it finish.

**`apt-get` says it could not get a lock.** Ubuntu installs its own updates in the first minutes after
a machine boots, and only one program may install packages at a time. Wait a few minutes and run the
command again. Deleting the lock file is the advice you will find online, and it is how a package
database gets corrupted.

**`up` stops at once and names packages.** `nslab.sh` checks for every package before it builds
anything, and says which are missing, with the command that installs them:

```
$ sudo bash nslab.sh up; echo "exit $?"
install first: sudo apt install aide
exit 1
```

Run the line it prints, then `up` again.

**`up` says to run it with `sudo`.** Building namespaces needs root, and the script also needs to know
whose account the machines are for, which `sudo` tells it:

```
$ bash nslab.sh up; echo "exit $?"
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
windows.sh: line 8: set: pipefail^M: invalid option name
windows.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators
$ sed -i "s/\r$//" windows.sh; cmp windows.sh nslab.sh && echo same
same
```

`cat -v` shows the carriage return as `^M`; without it, the terminal moves back to the start of the
line on that character and prints the rest over it, which is why the message looks garbled. `file`
says the same thing in words: *with CRLF line terminators*. The `sed` removes them, and the file is then
the same as the one the lessons used. The same symptom, with a line that is not the first, usually
means the paste stopped half way; the `sha256sum` check of the previous section catches that before
anything runs.

**A lesson's extra script refuses to run.** Three lessons add something to the lab with a script of
their own, and each one refuses to add it twice or to a lab that is not up:

```
$ sudo bash nslab.sh up; sudo bash inline.sh; sudo bash inline.sh; echo "exit $?"
ips is already inline: sudo bash nslab.sh reset, then run this again
exit 1
$ sudo bash nslab.sh reset; sudo bash inline.sh; echo "exit $?"
exit 0
```

The answer is the same as for most trouble in this course: `reset`, and run it again.

**Something that worked yesterday does not answer today.** A machine that was restarted keeps
`/lab`, but not the namespaces, which live in memory. `sudo bash nslab.sh up` builds them again. If
something still behaves strangely, `reset`: it costs four seconds and puts every machine back the
way `nslab.sh` builds it.

**And when nothing else works**, delete the virtual machine and build it again. With Multipass that
is `multipass delete --purge nslab` followed by the commands of the first section. It feels like giving up. It is what professionals do with a machine whose state nobody can
explain any more, and it is why this course builds everything from a script you can read.
