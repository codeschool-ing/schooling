---
title: Building srv
version: 1
---

A deploy needs a second machine: a server, which is not the computer you write on. In the transcripts
the server is **srv** and the computer is Ana's **laptop**. You build your own srv once, in this
section, and lesson 16 uses it again.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04 on your computer, reachable only from it | 2 GB of memory while it runs, and 10 GB of disk | match as printed |
| **a spare computer** | Ubuntu Server 24.04 on a real machine on your home network | an old computer you can wipe | match; its address is your network's |
| **online** | a small rented server, with a public address | a monthly fee, or a free tier on its provider's terms | match, and the last section applies at once |

**The virtual machine is the recommended path.** It costs nothing, it can be thrown away and built
again in minutes, and nothing on it is exposed to the internet while you are still learning what a
server needs. **Multipass**, from Canonical, the company behind Ubuntu, is free and builds an Ubuntu
Server virtual machine with one command. It uses the hypervisor your system already has: Hyper-V on
Windows Pro, Enterprise and Education, VirtualBox on Windows Home, QEMU on a Mac, and KVM on Linux.
On Windows and macOS it comes as an installer from its own site; on Ubuntu, `sudo snap install multipass`.

**A spare computer** works the same once Ubuntu Server 24.04 is installed on it from the official
image, with the *OpenSSH server* option ticked during the installation. **Online**, almost every hosting
provider sells a small virtual server, and some have a free tier; none is needed to finish this lesson,
and the last section lists what to check before trusting one. On both, the file below still applies:
an online provider usually takes it as *user data* when the server is created, and on a spare computer
you do by hand what it asks for.

## A key, and a file that describes srv

ssh lets you into srv with a **key** rather than a password: a pair of files, a private half that never
leaves your computer and a public half you hand to every machine that should let you in. Make one, unless
`~/.ssh/id_ed25519.pub` already exists:

```
ana@laptop:~$ ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
Created directory '/home/ana/.ssh'.
Generating public/private ed25519 key pair.
Your identification has been saved in /home/ana/.ssh/id_ed25519
Your public key has been saved in /home/ana/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:eRQ1yT6V3oGJwy9kUSMTxZ1flTAPIrspTkvLK+/8lTQ ana@laptop
The key's randomart image is:
+--[ED25519 256]--+
|         .oOXO=.=|
|          oB*=B=.|
|         .+.oo o+|
|         oo.o.. o|
|       +So.E..   |
|      = +.. o    |
|       =   o     |
|     .. . .      |
|      +=..       |
+----[SHA256]-----+
ana@laptop:~$ cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLnYX4B+/TJmCeRjHgeZURWQ3gFJ2X9iQWSKbb/LOs7 ana@laptop
```

`-N ""` leaves the private half without a passphrase. For a key that opens one machine only your computer
can reach, that is a fair trade; for a key that opens anything public, give it a passphrase. The line
`cat` printed is the public half, and it goes into the file that describes srv:

```yaml
#cloud-config
# srv, the server this course deploys to. cloud-init reads this file the
# first time the machine boots, and never again.
hostname: srv
users:
  - name: ana
    shell: /bin/bash
    groups: [sudo]
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    ssh_authorized_keys:
      - paste the line from ~/.ssh/id_ed25519.pub here
ssh_pwauth: false
package_update: true
packages:
  - podman
  - caddy
  - git
  - python3
  - curl
```

This is a **cloud-init** file. cloud-init runs on the first boot of an Ubuntu Server machine, reads a file
like this one and does what it says. This one names the machine `srv` and creates the account `ana` with
your public key in it. It turns off logging in with a password, and installs Podman, Caddy, git, Python
and curl from Ubuntu's own packages. Save it as `srv.yaml`, put **your** public key on the line that
asks for it, and write your own user name where it says `ana`. The `sudo` line lets that account run
`sudo` without a password, since srv.yaml never sets one; that is fine on a machine only your computer
reaches, and wrong on a public one.

Then the machine itself, which takes a few minutes the first time:

```sh
multipass launch 24.04 --name srv --cpus 2 --memory 2G --disk 10G --cloud-init srv.yaml
multipass info srv
```

These two were **not run for this course**: the computer that recorded it has no hardware
virtualisation, so its srv is a container that cloud-init built from this same file. `multipass info`
prints, among other things, srv's **IPv4** address, which is what the next step needs.

## Reaching it by name

Typing an address every time is how mistakes happen, so give it a name in `~/.ssh/config`, with the
address from `multipass info` and your user name:

```
ana@laptop:~$ printf 'Host srv\n    HostName 10.20.0.20\n    User ana\n' >> ~/.ssh/config
ana@laptop:~$ cat ~/.ssh/config
Host srv
    HostName 10.20.0.20
    User ana
```

From now on `ssh srv` means *that address, as that user*, and so does every `git` command that names
`srv:`. The first connection asks a question:

```
ana@laptop:~$ ssh srv hostname
The authenticity of host '10.20.0.20 (10.20.0.20)' can't be established.
ED25519 key fingerprint is SHA256:oIhKjQaT+HpopLWEVJTAyWCGN3xEs9te+VCtDIKW25c.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.20.0.20' (ED25519) to the list of known hosts.
srv
```

ssh has never seen this machine, so it shows the fingerprint of srv's own key and asks whether to trust
it. On a network you control, *yes* is right; ssh writes the key down and, from then on, refuses to talk
to any other machine claiming to be srv. If you want to be sure, `multipass exec srv -- ssh-keygen -lf
/etc/ssh/ssh_host_ed25519_key.pub` prints the same fingerprint from srv's side.

srv answered with its name, but cloud-init may still be installing. Wait for it, then ask for the tools:

```
ana@laptop:~$ ssh srv cloud-init status --wait
............................................................................status: done
ana@laptop:~$ ssh srv "podman --version; caddy version; git --version; python3 --version"
podman version 4.9.3
2.6.2
git version 2.43.0
Python 3.12.3
```

Each dot is a second of waiting, and `done` means every line of srv.yaml has been carried out. srv now
has everything the rest of this lesson uses. If any step here went differently, the next section is
about exactly that.
