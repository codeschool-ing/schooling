---
title: The base disk
version: 1
---

Every guest in this course starts from one disk that already has Ubuntu on it, the lab's **base**.
Installing Ubuntu from an ISO for every guest would take twenty minutes and a dozen answers each time.
Instead the base is Ubuntu's **minimal cloud image**, a disk Canonical publishes with the system
already installed and nothing else, made to be copied. It comes with a list of checksums, and the
first thing to do with a download is to check it against that list:

```
ana@host:~$ curl -sSLO https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img
ana@host:~$ curl -sSLO https://cloud-images.ubuntu.com/minimal/releases/noble/release/SHA256SUMS
ana@host:~$ sha256sum --check --ignore-missing SHA256SUMS
ubuntu-24.04-minimal-cloudimg-amd64.img: OK
```

`curl -O` keeps the file under its own name, `-L` follows a redirect and `-sS` stays quiet unless
something fails. `sha256sum --check` computed the image's checksum and found it in `SHA256SUMS`:
**`OK`**. `--ignore-missing` skips the other files the list names, which were not downloaded. A file that
was cut short or changed on the way says `FAILED` here instead, and is downloaded again.

The image is used as it is, plus five programs the lessons need inside every guest, which go in now
because some later guests have no internet to fetch them: `qemu-guest-agent`, lesson 3; `nginx-light`,
a small web server, switched off until a lesson starts it; and `curl`, `netcat-openbsd` and `tcpdump`,
for testing networks. `virt-customize` puts them in **without starting the image as a guest**: it boots
a tiny helper system of its own with the disk attached, runs `apt` inside, and writes the result back.
It works on a copy, so the download stays as it came:

```
ana@host:~$ cp ubuntu-24.04-minimal-cloudimg-amd64.img lab-base.qcow2
ana@host:~$ sudo virt-customize -a lab-base.qcow2 --install qemu-guest-agent,nginx-light,curl,netcat-openbsd,tcpdump --run-command "systemctl disable nginx" --truncate /etc/machine-id
[   0.0] Examining the guest ...
[  40.1] Setting a random seed
virt-customize: warning: random seed could not be set for this type of guest
[  40.5] Setting the machine ID in /etc/machine-id
[  40.5] Installing packages: qemu-guest-agent nginx-light curl netcat-openbsd tcpdump
[ 146.2] Running: systemctl disable nginx
[ 148.1] Truncating: /etc/machine-id
[ 148.1] SELinux relabelling
[ 149.1] Finishing off
```

It took about two and a half minutes here, most of it installing. The two `machine-id` lines are worth a
look. Ubuntu leaves `/etc/machine-id` empty in the image so that each machine made from it invents its
own on its first boot; `virt-customize` filled it in, and `--truncate` emptied it again. Without that,
every guest in the lab would share one identity, which is a problem lesson 10 spends a whole section on.

Last, the base goes where libvirt keeps disks, and becomes **read-only**:

```
ana@host:~$ sudo mv lab-base.qcow2 /var/lib/libvirt/images/ && sudo chmod 444 /var/lib/libvirt/images/lab-base.qcow2
ana@host:~$ sudo ls -lh /var/lib/libvirt/images/
total 620M
-r--r--r-- 1 ana ana 620M Oct  7 05:35 lab-base.qcow2
```

`chmod 444` is not tidiness. Every guest will read from this file, so one write into it changes every
guest at once. And there is a command that writes into it by default: lesson 9 shows it failing against
this file, which is the only reason it fails.
