---
title: Attaching two folders
version: 1
---

Two folders on host, one to share for working in and one for documents the guest should only read.
Each is added to vm1's description as a **filesystem** device, with a **tag** the guest will use to find
it:

```
ana@host:~$ ls -l /srv/share /srv/docs
/srv/docs:
total 4
-rw-r--r-- 1 ana ana 25 Sep 25 21:25 manual.txt

/srv/share:
total 4
-rw-r--r-- 1 ana ana 16 Sep 25 21:25 from-host.txt
ana@host:~$ virt-xml vm1 --add-device --filesystem source=/srv/share,target=share,accessmode=mapped
Domain 'vm1' defined successfully.
Changes will take effect after the domain is fully powered off.
ana@host:~$ virt-xml vm1 --add-device --filesystem source=/srv/docs,target=docs,accessmode=mapped,readonly=on
Domain 'vm1' defined successfully.
Changes will take effect after the domain is fully powered off.
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ virsh start vm1
Domain 'vm1' started

ana@host:~$ virsh dumpxml vm1 | grep -A5 "<filesystem"
    <filesystem type='mount' accessmode='mapped'>
      <source dir='/srv/share'/>
      <target dir='share'/>
      <alias name='fs0'/>
      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </filesystem>
    <filesystem type='mount' accessmode='mapped'>
      <source dir='/srv/docs'/>
      <target dir='docs'/>
      <readonly/>
      <alias name='fs1'/>
      <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
```

`accessmode=mapped` decides how ownership is handled, which section 05 is about. `readonly=on` made the
second one read-only, and the description shows it as `<readonly/>`. Like the hardware changes of lesson
8, a new device waits for the guest to be switched off and on.

This is QEMU's own way of sharing, called **9p**; newer setups use **virtiofs**, which is faster and does
the same job. VirtualBox and VMware do it through their guest packages, section 07.
