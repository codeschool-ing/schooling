---
title: Whose rights?
version: 1
---

Now the guest writes into the shared folder:

```
ana@vm1:~$ echo "written in vm1" > /mnt/share/from-guest.txt
bash: line 1: /mnt/share/from-guest.txt: Permission denied
ana@host:~$ ls -ld /srv/share; ps -o user= -C qemu-system-x86_64
drwxr-xr-x 2 ana ana 4096 Sep 25 21:25 /srv/share
libvirt-qemu
ana@host:~$ sudo chgrp kvm /srv/share && sudo chmod g+w /srv/share
ana@vm1:~$ echo "written in vm1" > /mnt/share/from-guest.txt && ls -l /mnt/share
total 12
-rw-rw-r-- 1 ana ana 15 Sep 25  2026 from-guest.txt
-rw-r--r-- 1 ana ana 16 Sep 25 21:25 from-host.txt
ana@host:~$ ls -l /srv/share && cat /srv/share/from-guest.txt
total 12
-rw------- 1 libvirt-qemu kvm 15 Sep 25 21:28 from-guest.txt
-rw-r--r-- 1 ana          ana 16 Sep 25 21:25 from-host.txt
cat: /srv/share/from-guest.txt: Permission denied
ana@vm1:~$ echo "a note" > /mnt/docs/note.txt
bash: line 1: /mnt/docs/note.txt: Read-only file system
```

The first write was **refused**. Not by the guest: ana owns her files in there as far as vm1 knows. By
the host, because **every access to a shared folder is made by the hypervisor's process**, and `ps`
shows that process runs as `libvirt-qemu`. The folder belonged to ana with `drwxr-xr-x`, so
`libvirt-qemu` could read it and not write in it. Giving QEMU's group, `kvm`, the right to write fixed it.

Then the other half of the same rule. In the guest, `from-guest.txt` belongs to ana with `rw-rw-r--`. On
the host it belongs to **`libvirt-qemu`, `rw-------`**, and ana on the host cannot read it. That is what
`mapped` means: QEMU creates the file as itself, and keeps the guest's idea of its owner and mode aside,
in extended attributes, for the guest to see.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 180\" role=\"img\" aria-label=\"The path a shared-folder write takes. Inside vm1, ana writes a file and sees it as hers, rw-rw-r--. The request goes over 9p to QEMU, which is running on host as libvirt-qemu and writes with its own rights. On host, the file belongs to libvirt-qemu with mode rw-------, and the guest&#x27;s idea of the owner and mode is kept aside in extended attributes.\"><defs><marker id=\"sp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">inside vm1: ana, rw-rw-r--</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"272\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">QEMU, running as libvirt-qemu</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">on host: libvirt-qemu, rw-------</text><path d=\"M222 65 L258 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><path d=\"M462 65 L498 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sp-ah)\"></path><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">asks as ana</text><text x=\"260\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">writes with its own rights</text><text x=\"500\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">keeps ana and rw-rw-r--</text><text x=\"500\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in extended attributes</text></svg>", "caption": "Every access to a shared folder is made by the hypervisor’s process, with that process’s rights. So the folder has to let QEMU in, and what the guest writes belongs, on the host, to QEMU."}
```

Nothing is broken here, and it is exactly the kind of thing a customer calls about: "the VM can't save to
the shared folder", "I can't open what the VM saved". The fix depends on the product, and the question is
always the same: **with whose rights is the hypervisor reaching this folder?**

The read-only share refused the last write outright: `Read-only file system`.
