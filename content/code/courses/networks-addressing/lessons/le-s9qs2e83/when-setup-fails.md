---
title: When the setup fails
version: 1
---

Most people who give up on a course like this one give up here, on an error message about a machine
they have not finished building. These are the failures you are most likely to meet, in the order you
would meet them, with what each one means. Every message in a block below was printed by the script
or by the system, on a real machine, while this course was recorded.

**The virtual machine will not start, and the message mentions virtualisation, VT-x, AMD-V or SVM.**
The processor's virtualisation support is switched off in the computer's firmware. It is a setting in
the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and it is off by default on
many laptops. No software can turn it on for you.

**The script asks for sudo.** It changes the kernel's network configuration, which only root may do:

```
ana@lab:~$ bash ~/netlab/netlab.sh up office
run it with sudo
```

**The script names packages.** Before it builds anything, it checks that every package it uses is
installed, and lists the ones that are not, as a command ready to run:

```
ana@lab:~$ sudo bash ~/netlab/netlab.sh up office
install first: sudo apt install bridge-utils frr iputils-arping traceroute conntrack isc-dhcp-server isc-dhcp-client isc-dhcp-relay radvd ndisc6 ipcalc sipcalc wireguard-tools lldpd
```

Run the command it prints, or the `apt-get install` line of the previous section, and try again. If
`apt-get` says it could not get a lock, Ubuntu is installing its own updates, which it does in the first
minutes after a machine boots; wait a few minutes and run it again.

**The kernel has no modules.** This is what the script printed in a Linux container, whose kernel came
with the container and has none of the modules the lab loads:

```
$ sudo bash ~/netlab/netlab.sh up office
modprobe: WARNING: Module 8021q not found in directory /lib/modules/6.18.44-fc-v77
modprobe: WARNING: Module bonding not found in directory /lib/modules/6.18.44-fc-v77
modprobe: WARNING: Module bridge not found in directory /lib/modules/6.18.44-fc-v77
modprobe: WARNING: Module veth not found in directory /lib/modules/6.18.44-fc-v77
modprobe: WARNING: Module wireguard not found in directory /lib/modules/6.18.44-fc-v77
```

No package fixes this, because the kernel is not the container's to change. The lab needs a whole
Linux machine, real or virtual, which is why the previous section recommends a virtual machine and
not WSL2 or Docker.

**A name is wrong.** `up` builds the network in the file of that name beside the script, and `on`
reaches a device of the network that is up:

```
ana@lab:~$ sudo bash ~/netlab/netlab.sh up offce
no network called offce; try: list
ana@lab:~$ bash ~/netlab/netlab.sh list
office
ana@lab:~$ sudo bash ~/netlab/netlab.sh down
ana@lab:~$ sudo bash ~/netlab/netlab.sh on pc1
no device called pc1
```

`list` prints the networks it can find, one per file, and a name missing from it is a file not saved
in `~/netlab`, or saved under another name. `no device called pc1` means no network is up, or the one
that is up has no pc1.

**A pasted file is cut short.** A file copied without its last lines stops in the middle of a block,
and the error then points somewhere that looks fine. Here `office.sh` was saved with only its first 40
lines, which end inside the firewall's rules:

```
ana@lab:~$ bash -n ~/netlab/office.sh
/home/ana/netlab/office.sh: line 40: warning: here-document at line 28 delimited by end-of-file (wanted `NFT')
ana@lab:~$ sudo bash ~/netlab/netlab.sh up office
/home/ana/netlab/office.sh: line 40: warning: here-document at line 28 delimited by end-of-file (wanted `NFT')
/dev/stdin:13:1-1: Error: syntax error, unexpected end of file
    counter comment "everything else: dropped"
^
```

`bash -n` reads a file without running it and prints nothing when the file is whole, so it is the
check to run after every paste. Here it says the file ended at line 40 while still waiting for the word
`NFT` that closes the block opened at line 28. Run without the check, the same file reaches `nft`, which
complains about a line that is perfectly correct; the missing part is the one after it. Compare the end
of your file with the end of the block in the lesson.

**And when the network looks wrong**, build it again. `sudo bash ~/netlab/netlab.sh up office` takes
down everything the script made and builds the office from nothing, in under a minute. When even that
does not help, delete the virtual machine and make it again, which takes about half an hour. It feels
like giving up. It is what professionals do with a machine whose state nobody can explain any more,
and it is the reason everything in this lab is built from files you can read.
