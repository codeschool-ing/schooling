---
title: The seed disk, by hand
version: 1
---

A cloud image has no user you could log in as and no password anybody knows, on purpose. It runs a
program called **cloud-init** on its first boot, which looks for its settings on a small extra disk,
the **seed**, and does what they say: give the machine a name, make a user, let a key in.

The key is yours. An **ssh key** is a pair of files: the private half stays on the host and the public
half goes into every guest, and then `ssh` logs you in without a password. If `~/.ssh/id_ed25519`
already exists, you have one; skip the first command, or it asks before overwriting it.

```
ana@host:~$ ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
Created directory '/home/ana/.ssh'.
Generating public/private ed25519 key pair.
Your identification has been saved in /home/ana/.ssh/id_ed25519
Your public key has been saved in /home/ana/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:iEeA/7cFXOXv44SyrgqUMV0hZZDVRCd0Zgy+2l/XIl8 ana@host
The key's randomart image is:
+--[ED25519 256]--+
|   .. o=***+*    |
|  .  o.+ .oB.    |
|   .o o. .. .    |
|    .* .o  . .   |
|    +.o S..   .  |
|   . .. .o.  o  .|
|    .  ..oo o * E|
|     .  .  + * = |
|      ...oo . o  |
+----[SHA256]-----+
```

`-N ""` gives the key no passphrase, which is a convenience for a lab on your own computer and not a
habit for a key that opens anything else. Then the settings, in a file called `user-data`:

```
ana@host:~$ cat > user-data <<EOF
> #cloud-config
> hostname: vm1
> users:
>   - name: $USER
>     sudo: ALL=(ALL) NOPASSWD:ALL
>     shell: /bin/bash
>     ssh_authorized_keys: [ "$(cat ~/.ssh/id_ed25519.pub)" ]
> EOF
ana@host:~$ cat user-data
#cloud-config
hostname: vm1
users:
  - name: ana
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys: [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxorodEdZ/92A9HlMVJICfxiPyvSd18CxzbYDlw1lYz ana@host" ]
```

The **first line has to be `#cloud-config`** exactly: it is how cloud-init knows what kind of file this
is, and without it the file is ignored in silence, which section 11 shows. The rest names the machine
and makes a user with `sudo` that asks no password. `$USER` and `$(cat ...)` were replaced as the file
was written: by **your own user name**, so that `ssh vm1` from your account logs in as the same name,
and by the public key itself.

`cloud-localds` turns the file into a disk image, with the label cloud-init looks for:

```
ana@host:~$ sudo cloud-localds /var/lib/libvirt/images/vm1-seed.img user-data
```

It prints nothing when it works. The seed goes in the same folder as the guest's disk, because libvirt
reads disks as a user of its own, `libvirt-qemu`, which cannot see into your home folder.
