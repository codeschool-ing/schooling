---
title: The disk, dynamic or fixed
version: 1
---

A machine needs a disk, a controller to plug it into, and usually an optical drive for the installer:

```
ana@host:~$ cd ~/"VirtualBox VMs"/lab1 && VBoxManage createmedium disk --filename lab1.vdi --size 20480
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Medium created. UUID: 2d68bc32-d25f-4071-9cf8-1d85af0f25e4
ana@host:~$ cd ~/"VirtualBox VMs"/lab1 && VBoxManage storagectl lab1 --name SATA --add sata && VBoxManage storageattach lab1 --storagectl SATA --port 0 --type hdd --medium lab1.vdi && VBoxManage storageattach lab1 --storagectl SATA --port 1 --type dvddrive --medium emptydrive
ana@host:~$ VBoxManage showmediuminfo ~/"VirtualBox VMs"/lab1/lab1.vdi | grep -E "^(Format variant|Capacity|Size on disk)"
Format variant: dynamic default
Capacity:       20480 MBytes
Size on disk:   2 MBytes
```

`createmedium` made a **VDI**, VirtualBox's own disk format, of 20480 MB. `storagectl` added a SATA
controller, and `storageattach` plugged the disk into port 0 and an **empty DVD drive** into port 1;
in the window, that drive is where you choose the ISO. `showmediuminfo` says the rest: the guest will be
told the disk holds 20480 MBytes, and the host has given it **2 MBytes**, because the variant is
`dynamic`, the default.

A disk can also be made **fixed**, all of it at once:

```
ana@host:~$ cd /tmp && VBoxManage createmedium disk --filename fixed.vdi --size 1024 --variant Fixed
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Medium created. UUID: 0791b75d-34a6-4a3e-b44b-236e27344c9e
ana@host:~$ ls -lh /tmp/fixed.vdi ~/"VirtualBox VMs"/lab1/lab1.vdi
-rw------- 1 ana ana 2.0M Sep 25 19:14 /home/ana/VirtualBox VMs/lab1/lab1.vdi
-rw------- 1 ana ana 1.1G Sep 25 19:14 /tmp/fixed.vdi
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Two virtual disks compared. A dynamically allocated disk of 20480 megabytes, which the guest is told is 20 GB, takes 2.0M on the host when it is new. A fixed-size disk of 1024 megabytes takes 1.1G on the host from the moment it is created, the whole of it.\"><defs><marker id=\"dk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"200\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the guest is told</text><text x=\"460\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the host gives up now</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dynamically allocated, 20480 MB</text><rect x=\"200\" y=\"66\" width=\"240\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20480 MB</text><rect x=\"460\" y=\"66\" width=\"2\" height=\"20\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"470\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2.0M</text><text x=\"20\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fixed size, 1024 MB</text><rect x=\"200\" y=\"136\" width=\"12\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1024 MB</text><rect x=\"460\" y=\"136\" width=\"13\" height=\"20\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"481\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.1G</text></svg>", "caption": "A dynamic disk costs the host almost nothing until the guest writes; a fixed one costs everything at once and never grows. The first is the default, and the right choice for a lab."}
```

The 1024 MB fixed disk takes 1.1G on the host the moment it exists, and the 20480 MB dynamic one
still takes 2.0M. A fixed disk is a little faster to write, because nothing has to be allocated
along the way, and it can never fill the host by surprise. **A dynamic disk is the right choice for a
lab**, where most guests are small and short-lived, and it is the reason ten guests fit on a laptop.
The catch is the one from lesson 1: a dynamic disk grows as the guest writes and never shrinks on its
own when the guest deletes, so keep an eye on the host's free space.
