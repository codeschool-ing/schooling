---
title: When the setup fails
version: 1
---

Most people who give up on a course like this one give up here, on an error about a machine they
have not finished building. These are the failures that happen, roughly in the order you would
meet them. Every transcript below is the real message, provoked on purpose on this course's machine.

**The virtual machine will not start, and the message mentions virtualisation, VT-x, AMD-V or
SVM.** The processor's support for virtual machines is switched off in the computer's firmware.
It is a setting in the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and many
laptops ship with it off. No program can turn it on for you. That one was not provoked here,
because the course's machine cannot run a hypervisor.

**`multipass launch` gives up before the machine is ready.** The first launch downloads an Ubuntu
image of several hundred megabytes, and a slow connection takes longer than Multipass waits by
default. Add `--timeout 1800` to the command and let it finish.

**`apt-get` or `pip` cannot download anything.** Inside the virtual machine, `curl -sI
https://archive.ubuntu.com` should print a status line. If the name does not resolve, the virtual
machine has no DNS, which usually means a VPN or a firewall on your computer is in the way.

**You forgot `sudo`.** Building namespaces needs root, and the script says so before it touches
anything:

```
ubuntu@netlab:~$ ~/netlab/netlab.sh up
run it with sudo
```

**The virtual environment is missing**, or was made somewhere else. The routers' API and every
script in the course run on the Python in `/opt/netauto`, so the script refuses to build a lab
nothing could talk to:

```
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh reset
missing /opt/netauto: make the virtual environment first
```

Run the two `/opt/netauto` lines from the section on the software, at the start of this lesson. A missing package is the
same kind of message, `install first:` followed by its name, and the `apt-get` line fixes it.

**The lab is already up.** `up` builds a lab that does not exist and does nothing to one that
does:

```
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh up
netlab: already up; reset rebuilds it
```

`reset` is what you meant: it takes the lab down and builds it again.

**The virtual machine was restarted**, or shut down and started again. Network namespaces live in
the kernel's memory, so a restart takes the whole lab with it, and the first command into it fails:

```
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh enter ctl
Cannot open network namespace "ctl": No such file or directory
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh up 2>&1 | tail -1
netlab: up: OSPF is Full and every service above answers
```

Nothing is broken, and `up` builds it again: it clears whatever the old lab left on disk before
it starts, so a lab interrupted halfway through a build comes back the same way. `ana`'s files are
where she left them.

**The script was saved on Windows and copied in.** Windows ends each line with two characters
where Linux expects one, and the first line of the script then names a program called `bash` plus
an invisible carriage return:

```
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh up
/usr/bin/env: ‘bash\r’: No such file or directory
/usr/bin/env: use -[v]S to pass options in shebang lines
ubuntu@netlab:~$ file ~/netlab/netlab.sh
/home/ubuntu/netlab/netlab.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators
ubuntu@netlab:~$ sed -i 's/\r$//' ~/netlab/netlab.sh
ubuntu@netlab:~$ file ~/netlab/netlab.sh
/home/ubuntu/netlab/netlab.sh: Bourne-Again shell script, ASCII text executable
netlab: devapi: started on core1, edge1 and edge2
netlab: nc1: started
netlab: tickets: started
netlab: napalm_frr: installed
netlab: netbox: started
netlab: sw1: started
netlab: up: OSPF is Full and every service above answers
```

`file` says `with CRLF line terminators`, the `sed` takes the extra character off every line, and
`file` agrees. Saving the script from inside the virtual machine, with `nano ~/netlab/netlab.sh`
and a paste, avoids the problem altogether.

**A service did not start.** Each line of `up` that ends in `started` was checked: the last thing
the script does is wait until every one of them accepts a connection, and it names any that never
did with `nothing answers on` and its address. That line means the program started and stopped
again, almost always because it was cut short or changed on its way into the file. Its own error
is in the file `netlab.sh` sends it to, beside the line that starts it: `/var/log/devapi.err` on
each router, for instance, which `enter` reads as `root`:
`sudo ~/netlab/netlab.sh enter core1 root 'tail /var/log/devapi.err'`. A program that is not in
`~/netlab` at all, or is there under another name, is not an error: its line says `skipped`.

**And when nothing else works**, delete the virtual machine and build it again: `multipass delete
--purge netlab`, then the commands of this lesson from the top. It feels like giving up, and it is
what people who run labs for a living do with a machine whose state nobody can explain any more.
The lab is written down in full in this lesson, which is what makes throwing it away cheap.
