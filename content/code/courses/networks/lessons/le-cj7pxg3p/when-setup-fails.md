---
title: When the setup fails
version: 1
---

Most people who give up on a course like this give up here, on an error about a machine they have
not finished building. These are the failures that actually happen, in the order you would meet
them.

**The virtual machine will not start, and the message mentions virtualisation, VT-x, AMD-V or
SVM.** The processor's support for virtual machines is switched off in the computer's firmware, the
BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*. No program can switch it on for
you. On Windows, Hyper-V and WSL can also hold it, and then VirtualBox runs slowly or not at all.

**`apt-get` says it could not get a lock.** Ubuntu installs its own updates in the first minutes
after a machine boots, and only one program may install packages at a time. Wait a few minutes and
run the command again. Deleting the lock file is the advice you will find online, and it is how a
package database gets corrupted.

**IPv6 is still there.** If `ls /proc/sys/net/ipv6` lists files after the restart, the boot loader
did not take the setting. `cat /proc/cmdline` prints the line the kernel was started with, and
`ipv6.disable=1` should be in it. If it is not, check that
`/etc/default/grub.d/99-netlab.cfg` holds the one line from section 03, run `sudo update-grub`
again, and restart. The lab still works with IPv6 on, but a few of your transcripts will not match
the ones in the lessons.

**You forgot `sudo`.** The lab creates network devices for the whole machine, and only root may:

```
ubuntu@netlab:~$ bash ~/netlab/netlab up
netlab builds and removes network devices for the whole machine: run it with sudo
```

**A package is missing.** The script checks for every package before it builds anything, and names
the ones it did not find. Install them with `sudo apt-get install -y` and the names, and run `up`
again:

```
ubuntu@netlab:~$ sudo bash ~/netlab/netlab up
install first: swaks
```

**A file was cut short.** A paste that stopped before the end leaves a file that looks fine at the
top and breaks at the bottom. Bash reads a function at a time and reports the place where the file
ended, not where the paste failed:

```
ubuntu@netlab:~$ wc -l ~/netlab/dns.sh
100 /home/ubuntu/netlab/dns.sh
ubuntu@netlab:~$ sudo bash ~/netlab/netlab up
/home/ubuntu/netlab/dns.sh: line 100: warning: here-document at line 93 delimited by end-of-file (wanted `Z')
/home/ubuntu/netlab/dns.sh: line 101: syntax error: unexpected end of file
```

`dns.sh` should have 172 lines, as the line counts in section 08 show. Open it, delete everything,
and paste the whole block from section 05 again.

**The machines are not there.** This is the message after a restart, or before the first `up`:

```
ubuntu@netlab:~$ sudo bash ~/netlab/netlab shell laptop
Cannot open network namespace "laptop": No such file or directory
```

`laptop` is a network namespace, and a namespace exists only while the lab is up. Run `up`.

**You are in a container rather than a virtual machine.** Docker and many of the shells offered in
a browser are containers, and a container is usually not allowed to create network namespaces,
even as its own root. The build stops at the first `ip netns add` with
`mount --make-shared /run/netns failed: Operation not permitted`. No setting inside the container
fixes that; use a virtual machine.

**Something in the lab behaves differently from a transcript**, after a lesson that broke
something or after an experiment of your own. Run `sudo bash ~/netlab/netlab reset`. It costs ten
seconds and puts every machine back the way the four files describe.

**And when nothing else works**, delete the virtual machine and build it again: with Multipass,
`multipass delete --purge netlab`, then the commands of section 03 and the four files again. It
feels like giving up. It is what people who run networks do with a machine whose state nobody can
explain any more, and it is the reason everything here is built from files you can read.
