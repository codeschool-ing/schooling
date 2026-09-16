---
title: `apt`, and reading what it is about to do
version: 1
---

Here is a complete install, unedited, and it is worth reading before it is worth running:

```
root@vm:~# apt install cowsay
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  libtext-charwidth-perl
Suggested packages:
  filters cowsay-off
The following NEW packages will be installed:
  cowsay libtext-charwidth-perl
0 upgraded, 2 newly installed, 0 to remove and 168 not upgraded.
Need to get 27.9 kB of archives.
After this operation, 135 kB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://archive.ubuntu.com/ubuntu noble/main amd64 libtext-charwidth-perl amd64 0.04-11build3 [
9358 B]
Get:2 http://archive.ubuntu.com/ubuntu noble/universe amd64 cowsay all 3.03+dfsg2-8 [18.6 kB]
Fetched 27.9 kB in 0s (154 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package libtext-charwidth-perl:amd64.
(Reading database ... 58861 files and directories currently installed.)
Preparing to unpack .../libtext-charwidth-perl_0.04-11build3_amd64.deb ...
Unpacking libtext-charwidth-perl:amd64 (0.04-11build3) ...
Selecting previously unselected package cowsay.
Preparing to unpack .../cowsay_3.03+dfsg2-8_all.deb ...
Unpacking cowsay (3.03+dfsg2-8) ...
Setting up libtext-charwidth-perl:amd64 (0.04-11build3) ...
Setting up cowsay (3.03+dfsg2-8) ...
```

## The paragraph before the prompt is the whole point

**Everything above `Do you want to continue?` is apt telling you what it decided**, and it is the
part people press `y` through. Four lines of it answer four different questions:

**`The following additional packages will be installed:`** — you asked for one and you are getting
two. `libtext-charwidth-perl` is `cowsay`'s `Depends` from section 02, resolved.

**`The following NEW packages will be installed:`** is the full list. On a real machine this is
where you notice that a small utility is dragging in a display server.

**`0 upgraded, 2 newly installed, 0 to remove and 168 not upgraded.`** is the one to read carefully,
and the number that matters is the third. **`to remove` should be `0`** unless you meant it — a
non-zero there is apt telling you that satisfying your request requires taking something away, and
it is the single most useful thing on the screen.

The `168 not upgraded` is unrelated to this install: it is how far behind the machine is. Section 09
is what to do about that number.

**`After this operation, 135 kB of additional disk space will be used.`** — and it can say `freed`
instead, or a figure in gigabytes that explains why the disk filled up last time.

## `-y`, and when not to use it

`apt install -y` answers the prompt for you. It belongs in a script, a Dockerfile, an Ansible task —
anywhere nobody is watching.

**It does not belong in a terminal you are sitting at**, because the prompt is the last moment
before `to remove` becomes real. Type the command, read the paragraph, then decide.

## Unpacking and setting up are two steps

```
Unpacking cowsay (3.03+dfsg2-8) ...
Setting up cowsay (3.03+dfsg2-8) ...
```

Every package goes through both, and they fail differently:

| | |
|---|---|
| **unpack** | the files are written to the filesystem |
| **configure** | the package's own setup script runs — users, directories, a service enabled |

A package can be unpacked and not configured, and section 07 shows exactly that state, with the
program installed and not working. **The two-letter code in `dpkg -l` is these two steps**, one
letter each.

`debconf: delaying package configuration, since apt-utils is not installed` in that transcript is
this machine being minimal: `debconf` is what asks a package's setup questions, and with nothing to
ask them through it postpones. On a machine you installed normally, this is where a package would
stop and ask you something.

## The daily set

```
apt update                    # refresh the indexes
apt install thing             # install, with dependencies
apt remove thing              # uninstall, keeping its configuration
apt purge thing               # uninstall, configuration and all
apt autoremove                # drop dependencies nothing needs any more
apt upgrade                   # newer versions of everything installed
apt search text               # find something by name or description
apt show thing                # everything known about one package
apt list --installed          # what is on this machine
```

Nine commands, and they are most of what anybody types. `remove` against `purge` and what
`autoremove` is for are section 08.

## `apt` and `apt-get` are not the same command

```
root@vm:~# apt list --installed 2>&1 | head -3

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
```

apt prints that when its output is not a terminal, and it means what it says. **`apt` is for people
and `apt-get` is for scripts**: `apt` has progress bars, colour and a friendlier layout, and its
authors reserve the right to change all of it. `apt-get` and `apt-cache` have not changed in
decades and will not.

So: type `apt` at a prompt, and write `apt-get` in anything that runs unattended. The transcripts in
this lesson use whichever one is being talked about, and the warning above is why you will see both.
