---
title: When the setup fails
version: 1
---

Most people who give up on a course like this one give up here, on an error about a machine they have
not finished building. These are the failures that happen, in the order you would meet them.

**The checksum says `FAILED`.** The download is damaged. Download it again; never install from a file
that failed, because nothing it does afterwards can be trusted. Lesson 3 shows the failure on purpose.

**The virtual machine will not start, and the message mentions VT-x, AMD-V, SVM or virtualisation.**
The processor's support for virtual machines is switched off in the computer's firmware. It is a setting
in the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and lesson 2 shows how to
reach that menu. No program can switch it on for you. On Windows, Hyper-V and WSL can hold it too, and
VirtualBox then runs very slowly or not at all; use Hyper-V itself, or turn those two off.

**On an Apple-silicon Mac, the installer never appears, or crawls.** The `amd64` installer was used.
That Mac runs `arm64` systems natively and can only emulate the other kind, slowly. Download the
`arm64` installer and make the machine again.

**The password is refused at the first sign-in, though you typed it twice.** The installer was told
the wrong keyboard, and a character in the password sits somewhere else on the one you have. Sign in
by typing the password as that keyboard sees it, or install again with the right layout.

**After the reboot, the installer starts again.** The ISO is still in the machine's virtual drive and
it booted from that rather than from the disk. Remove it (in VirtualBox, *Devices*, *Optical Drives*)
and restart.

**`apt` says it could not get a lock.** In its first minutes Ubuntu installs its own security updates,
and only one program may install at a time. Wait a few minutes and run the command again. Deleting the
lock file is the advice you will find online, and it is how a package database gets damaged.

**`apt` cannot find PowerShell.** This is what it says when Microsoft's catalogue was not added, or was
added and `apt update` was not run after it:

```
ana@server:~$ sudo apt install -y powershell
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
E: Unable to locate package powershell
```

Run the lines of step 5 again, in order.

**Every `sudo` complains about the machine's own name.** This happens after renaming the server, and the
transcript below reproduces it by taking the name out of `/etc/hosts`:

```
ana@server:~$ sudo true
sudo: unable to resolve host server: Name or service not known
ana@server:~$ cat /etc/hostname
server
ana@server:~$ grep server /etc/hosts
ana@server:~$ echo '127.0.1.1 server' | sudo tee -a /etc/hosts
sudo: unable to resolve host server: Name or service not known
127.0.1.1 server
ana@server:~$ sudo true
```

`sudo` still ran each command; the line is a warning. The machine's name is in `/etc/hostname` and missing
from `/etc/hosts`, the file that turns names into addresses, so the machine cannot look itself up. The
installer writes both. Adding the line fixes it, and the last `sudo` says nothing. Lesson 15 is about
`/etc/hosts`.

**And when nothing else works**, restore the snapshot `fresh`, or delete the virtual machine and build it
again from step 2. It feels like giving up. It is what professionals do with a machine whose state nobody
can explain any more, and it costs half an hour because every step is written down in the section before
this one.
