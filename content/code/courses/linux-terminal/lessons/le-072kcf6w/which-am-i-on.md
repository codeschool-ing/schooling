---
title: The first command on any machine
version: 1
---

Everything in this lesson reduces to one reflex. You reach a machine you did not set up, and
before you type anything that changes it, you ask what it is.

```
ana@vm:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
```

Two seconds, and it answers the six questions of the previous section at once.

## The two fields that matter

**`ID`** is the distribution — `ubuntu`, `debian`, `rocky`, `alpine`, `opensuse-leap`.

**`ID_LIKE`** is the family, and it is the one that decides what you type. A distribution you have
never heard of that says `ID_LIKE=debian` is one whose package manager is `apt`, whose web server
is `apache2`, and whose security framework is AppArmor. **You already know how to operate it.**

`ID_LIKE` is absent on the family heads — Debian itself has no `ID_LIKE`, because it is not like
anything else. Its absence is information too.

**`VERSION_ID`** is the third, and it is what you check against section 09's table when you want to
know whether this machine is still supported.

## Why this file and not the older ones

Section 04 showed an Ubuntu machine answering the older question:

```
ana@vm:~$ cat /etc/debian_version
trixie/sid
```

That is the same machine, and read as "which system am I on" it is wrong. `/etc/debian_version`,
`/etc/redhat-release`, `/etc/SuSE-release` are per-family files from before there was a standard.
They still exist, and each one answers a slightly different question in a slightly different
format.

`/etc/os-release` was created so that **one file, with the same field names, exists on every
distribution**. It is the question that always works, which is why it is the one to make a habit
of.

## The other two, and what they are for

```
ana@vm:~$ uname -a
Linux vm 6.18.44-fc-v24 #1 SMP PREEMPT_DYNAMIC @0 x86_64 x86_64 x86_64 GNU/Linux
```

`uname` is the **kernel**, not the distribution. The `6.18.44` is the kernel version, `x86_64` is
the processor architecture, and `vm` is the hostname. It answers a different question, and it is
the one to ask when a piece of software says it needs a particular kernel or architecture.

And the third tool, which is worth showing because of how it fails:

```
ana@vm:~$ hostnamectl
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

`hostnamectl` gives a tidy summary — distribution, kernel, architecture, hostname, hardware — and
**it is part of systemd**, so inside a container it cannot answer at all. Same cause as the
`systemctl` message in lesson 1 section 04, and the same reading: nothing is broken, nothing
booted.

Which is the practical reason `/etc/os-release` is the reflex and `hostnamectl` is the convenience:
**one of them is a file, and files do not need a running init system.**

## The habit, in three lines

```
cat /etc/os-release     # which distribution, which family, which version
uname -a                # which kernel, which architecture
whoami                  # and who I am here — lesson 1, section 14
```

Three commands, none of which changes anything. Run them before the fourth one that does.
