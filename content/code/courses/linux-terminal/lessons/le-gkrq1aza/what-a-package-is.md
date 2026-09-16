---
title: A package is an archive plus a list of promises
version: 1
---

Strip the tooling away and a package is a small archive with metadata attached. The archive holds
files and where they go. The metadata says what it is called, what version it is, **what it needs**,
and what it offers other packages.

That is the whole format, in both families:

| | | |
|---|---|---|
| **Debian, Ubuntu** | `.deb` | `dpkg` handles one; `apt` handles the rest |
| **RHEL, Rocky, Alma, Fedora, SUSE** | `.rpm` | `rpm` handles one; `dnf` or `zypper` handles the rest |

**The two-layer split is the thing to understand first**, because almost every confusing message in
this lesson comes from using the low layer and expecting the high one.

| | |
|---|---|
| **low: `dpkg`, `rpm`** | one package, from a file you already have. Does exactly what you say |
| **high: `apt`, `dnf`, `zypper`** | knows the repositories, resolves dependencies, downloads |

`dpkg -i thing.deb` does not fetch anything. It cannot: it has never heard of a repository. Section
07 is that failure in full, and it ends with the one command that repairs it.

## What is actually in one

A `.deb` is an `ar` archive containing two tarballs and a version marker. A `.rpm` is a header
followed by a compressed cpio archive. **Neither is interesting to open**, and the tools that read
them are worth knowing anyway, because "what would this install" is a fair question to ask before
installing it:

```
dpkg -c thing.deb          # the file list, without installing
dpkg -I thing.deb          # the metadata: version, dependencies, description
rpm -qlp thing.rpm         # the file list
rpm -qip thing.rpm         # the metadata
```

**`-p` in the rpm commands means "on this file"** rather than "on an installed package", and it is
the difference between asking about a download and asking about the machine.

## The database, which is the half people forget

Installing does two things: it puts the files where they go, and it **writes down that it did**.
That second half is a database — `/var/lib/dpkg` on Debian, `/var/lib/rpm` on the rpm side — and it
is what makes every question in section 07 answerable.

```
root@vm:~# dpkg --get-selections | wc -l
748
root@vm:~# dpkg -l | grep -c "^ii"
748
```

Seven hundred and forty-eight packages on a machine that has had a handful installed by hand. That
is a normal number, and almost all of it arrived as somebody else's dependency.

**The database is why `dpkg -S` can answer "what put this file here".** Nothing scans the disk; it
is a lookup.

## What a package promises

Four fields do most of the work, and all four are visible in `apt show`:

```
root@vm:~# apt show cowsay 2>/dev/null | head -14
Package: cowsay
Version: 3.03+dfsg2-8
Priority: optional
Section: universe/games
Origin: Ubuntu
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Original-Maintainer: James McDonald <james@jamesmcdonald.com>
Bugs: https://bugs.launchpad.net/ubuntu/+filebug
Installed-Size: 93.2 kB
Depends: libtext-charwidth-perl, perl:any
Suggests: filters, cowsay-off
Homepage: https://web.archive.org/web/20120527202447/http://www.nog.net/~tony/warez/cowsay.shtml
Download-Size: 18.6 kB
APT-Sources: http://archive.ubuntu.com/ubuntu noble/universe amd64 Packages
```

| | |
|---|---|
| `Depends` | **must** be there, or this will not be configured |
| `Recommends` | installed by default, and not required. `--no-install-recommends` skips them |
| `Suggests` | mentioned and never installed automatically |
| `APT-Sources` | which repository this version came from — section 03 |

**`Recommends` is the field that explains why a one-line install downloaded forty megabytes.** It is
on by default on Debian and Ubuntu, and turning it off is the single biggest difference between a
small container image and a large one.

`Depends: libtext-charwidth-perl` is the promise that section 07 breaks on purpose.

## Versions, and why they look like that

`3.03+dfsg2-8` is three things joined up:

| | |
|---|---|
| `3.03` | the **upstream** version — what the program's own authors called it |
| `+dfsg2` | the distribution's marker, here "we removed something not redistributable" |
| `-8` | the **packaging** revision: the eighth attempt at packaging that same 3.03 |

**The last number changes without the program changing at all.** A `-8` where you had `-7` can be a
patched security hole and nothing else, which is exactly what a distribution's stable release is
for: the version number stays put and the fixes arrive underneath it.

`5:29.3.1-1~ubuntu.24.04~noble` in section 09 has a fourth part — the `5:` is an **epoch**, a
number that overrides normal version comparison when upstream's numbering went backwards. You will
rarely write one and you will see them.
