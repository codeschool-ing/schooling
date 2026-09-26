---
title: The other doors
version: 1
---

The network is one way between guest and host. Lesson 12 opened two more on purpose, and a lab that
runs anything you do not trust keeps them shut. In libvirt, the guest's description says which devices
it has:

```
ana@host:~$ virsh dumpxml client | grep -E "<(interface|filesystem|graphics|channel) "
    <interface type='network'>
    <channel type='unix'>
ana@host:~$ VBoxManage modifyvm lab1 --clipboard-mode disabled --drag-and-drop disabled --nic1 intnet --intnet1 labnet && VBoxManage showvminfo lab1 --machinereadable | grep -E "^(clipboard|draganddrop|nic1|intnet1)="
intnet1="labnet"
nic1="intnet"
clipboard="disabled"
draganddrop="disabled"
```

The client has **an interface on a network and one channel**, the guest agent's, which lets the host
ask the guest things and gives the guest nothing on the host. **No `filesystem`**, so no shared folder;
**no `graphics`**, so no screen to carry a clipboard or drag and drop.

VirtualBox keeps the same doors as settings. `lab1` started with the clipboard shared both ways, drag and
drop from host to guest and NAT, lesson 12's arrangement; one command turns off the first two and puts
its network card on an **internal network**, VirtualBox's name for lesson 11's fourth mode: the guests
reach each other, and the host has no address on it at all, so there is no host service to reach.

Before a guest runs something you do not trust, then:

| door | closed by | checked from inside by |
| --- | --- | --- |
| the real network | an isolated or internal network | no `default via` line |
| the host's services | a firewall rule on the host, or an internal network | `nc -z` to the host fails |
| a shared folder | no `filesystem` device, no shared folder setting | no `9p` or `virtiofs` mount |
| the clipboard, drag and drop | no graphics, or both set to disabled | no clipboard agent running |

Then take a snapshot, lesson 9, so whatever happens in the guest can be undone with one command.
