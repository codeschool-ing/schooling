---
title: The same command in three dialects
version: 1
---

This is the page to come back to. Nothing here is new; it is sections 04 to 11 put side by side,
so that knowing one column means you can work in the other two.

## The daily commands

| | **apt** (Debian, Ubuntu) | **dnf** (RHEL, Rocky, Alma, Fedora) | **zypper** (SUSE) |
|---|---|---|---|
| refresh the indexes | `apt update` | *automatic*; `dnf --refresh` | `zypper refresh` |
| install | `apt install X` | `dnf install X` | `zypper install X` |
| remove | `apt remove X` | `dnf remove X` | `zypper remove X` |
| remove with config | `apt purge X` | *none* — see below | *none* |
| upgrade everything | `apt upgrade` | `dnf upgrade` | `zypper update` |
| upgrade, allowed to remove | `apt full-upgrade` | `dnf distro-sync` | `zypper dup` |
| what would upgrade | `apt list --upgradable` | `dnf check-update` | `zypper list-updates` |
| search | `apt search X` | `dnf search X` | `zypper search X` |
| details | `apt show X` | `dnf info X` | `zypper info X` |
| what is installed | `apt list --installed` | `dnf list installed` | `zypper search -i` |
| drop unused dependencies | `apt autoremove` | `dnf autoremove` | `zypper packages --unneeded` |
| list repositories | `apt policy` | `dnf repolist` | `zypper repos` |
| add a repository | edit `sources.list.d/` | edit `yum.repos.d/` | `zypper addrepo` |
| hold a version | `apt-mark hold X` | `dnf versionlock add X` | `zypper addlock X` |
| which package owns a file | `dpkg -S /path` | `rpm -qf /path` | `rpm -qf /path` |
| which package **would** provide it | `apt-file search X` | `dnf provides '*/X'` | `zypper se --provides X` |
| files in a package | `dpkg -L X` | `rpm -ql X` | `rpm -ql X` |
| install a local file | `apt install ./f.deb` | `dnf install ./f.rpm` | `zypper install ./f.rpm` |
| the low layer | `dpkg -i f.deb` | `rpm -i f.rpm` | `rpm -i f.rpm` |
| transaction log | `/var/log/apt/history.log` | `dnf history` | `/var/log/zypp/history` |

**The `rpm -qf` and `rpm -ql` rows repeat on purpose.** dnf and zypper are two front ends over one
database, so every `rpm` query from section 10 works unchanged on SUSE.

## The four differences that are not just spelling

**1. `purge` exists only on the Debian side.** apt distinguishes "remove the program" from "remove
the program and its configuration", and tracks the in-between state as `rc`. rpm has no such state:
it removes the package and leaves edited config files behind as `.rpmsave`. Section 08 has both.

**2. `apt update` is a separate step and `dnf`'s is not.** dnf expires its own metadata on a timer,
so `dnf install` after a week fetches fresh indexes by itself. There is no equivalent of running
`upgrade` against yesterday's catalogue.

**3. The confirmation default differs.** apt asks `[Y/n]` and zypper asks `(y)` — Return means yes.
dnf asks `[y/N]` — Return means no. **Three tools, and a habit built on one of them is wrong on
another**, which is worth one moment of care the first few times on an unfamiliar system.

**4. `zypper dup` on a rolling release.** Section 11: on Tumbleweed the routine upgrade is `dup`,
not `up`, and using the wrong one for months produces a genuinely broken machine. There is nothing
like this on the other two.

## The files

| | apt | dnf | zypper |
|---|---|---|---|
| repository definitions | `/etc/apt/sources.list.d/` | `/etc/yum.repos.d/` | `/etc/zypp/repos.d/` |
| signing keys | `/etc/apt/keyrings/` | `gpgkey=` in the repo file | `/etc/pki/trust/` |
| the installed database | `/var/lib/dpkg/` | `/var/lib/rpm/` | `/var/lib/rpm/` |
| downloaded packages | `/var/cache/apt/archives/` | `/var/cache/dnf/` | `/var/cache/zypp/` |
| pins and priorities | `/etc/apt/preferences.d/` | `priority=` in the repo file | `priority=` in the repo file |

**The cache directories are worth knowing for one reason**: they fill up. `apt clean`,
`dnf clean all` and `zypper clean` empty them, and on a small root filesystem that is sometimes the
difference between an upgrade working and not.

## Reading a command you have never seen

Almost everything reduces to four questions, and the shapes are stable across all three:

| | |
|---|---|
| **a verb** | install, remove, search, update, info |
| **a target** | a package name, or a path, or nothing |
| **a scope flag** | `-i`/`--installed`, `--available`, `-a` |
| **a "do not actually" flag** | `apt --dry-run`, `dnf --assumeno`, `zypper install --dry-run` |

**That last row is the one to use on an unfamiliar system.** When you are not sure what a command
will do on a distribution you do not use daily, ask it to tell you instead of guessing — every one
of the three has a way to print the plan and stop.
