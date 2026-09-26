---
title: Sealing a template
version: 1
---

Removing a machine's identity so that each copy makes its own is called **sealing** it, or
*generalising* it, and the sealed machine is a **template**. On an Ubuntu cloud image, cloud-init
does most of it:

```
ana@vm1:~$ cat /etc/machine-id; ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d" " -f2
f2b0a97d568b4cd0bb0179512eaab5f9
SHA256:SUFzDOz3YLtSwoKTtEuZewisO99n/s8q8qZUtrMDzHM
ana@vm1:~$ sudo cloud-init clean --logs --seed --machine-id --configs all && sudo rm -f /etc/ssh/ssh_host_* && cat /etc/machine-id && ls /etc/ssh/ssh_host_* 2>&1
uninitialized
ls: cannot access '/etc/ssh/ssh_host_*': No such file or directory
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ virsh undefine vm1 && cd /var/lib/libvirt/images && sudo mv vm1.qcow2 template.qcow2 && sudo chmod 444 template.qcow2 && ls -l template.qcow2
Domain 'vm1' has been undefined

-r--r--r-- 1 root root 38731776 Sep 25 20:52 template.qcow2
```

Before: vm1's machine-id was `f2b0a97d568b4cd0bb0179512eaab5f9` and its host key's fingerprint `SHA256:SUFzDOz3YLtSwoKTtEuZewisO99n/s8q8qZUtrMDzHM`. `cloud-init clean`
forgot everything it did on the first boot: `--logs` its logs, `--seed` the settings it was given, and
`--machine-id` the machine-id, now `uninitialized` so the next boot makes a new one. `--configs all`
removed the files it wrote, **the network configuration pinned to vm1's MAC** among them. The host keys were
deleted by hand, and the next boot generates new ones. Then vm1 was switched off, removed from libvirt,
and its disk kept, renamed and made **read-only**, like the lab's base.

Sealing is always the last thing done to a template, because **booting it again undoes it**: the first
boot after `cloud-init clean` builds a new identity, and the template would carry that one to every
copy. To update a template, make a machine from it, change that, and seal that.

Windows is sealed with **Sysprep**:

```sh
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown   # Windows: remove this machine's identity, then switch off
```

**It was not run for this lesson.** `/generalize` removes the identity, `/oobe` makes the next boot run
the first-start screens, and `/shutdown` switches it off so it cannot boot again by accident. Proxmox's
*Convert to template* and VMware's *Convert to Template* mark a machine as a template, and do not seal
it: that is still yours to do first.
