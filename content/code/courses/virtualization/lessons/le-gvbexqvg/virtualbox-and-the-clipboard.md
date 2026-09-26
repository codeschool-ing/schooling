---
title: VirtualBox, VMware and the clipboard
version: 1
---

In VirtualBox the same folder is one command, and the clipboard and drag and drop are settings of the
machine:

```
ana@host:~$ VBoxManage sharedfolder add lab1 --name docs --hostpath /srv/docs --readonly --automount
ana@host:~$ VBoxManage modifyvm lab1 --clipboard-mode bidirectional --drag-and-drop hosttoguest
ana@host:~$ VBoxManage showvminfo lab1 --machinereadable | grep -E "^(SharedFolder|clipboard|draganddrop)"
clipboard="bidirectional"
draganddrop="hosttoguest"
SharedFolderNameMachineMapping1="docs"
SharedFolderPathMachineMapping1="/srv/docs"
```

`--readonly` and `--automount` did what they say. In a guest with the **Guest Additions**, an automounted
share appears as `/media/sf_docs` on Linux, readable by members of the group `vboxsf`, which a user must
be added to first, or as a network drive on Windows. VMware's shared folders come with **VMware Tools**
and appear under `/mnt/hgfs` on Linux.

**The shared clipboard** copies text between the host's desktop and the guest's, and **drag and drop**
moves files the same way. Both need the guest's agent and a graphical desktop in the guest, so neither
can be shown on this course's host, whose guests have no screen. Each can be set to *disabled*, *host to
guest*, *guest to host* or *bidirectional*, and that choice is a security one as much as a comfort one:
**a bidirectional clipboard hands the guest whatever you copy on the host**, a password from your
password manager included. For a guest you do not trust, *disabled* is the setting; for one you only
feed files into, *host to guest*, as `lab1` has for drag and drop.
