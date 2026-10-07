---
title: Building the server
version: 1
---

Half an hour, most of it waiting. Lesson 3 explains every screen of the installer; this section gives
the answers, so that the machine exists before the first command.

## 1. Download the installer, and check it

From `ubuntu.com/download/server`, download **Ubuntu Server 24.04 LTS**, a file of about 4 GB, and from
the same release page the small file `SHA256SUMS`. On an Apple-silicon Mac, take the `arm64` installer
instead. Then check that the file you have is the file Canonical published. On a Linux computer it
is one command:

```
ana@laptop:~/Downloads$ ls
SHA256SUMS  ubuntu-24.04.5-live-server-amd64.iso
ana@laptop:~/Downloads$ grep live-server-amd64 SHA256SUMS
c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b *ubuntu-24.04.3-live-server-amd64.iso
e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433 *ubuntu-24.04.4-live-server-amd64.iso
97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8 *ubuntu-24.04.5-live-server-amd64.iso
ana@laptop:~/Downloads$ sha256sum -c --ignore-missing SHA256SUMS
ubuntu-24.04.5-live-server-amd64.iso: OK
```

`SHA256SUMS` lists every file of the release, and `--ignore-missing` checks only the ones you have. The
`24.04.5` is the fifth refresh of 24.04, and yours may be a later one; any `24.04` is the same system.
`OK` is the only acceptable answer. On Windows and macOS the number comes from another command, and you
compare it by eye with the line for your file:

```sh
Get-FileHash .\ubuntu-24.04.5-live-server-amd64.iso      # Windows, in PowerShell
shasum -a 256 ubuntu-24.04.5-live-server-amd64.iso       # macOS, in Terminal
```

**Those two were not run for this course.** Lesson 3 comes back to why the check matters.

## 2. Create the virtual machine

In VirtualBox, *New*, and these answers. UTM and the others ask the same questions in other words.

- *Name*: `server`. *Type*: Linux, *Ubuntu (64-bit)*. *ISO image*: the file you downloaded.
- *Skip Unattended Installation*: **tick it.** Otherwise VirtualBox answers the installer for you,
  and the installer is what lesson 3 is about.
- *Memory*: 2048 MB. *Processors*: 2. *Hard disk*: 25 GB, not preallocated.

Start it. It boots from the ISO, the way a real computer boots from a USB stick.

## 3. Install

Answer the installer like this, and lesson 3 says what each choice means:

- Language and keyboard: the language you read, and **the keyboard you actually have**, because it is
  the one your password will be typed on.
- *Ubuntu Server*, not the *minimized* one. The network as it comes. *Use an entire disk*: the
  virtual one, which is empty.
- *Your name*, anything. *Your server's name*: `server`. *Pick a username*: your own. The transcripts say
  `ana`, and yours will say your name wherever they say hers. A password you will not forget.
- *Ubuntu Pro*: skip. *Install OpenSSH server*: **tick it.** Featured snaps: none.

When it says the installation is complete, choose *Reboot Now*, and press Enter if it asks you to remove
the installation medium. Sign in with your username and password.

## 4. Look at it, and bring it up to date

```
ana@server:~$ hostname
server
ana@server:~$ grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
ana@server:~$ id
uid=1000(ana) gid=1000(ana) groups=1000(ana),27(sudo)
```

The right name, the right system, and your account in the `sudo` group, which lets it run administrator
commands. Then the updates, which lesson 3 takes apart line by line:

```sh
sudo apt update
sudo apt upgrade -y
```

## 5. PowerShell 7

PowerShell is not in Ubuntu's own catalogue, so `apt` cannot find it until you add Microsoft's. The
release number in `/etc/os-release` picks the right one:

```
ana@server:~$ source /etc/os-release
ana@server:~$ wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
ana@server:~$ sudo dpkg -i packages-microsoft-prod.deb
Selecting previously unselected package packages-microsoft-prod.
(Reading database ... 37575 files and directories currently installed.)
Preparing to unpack packages-microsoft-prod.deb ...
Unpacking packages-microsoft-prod (1.2-ubuntu24.04) ...
Setting up packages-microsoft-prod (1.2-ubuntu24.04) ...
ana@server:~$ sudo apt update > apt.log 2>&1; grep microsoft apt.log
Get:5 https://packages.microsoft.com/ubuntu/24.04/prod noble InRelease [3600 B]
Get:6 https://packages.microsoft.com/ubuntu/24.04/prod noble/main amd64 Packages [519 kB]
Get:7 https://packages.microsoft.com/ubuntu/24.04/prod noble/main all Packages [643 B]
Get:8 https://packages.microsoft.com/ubuntu/24.04/prod noble/main arm64 Packages [463 kB]
Get:9 https://packages.microsoft.com/ubuntu/24.04/prod noble/main armhf Packages [12.6 kB]
ana@server:~$ sudo apt install -y powershell > pwsh.log 2>&1; grep "^Setting up" pwsh.log
Setting up powershell (7.6.6-1.deb) ...
ana@server:~$ pwsh --version
PowerShell 7.6.6
ana@server:~$ rm packages-microsoft-prod.deb apt.log pwsh.log
```

The package `packages-microsoft-prod` contains no program, only the address of Microsoft's catalogue and
the key that proves a package came from there. After it, `apt update` reads that catalogue too, and
`powershell` is found like any other package; lesson 11 is about how that works. The last line removes
the three files the installation left in your home folder, which nothing needs any more. Type `pwsh` and the
prompt becomes `PS /home/ana>`, which is how every PowerShell line in this course begins; `exit` comes
back to bash.

## 6. Save it as it is now

In VirtualBox, *Snapshots*, *Take*, and call it `fresh`. A snapshot is the whole machine at that moment.
When a later lesson leaves the server in a state you cannot explain, *Restore* puts it back in seconds.
Hyper-V calls the same thing a *checkpoint*; in UTM, *Clone* the stopped machine and keep the copy.

**Typing from your own terminal** is optional and pleasant: the server's window does not let you paste,
and your own terminal does. With VirtualBox, *Settings*, *Network*, *Advanced*, *Port Forwarding*, add a rule from
host port `2222` to guest port `22`, and then, on your computer:

```sh
ssh -p 2222 ana@127.0.0.1      # your username, not ana
```

**Not run for this course**, like every step of this section that happens outside the server.
