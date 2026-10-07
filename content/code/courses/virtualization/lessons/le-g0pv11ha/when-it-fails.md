---
title: When the setup fails
version: 1
---

Every failure below happened while this lesson was being recorded, on the computer it was recorded on,
and each comes with what it looks like and what fixes it. Most of them fail loudly. Two of them do not,
and those are the ones to remember.

**The processor gives no help.** `kvm-ok` said `KVM acceleration can NOT be used` in section 03, and the
device KVM works through is not there at all:

```
ana@host:~$ ls -l /dev/kvm
ls: cannot access '/dev/kvm': No such file or directory
```

The lab still works: `virt-install` falls back to QEMU's imitation by itself, with the warning from
section 06, and every guest is several times slower, which lesson 2 measures. To get the speed back,
first switch on *Intel Virtualization Technology*, *VT-x*, *SVM Mode* or *AMD-V* in the computer's UEFI
setup, since many PCs ship with it off. On Windows, a lab in a virtual machine competes for the same
feature with Hyper-V, WSL 2 and memory integrity, which lesson 2 explains. In a virtual machine or a
rented server, switch on nested virtualisation, section 02, or accept the speed.

**`virsh list` shows nothing, and no error.** That is the session from before your next login, section
03: `virsh uri` says `qemu:///session`, and you are looking at a private, empty list while your guests
run in the system's. Log out and in, and check that `groups` includes `libvirt`.

**A disk in your home folder.** libvirt opens a guest's disks as its own user, and your home folder is
closed to other users:

```
ana@host:~$ ls -ld ~ && sudo virt-install --name vm2 --memory 1024 --vcpus 2 --import --disk ~/vm2.qcow2,bus=virtio --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole
drwxr-x--- 5 ana ana 4096 Oct  7 05:42 /home/ana
WARNING  KVM acceleration not available, using 'qemu'
WARNING  /home/ana/vm2.qcow2 may not be accessible by the hypervisor. You will need to grant the 'libvirt-qemu' user search permissions for the following directories: ['/home/ana']
WARNING  Requested memory 1024 MiB is less than the recommended 3072 MiB for OS ubuntu24.04
ERROR    Cannot access storage file '/home/ana/vm2.qcow2' (as uid:64055, gid:995): Permission denied
Domain installation does not appear to have been successful.
If it was, you can restart your domain by running:
  virsh --connect qemu:///system start vm2
otherwise, please restart your installation.

Starting install...
```

`drwxr-x---` lets in you and your group, and `uid:64055` is `libvirt-qemu`, which is neither. The fix is
to keep the lab's disks in `/var/lib/libvirt/images`, as every command in this course does, and not to
open your home folder to everybody instead.

**The default network will not start.** A computer that is itself a libvirt guest is the second path
in section 02 with QEMU as the outer hypervisor, and its outer network very often uses the same
`192.168.122.0/24` as the inner one. Here a second interface was given that range on purpose, to show
it:

```
ana@host:~$ virsh net-start default
error: Failed to start network default
error: internal error: Network is already in use by interface office0
```

libvirt refuses rather than make two networks with one range. The fix is to give the inner network
another range: `virsh net-edit default`, change `192.168.122` to `192.168.123` in the three places it
appears, and `virsh net-start default`.

**virt-customize cannot reach the internet.** This is what happens on Ubuntu 24.04 without
`isc-dhcp-client`:

```
ana@host:~$ cp ubuntu-24.04-minimal-cloudimg-amd64.img try.qcow2
ana@host:~$ sudo virt-customize -a try.qcow2 --install qemu-guest-agent,nginx-light,curl,netcat-openbsd,tcpdump --run-command "systemctl disable nginx" --truncate /etc/machine-id
[   0.0] Examining the guest ...
[  53.4] Setting a random seed
virt-customize: warning: random seed could not be set for this type of guest
[  53.8] Setting the machine ID in /etc/machine-id
[  53.8] Installing packages: qemu-guest-agent nginx-light curl netcat-openbsd tcpdump
Ign:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Ign:2 http://archive.ubuntu.com/ubuntu noble InRelease
Ign:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Ign:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Ign:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Ign:2 http://archive.ubuntu.com/ubuntu noble InRelease
Ign:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Ign:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Ign:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Ign:2 http://archive.ubuntu.com/ubuntu noble InRelease
Ign:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Ign:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Err:1 http://security.ubuntu.com/ubuntu noble-security InRelease
  Temporary failure resolving 'security.ubuntu.com'
Err:2 http://archive.ubuntu.com/ubuntu noble InRelease
  Temporary failure resolving 'archive.ubuntu.com'
Err:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
  Temporary failure resolving 'archive.ubuntu.com'
Err:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
  Temporary failure resolving 'archive.ubuntu.com'
Reading package lists...
W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/noble/InRelease  Temporary failure resolving 'archive.ubuntu.com'
W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/noble-updates/InRelease  Temporary failure resolving 'archive.ubuntu.com'
W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/noble-backports/InRelease  Temporary failure resolving 'archive.ubuntu.com'
W: Failed to fetch http://security.ubuntu.com/ubuntu/dists/noble-security/InRelease  Temporary failure resolving 'security.ubuntu.com'
W: Some index files failed to download. They have been ignored, or old ones used instead.
Reading package lists...
Building dependency tree...
Reading state information...
E: Unable to locate package qemu-guest-agent
E: Unable to locate package nginx-light
E: Unable to locate package netcat-openbsd
E: Unable to locate package tcpdump
virt-customize: error: 
      export DEBIAN_FRONTEND=noninteractive
      apt_opts='-q -y -o Dpkg::Options::=--force-confnew'
      apt-get $apt_opts update
      apt-get $apt_opts install 'qemu-guest-agent' 'nginx-light' 'curl' 'netcat-openbsd' 'tcpdump'
    : command exited with an error

If reporting bugs, run virt-customize with debugging enabled and include the complete output:

  virt-customize -v -x [...]
```

`Temporary failure resolving` means the helper system had no network at all. Its startup asks for an
address with `dhclient`, which that package provides and Ubuntu 24.04 no longer installs, and nothing
says that is the reason. `sudo apt install isc-dhcp-client` fixes it. Then **start again from a fresh
copy** of the downloaded image, because the failed run had already written into this one.

**The guest runs, has an address, and will not let you in.** This one is silent, and it is a mistake in
the seed. Here the first line of `user-data` was left out:

```
ana@host:~$ head -2 user-data
hostname: vm2
users:
ana@host:~$ ssh vm2 hostname
ana@vm2: Permission denied (publickey).
ana@host:~$ virsh domifaddr vm2 --source agent
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 lo         00:00:00:00:00:00    ipv4         127.0.0.1/8
 -          -                    ipv6         ::1/128
 enp1s0     52:54:00:95:11:31    ipv4         192.168.122.116/24
 -          -                    ipv6         fe80::5054:ff:fe95:1131/64
```

The guest agent answered, so the guest is up and on the network, and ssh still said `Permission
denied (publickey)`: without `#cloud-config` the file was ignored, no user was made and no key was let
in. Delete the guest, `virsh destroy vm2` and `virsh undefine vm2`, fix the file, and make the seed and
the guest again; a seed is only read on the first boot.

**`REMOTE HOST IDENTIFICATION HAS CHANGED`.** ssh says this, in capitals, when a name it knows presents
a different key. In this lab it happens every time a guest is deleted and a new one made under the same
name, which is often. `ssh-keygen -R vm1` forgets the old key, and `newvm.sh` does it for you.
