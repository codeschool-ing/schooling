---
title: When the setup fails
version: 1
---

Most people who give up on a course like this one give up here, before the first real lesson, on an
error message about a machine they have not built yet. These are the failures that actually happen,
in the order you would meet them, with what each one means.

**The virtual machine will not start, and the message mentions virtualisation, VT-x, AMD-V or
SVM.** The processor's virtualisation support is switched off in the computer's firmware. It is a
setting in the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and it is off by
default on many laptops. No software can turn it on for you. On Windows, Hyper-V and the Windows
Subsystem for Linux can also hold it, and then VirtualBox runs slowly or not at all.

**`multipass launch` times out.** The first launch downloads an Ubuntu image of several hundred
megabytes, and a slow connection takes longer than its default wait. `multipass launch` accepts a
`--timeout` in seconds; give it 1800 and let it finish.

**`apt-get` says it could not get a lock.** Ubuntu runs its own updates for the first minutes after
a machine boots, and only one program may install packages at a time. Wait until
`ps aux | grep -c [a]pt` prints 0, then run the command again. Deleting the lock file is the advice
you will find online, and it is how a package database gets corrupted.

**`apt-get` cannot reach the archive.** Inside the machine, `curl -sI http://archive.ubuntu.com`
should answer `200`. If it cannot resolve the name, the machine has no DNS, which in a VM usually
means the host's VPN or firewall is in the way; turning the VPN off while installing is the quick
test.

**A server will not start.** Ask systemd before guessing:

```
sudo systemctl status nginx
sudo journalctl -u nginx -n 20
```

The last lines of the journal name the reason almost every time, and two reasons account for most
of them in this course. Another program already holds the port, which the section on Apache shows
on purpose. Or the configuration file has an error, which the last section of this lesson
shows on purpose too.

**`curl http://ipelivros.example/` says it could not resolve the host.** The names in `/etc/hosts`
are missing. `grep ipelivros /etc/hosts` should print one line; if it prints nothing, `lab.sh
install` did not finish, and running it again is safe, because it checks before adding anything.

**And when nothing else works**, delete the machine and build it again. With Multipass that is
`multipass delete --purge web` followed by the two commands of the previous section, and about ten
minutes. It feels like giving up. It is what professionals do with a machine whose state nobody can
explain any more, and it is the reason this course builds everything from one script.
