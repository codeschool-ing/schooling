---
title: The guest agent
version: 1
---

The host can describe a guest's hardware, but what happens inside is the guest's business: its
address, its file systems, its version of Ubuntu. To learn those, the host asks a small service
**inside** the guest, the **guest agent**, `qemu-guest-agent`, through a private channel that is not
the network:

```
ana@host:~$ virsh qemu-agent-command vm1 "{\"execute\":\"guest-get-osinfo\"}" | python3 -m json.tool
{
    "return": {
        "name": "Ubuntu",
        "kernel-release": "6.8.0-139-generic",
        "version": "24.04.4 LTS (Noble Numbat)",
        "pretty-name": "Ubuntu 24.04.4 LTS",
        "version-id": "24.04",
        "kernel-version": "#139-Ubuntu SMP PREEMPT_DYNAMIC Sat Aug  1 03:52:05 UTC 2026",
        "machine": "x86_64",
        "id": "ubuntu"
    }
}
ana@host:~$ virsh domifaddr vm1 --source agent
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 lo         00:00:00:00:00:00    ipv4         127.0.0.1/8
 -          -                    ipv6         ::1/128
 enp1s0     52:54:00:ce:da:4e    ipv4         192.168.122.117/24
 -          -                    ipv6         fe80::5054:ff:fece:da4e/64

ana@host:~$ virsh domfsinfo vm1
 Mountpoint   Name    Type   Target
-------------------------------------
 /            vda1    ext4   vda
 /boot        vda16   ext4   vda
 /boot/efi    vda15   vfat   vda

ana@host:~$ virsh domtime vm1; date +%s
Time: 1790374001
1790374002
```

`guest-get-osinfo` answered with the guest's system and kernel. `domifaddr --source agent` gave the
address inside, `192.168.122.117`, straight from the guest rather than from the DHCP server's records. `domfsinfo`
listed what is mounted where. `domtime` read the guest's clock, and it agreed with host's `date +%s`
within a second.

Stop the agent inside, and the host is blind to all of that:

```
ana@host:~$ virsh domfsinfo vm1
error: Unable to get filesystem information
error: Guest agent is not responding: QEMU guest agent is not connected
```

**`Guest agent is not responding`** is one of the most common messages in any hypervisor's log, and it
almost always means the agent is not installed or not running inside, not that anything is broken.
The guest itself was fine. The agent is also what lets a hypervisor freeze a guest's file systems for a
consistent backup, so a guest without one gets a cruder copy.

Every hypervisor has one, under a different name. VirtualBox calls its package **Guest Additions** and
VMware calls its package **VMware Tools**, and both do more than this one: they match the guest's
screen to the window, share the clipboard and share folders, which is lesson 12. **Installing them is
the first thing to do in a new guest.**
