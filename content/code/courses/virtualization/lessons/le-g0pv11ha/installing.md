---
title: Installing QEMU and libvirt
version: 1
---

First, whether the processor can help. `kvm-ok`, from the `cpu-checker` package, looks for VT-x or
AMD-V and for the kernel's KVM module, and says in one line whether guests will run on the real
processor:

```bash
sudo apt install cpu-checker
```

```
ana@host:~$ sudo kvm-ok
INFO: Your CPU does not support KVM extensions
KVM acceleration can NOT be used
```

On the computer this course was recorded on the answer is **no**, and section 11 says what that means
and what to try. On your own computer, installed as the first path in section 02 describes, it
should say `KVM acceleration can be used`. Either way the lab works; a no only makes it slower.

Then the programs, all from Ubuntu's own packages, in one line:

```bash
sudo apt install qemu-system-x86 qemu-utils libvirt-daemon-system virtinst cloud-image-utils libguestfs-tools isc-dhcp-client
```

`qemu-system-x86` is the hypervisor and `qemu-utils` its disk tool, `qemu-img`. `libvirt-daemon-system`
is libvirt, with `virsh` to drive it and a ready-made network called `default`. `virtinst` brings
`virt-install`, which creates guests. `cloud-image-utils` makes the small disk that tells a new guest
its name, section 05, and `libguestfs-tools` changes a disk image without starting it, section 04.
`isc-dhcp-client` is there for `libguestfs-tools` alone, which needs it on Ubuntu 24.04 and does not
say so; section 11 shows what happens without it. apt lists a few hundred packages and asks before it
installs them.

The install also adds you to a group called **libvirt**, and that is what lets you run `virsh` without
`sudo`. A group only counts from your next login, so straight after the install, in the same terminal:

```
ana@host:~$ groups; virsh uri; virsh list --all
ana sudo
qemu:///session

 Id   Name   State
--------------------
```

Log out and back in, or restart the computer, and ask again:

```
ana@host:~$ groups; virsh uri
ana sudo libvirt
qemu:///system

ana@host:~$ virsh net-list --all
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes
```

`groups` now lists `libvirt`, and `virsh uri` answers **`qemu:///system`**, the guests the whole
computer shares. Before, it answered `qemu:///session`: a private set of guests for your user alone,
where `virsh list` shows nothing and nothing complains, while every guest made with `sudo` lives in
the other one. The `default` network is **active** and starts with the computer, and the first guest
will be plugged into it.
