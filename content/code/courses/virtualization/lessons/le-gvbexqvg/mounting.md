---
title: Mounting them in the guest
version: 1
---

Inside, each folder is mounted by its tag, like any file system in the operating systems course:

```
ana@vm1:~$ sudo mkdir -p /mnt/share /mnt/docs && sudo mount -t 9p -o trans=virtio,version=9p2000.L share /mnt/share && sudo mount -t 9p -o trans=virtio,version=9p2000.L docs /mnt/docs && ls -l /mnt/share /mnt/docs
/mnt/docs:
total 4
-rw-r--r-- 1 ana ana 25 Sep 25 21:25 manual.txt

/mnt/share:
total 4
-rw-r--r-- 1 ana ana 16 Sep 25 21:25 from-host.txt
ana@vm1:~$ cat /mnt/share/from-host.txt /mnt/docs/manual.txt
written on host
how to reset the printer
```

`share` and `docs` are the tags from the description; `trans=virtio` says the files travel over a virtio
channel, lesson 8. Both folders show the host's files, and the guest can read them.

**A mount made by hand lasts until the guest reboots.** To keep it, it goes into `/etc/fstab`:

```
ana@vm1:~$ echo "share /mnt/share 9p trans=virtio,version=9p2000.L,nofail 0 0" | sudo tee -a /etc/fstab
share /mnt/share 9p trans=virtio,version=9p2000.L,nofail 0 0
ana@vm1:~$ sudo umount /mnt/share && sudo mount -a && findmnt /mnt/share
TARGET     SOURCE FSTYPE OPTIONS
/mnt/share share  9p     rw,relatime,access=client,trans=virtio
```

`nofail` matters here: if the host is ever started without the share, the guest still boots, without the
folder, instead of stopping at an emergency prompt. `mount -a` mounted everything in the file, and
`findmnt` shows the share back in place.
