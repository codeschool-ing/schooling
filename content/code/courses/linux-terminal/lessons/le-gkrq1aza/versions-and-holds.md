---
title: Which version you got, and how to stop it changing
version: 1
---

`apt policy` answers the question nobody thinks to ask until something is wrong: **where did this
version come from, and what else was on offer?**

```
root@vm:~# apt policy cowsay
cowsay:
  Installed: (none)
  Candidate: 3.03+dfsg2-8
  Version table:
     3.03+dfsg2-8 500
        500 http://archive.ubuntu.com/ubuntu noble/universe amd64 Packages
```

Three things:

| | |
|---|---|
| `Installed` | what is on the machine now, or `(none)` |
| `Candidate` | what `apt install` would give you |
| `Version table` | every version any configured repository offers |

**`Candidate` is the word to remember.** It is not "the newest version that exists" — it is the
newest version apt is willing to give you from the repositories you have, at their priorities.

## Priorities, and the number in front of the URL

```
root@vm:~# apt policy docker-ce 2>/dev/null | head -12
docker-ce:
  Installed: 5:29.3.1-1~ubuntu.24.04~noble
  Candidate: 5:29.8.0-1~ubuntu.24.04~noble
  Version table:
     5:29.8.0-1~ubuntu.24.04~noble 500
        500 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages
     5:29.7.2-1~ubuntu.24.04~noble 500
        500 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages
     5:29.7.1-1~ubuntu.24.04~noble 500
        500 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages
     5:29.7.0-1~ubuntu.24.04~noble 500
        500 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages
```

This is a real machine behind on Docker: installed `29.3.1`, candidate `29.8.0`, and four
intermediate versions the repository still carries.

**`500` is the priority.** Every version gets one, and apt picks the highest-priority version, using
the newest to break ties. The defaults are worth knowing because they explain more than they look
like they should:

| | |
|---|---|
| `100` | already installed, or from `noble-backports` |
| `500` | a normal repository |
| `990` | the release you actually target |
| `< 0` | never install this |
| `1001+` | install this even if it means **downgrading** |

`100` for "already installed" is the quiet one. **It is why an installed package is never
automatically downgraded** — anything from a repository outranks it at 500, but nothing pushes it
out in favour of something older.

That `5:` at the front of the Docker versions is the epoch from section 02. Read past it: `29.8.0`
against `29.3.1`.

## Holding a version

```
root@vm:~# apt-mark hold cowsay
cowsay set on hold.
root@vm:~# apt-mark showhold
cowsay
root@vm:~# apt-get install -y --only-upgrade cowsay
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
cowsay is already the newest version (3.03+dfsg2-8).
0 upgraded, 0 newly installed, 0 to remove and 168 not upgraded.
root@vm:~# apt-mark unhold cowsay
Canceled hold on cowsay.
root@vm:~# apt-mark showhold; echo "(empty above means none held)"
(empty above means none held)
```

**A hold means `upgrade` will skip it**, silently, for as long as the hold is there. It is the right
tool for a database or a kernel that must not move without a maintenance window.

And it is a trap you set for a colleague. The package stops upgrading, `apt upgrade` says nothing
about it, and the only way to find out is `apt-mark showhold`. **When a package is mysteriously
stuck at an old version, that is the first command to run** — and when you set a hold, write down
why, somewhere that is not the machine.

`dpkg --get-selections | grep hold` is the other way to see them, and `dpkg -l` shows `h` in the
first column for a held package.

## Installing a specific version

```
apt install cowsay=3.03+dfsg2-8        # exactly this version
apt policy cowsay                      # to find out what the choices are
```

The version has to be in the table `apt policy` printed. **A repository normally carries one
version of each package**, which is why this works on Docker's repository above — it keeps several
— and fails on Ubuntu's, which does not.

Going backwards needs more than a version number: `apt install thing=oldversion` will do it, and
apt will warn that it is a downgrade. Downgrades are not supported by packaging in general, because
a package's setup script is written to upgrade from older versions and not from newer ones. **The
reliable way back is to purge and install the old version**, and the reliable way to not need that
is to test before upgrading.

## Pinning, when a hold is not enough

A hold pins one package at whatever it currently is. A **pin** expresses a rule, in
`/etc/apt/preferences.d/`:

```
Package: docker-ce
Pin: version 5:29.3.*
Pin-Priority: 1001
```

That says "the candidate for `docker-ce` is any `29.3` release, and install it even if it is a
downgrade". Priority `1001` is the number above 1000 from the table, which is the only band that
permits going backwards.

The other common one is the opposite — keeping a whole third-party repository from taking over:

```
Package: *
Pin: origin download.docker.com
Pin-Priority: 100
```

**That drops every package from that origin below "already installed"**, so nothing from it is
installed unless you ask by name. It is the standard defence against a third-party repository that
also carries versions of things your distribution already provides, which is section 13.

`apt-cache policy` with no package prints the priorities in force, which is how you check that a
pin file says what you meant.

## On the rpm side

```
dnf --showduplicates list thing     # every version the repositories have
dnf install thing-1.2.3             # a specific one
dnf downgrade thing                 # supported, and it means it
dnf versionlock add thing           # the hold, from the dnf-plugins-core package
```

**`dnf downgrade` is a first-class command**, which is the one real difference in this section
between the two families. `/etc/dnf/dnf.conf` can also carry `exclude=` lines, which is the blunter
form of a pin.
