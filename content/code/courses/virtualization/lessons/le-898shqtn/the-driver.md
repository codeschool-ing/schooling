---
title: VirtualBox, and the part in the kernel
version: 1
---

VirtualBox is a type 2 hypervisor, lesson 2, and it runs on Windows, macOS and Linux. It is free.
Oracle publishes it, with an optional *Extension Pack* under a different licence that adds a few
features, such as remote display, and which businesses may have to pay for.

It is an application, and it also installs a **driver in the host's kernel**, called `vboxdrv` on Linux,
to use the processor's virtualisation features. Here is VirtualBox 7.0.16 on this
course's host:

```
ana@host:~$ VBoxManage --version
WARNING: The character device /dev/vboxdrv does not exist.
         Please install the virtualbox-dkms package and the appropriate
         headers, most likely linux-headers-v37.

         You will not be able to start VMs until this problem is fixed.
7.0.16_Ubuntur162802
```

The warning comes from Ubuntu's wrapper around `VBoxManage`, which checks for the driver before every
command. Everything that only changes a machine's description works without it, and all of this
lesson does. **Starting a guest does not**, and section 07 shows the failure. On this computer the
driver cannot be loaded at all, because the processor offers it nothing to use, as lesson 2 found.

On a customer's Linux computer the same warning has two usual causes, and both are worth knowing
because nothing else in the message names them:

- **The kernel was updated** and the driver was not rebuilt for the new one. Reinstalling VirtualBox's
  kernel module package, or rebooting into the old kernel, brings it back.
- **Secure Boot is on**, and the firmware refuses to load a driver nobody signed. The fix is to sign it
  and enrol the key, which the installer usually offers to do on the next boot.

On Windows and on a Mac, the installer puts what VirtualBox needs in place along with the rest, and
asks for permission to do it.
