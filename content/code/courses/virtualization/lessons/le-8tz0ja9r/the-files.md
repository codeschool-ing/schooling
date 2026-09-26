---
title: A VMware machine on disk
version: 1
---

A Workstation machine is a folder, like a VirtualBox one, and the files in it have names worth knowing
by their endings, because a customer will read them to you:

| ending | what it is |
|---|---|
| `.vmx` | the machine's settings, as plain text, one `key = "value"` per line |
| `.vmdk` | a disk, or the small text file that describes a disk split into pieces |
| `-s001.vmdk`, `-s002.vmdk`… | the pieces of a split disk |
| `-000001.vmdk` | the changes made since a snapshot, lesson 9 |
| `.vmsd`, `.vmsn` | the list of snapshots, and the state saved with one |
| `.vmem`, `.vmss` | the guest's memory and state, while it is suspended |
| `.nvram` | the guest's firmware settings, its BIOS or UEFI |
| `vmware.log` | what happened the last time it ran: the first place to look when it will not start |

**The `.vmx` is what you open**: *File* → *Open* in Workstation takes a `.vmx`, or an `.ova`. To move a
machine, copy the whole folder with the guest switched off, not suspended, and open the `.vmx` on the
other side. Workstation then asks whether you *moved* it or *copied* it; answering *copied* gives the
guest a new identity and a new MAC, which is what you want when the original is still running
somewhere else.

Inside the guest, VMware's agent is **VMware Tools**, lesson 3's guest agent under another name. On
Linux it comes from the distribution as `open-vm-tools`, and many distributions install it by
themselves when they find they are running under VMware.
