---
title: `dnf`, `yum` and `rpm`
version: 1
---

**A note about this section before anything else.** The machine these transcripts were captured on
is Ubuntu. `rpm`, `dnf` and `zypper` are installed on it, and the packages in the transcripts come
from a repository built for this lesson — two small packages, one of which requires the other, in a
directory with an index over it.

So **the commands, their options and their output are real and were run**, and the distribution is
not Red Hat. Two consequences show up in the output and are pointed out where they do. Everything
else on this page is what you would see on Rocky, Alma, Fedora or RHEL.

## `yum` is `dnf`

`yum` was the tool; `dnf` was the rewrite; on any current Red Hat family system **`yum` is a symlink
to `dnf`** and every command below works under either name. You will meet `yum` in documentation,
in Dockerfiles and in muscle memory, and typing it is not a mistake.

Fedora 41 and later ship `dnf5`, which is the same commands again with faster internals and slightly
different output formatting.

## The repository file

```
root@vm:~# cat /etc/yum.repos.d/teaching.repo
[teaching]
name=A local repository, built for this lesson
baseurl=file:///srv/teaching-repo
enabled=1
gpgcheck=0
root@vm:~# dnf repolist
repo id                           repo name
teaching                          A local repository, built for this lesson
```

This is the shape of every `.repo` file in `/etc/yum.repos.d/`:

| | |
|---|---|
| `[teaching]` | the **repo id**, which is what commands refer to |
| `name=` | the human label |
| `baseurl=` | where it is. `mirrorlist=` or `metalink=` instead, for a list of mirrors |
| `enabled=1` | whether it is used without being asked for |
| `gpgcheck=1` | **verify package signatures**. This lesson's repo is unsigned, hence the `0` |

**`gpgcheck=0` is the thing not to copy.** It is here because these two packages were built on this
machine minutes before, with no key. On anything real it is `1`, with `gpgkey=` naming the key —
that is the rpm side of section 03's `signed-by`.

The equivalence to keep: **one `.repo` file here is one `.list` or `.sources` file in
`/etc/apt/sources.list.d/`.** Same job, different syntax.

## Finding and reading

```
root@vm:~# dnf search greet
Last metadata expiration check: 0:07:43 ago on Tue Sep 15 08:38:01 2026.
================================== Name & Summary Matched: greet ===================================
greet.noarch : Print a greeting, for teaching package managers
greet-tools.noarch : Extra commands that need greet
root@vm:~# dnf info greet
Last metadata expiration check: 0:07:48 ago on Tue Sep 15 08:38:01 2026.
Available Packages
Name         : greet
Version      : 1.2.0
Release      : 1
Architecture : noarch
Size         : 6.4 k
Source       : greet-1.2.0-1.src.rpm
Repository   : teaching
Summary      : Print a greeting, for teaching package managers
License      : MIT
Description  : A two-line shell script that prints a greeting. It exists so that a
             : package manager has something real to install, remove and query.
```

**`Last metadata expiration check` is the line that replaces `apt update`.** dnf refreshes its own
metadata when the cache is older than `metadata_expire` — a day, by default — so there is no
separate update step and no "but I did update it". `dnf --refresh` forces it, and `dnf makecache`
is the explicit version.

`Available Packages` at the top of `info` is dnf saying this one is not installed. After installing,
the same command says `Installed Packages`.

## Installing, and the dependency

```
root@vm:~# dnf install greet-tools
Last metadata expiration check: 0:08:05 ago on Tue Sep 15 08:38:01 2026.
Dependencies resolved.
====================================================================================================
 Package                   Architecture         Version                Repository              Size
====================================================================================================
Installing:
 greet-tools               noarch               0.3.0-1                teaching               6.2 k
Installing dependencies:
 greet                     noarch               1.2.0-1                teaching               6.4 k

Transaction Summary
====================================================================================================
Install  2 Packages

Total size: 13 k
Installed size: 89
Is this ok [y/N]: y
Downloading Packages:
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                            1/1
  Installing       : greet-1.2.0-1.noarch                                                       1/2
  Installing       : greet-tools-0.3.0-1.noarch                                                 2/2
  Verifying        : greet-1.2.0-1.noarch                                                       1/2
  Verifying        : greet-tools-0.3.0-1.noarch                                                 2/2

Installed:
  greet-1.2.0-1.noarch                          greet-tools-0.3.0-1.noarch               

Complete!
root@vm:~# greet-twice
hello from greet 1.2.0
hello from greet 1.2.0
```

Compare that table with apt's paragraph in section 04. **The same information, laid out rather than
written out**, and with the sections named: `Installing:` is what you asked for, `Installing
dependencies:` is what came with it.

Two things apt does not have. **`Is this ok [y/N]` defaults to no** — a bare Return cancels, where
apt's `[Y/n]` proceeds. And the transaction is checked and tested before anything is written, which
is the `Transaction check` and `Transaction test` lines: dnf verifies the whole plan against the
filesystem first, so a conflict is found before any file has moved.

## `rpm`, the layer underneath

```
root@vm:~# rpm -q greet
greet-1.2.0-1.noarch
root@vm:~# rpm -qi greet | head -8
Name        : greet
Version     : 1.2.0
Release     : 1
Architecture: noarch
Install Date: Tue Sep 15 08:46:10 2026
Group       : Unspecified
Size        : 66
License     : MIT
root@vm:~# rpm -ql greet
/usr/bin/greet
/usr/share/doc/greet/README
root@vm:~# rpm -qf /usr/bin/greet
greet-1.2.0-1.noarch
root@vm:~# rpm -qR greet-tools
greet >= 1.2.0
rpmlib(CompressedFileNames) <= 3.0.4-1
rpmlib(FileDigests) <= 4.6.0-1
rpmlib(PayloadFilesHavePrefix) <= 4.0-1
```

**Every `rpm` query starts with `-q`**, and the second letter picks the question. That is the whole
of the interface and it is worth memorising as a group:

| | | |
|---|---|---|
| `rpm -q thing` | `dpkg -l thing` | is it installed, and which version |
| `rpm -qi thing` | `apt show thing` | everything known about it |
| `rpm -ql thing` | `dpkg -L thing` | the files it owns |
| `rpm -qf /path` | `dpkg -S /path` | **which package owns this file** |
| `rpm -qR thing` | `apt-cache depends` | what it requires |
| `rpm -qa` | `dpkg -l` | everything installed |

`rpm -qR greet-tools` shows the `greet >= 1.2.0` this lesson's package declares, plus three
`rpmlib(...)` entries. Those are not packages: they are **requirements on the rpm format itself**,
and every rpm has them. Read past them.

## `rpm -i` does not resolve anything either

```
root@vm:~# rpm -q greet greet-tools
package greet is not installed
package greet-tools is not installed
root@vm:~# rpm -i /srv/teaching-repo/greet-tools-0.3.0-1.noarch.rpm
rpm: RPM should not be used directly install RPM packages, use Alien instead!
rpm: However assuming you know what you are doing...
error: Failed dependencies:
        greet >= 1.2.0 is needed by greet-tools-0.3.0-1.noarch
```

**`error: Failed dependencies:` is `rpm`'s version of section 07's message**, and there is one
difference worth noticing: rpm refuses outright. dpkg unpacks and leaves the package half
installed; rpm does not write anything at all.

Those two `rpm:` lines above the error are the first of the two Ubuntu artefacts this
lesson's rpm transcripts carry; the other is in section 11.
**Debian and Ubuntu ship a wrapper around `rpm` that warns you are on the wrong kind of system**,
then runs it anyway. On Rocky or Fedora they are not there.

Removal is refused the same way:

```
root@vm:~# rpm -e greet
error: Failed dependencies:
        greet >= 1.2.0 is needed by (installed) greet-tools-0.3.0-1.noarch
```

`(installed)` is the useful word: something on this machine needs it. `rpm -e greet-tools greet`
names both and succeeds.

## Removing with dnf

```
root@vm:~# dnf remove greet
Dependencies resolved.
====================================================================================================
 Package                   Architecture         Version               Repository               Size
====================================================================================================
Removing:
 greet                     noarch               1.2.0-1               @teaching                66
Removing dependent packages:
 greet-tools               noarch               0.3.0-1               @teaching                23
```

**`Removing dependent packages:` is the same behaviour section 06 showed apt doing** — asking for
one and being told two. The `@` in `@teaching` means "installed, and it came from there", which is
how dnf marks an installed package's origin.

## The command set

```
dnf install thing              dnf remove thing
dnf upgrade                    dnf check-update
dnf search text                dnf info thing
dnf list installed             dnf provides '*/bin/pdftotext'
dnf repolist                   dnf history
dnf autoremove                 dnf clean all
```

Two with no apt equivalent worth knowing:

**`dnf provides` answers section 05's fourth question with no extra download**, because rpm
repository metadata includes file lists:

```
root@vm:~# dnf provides '*/bin/greet'
Last metadata expiration check: 0:20:51 ago on Tue Sep 15 08:38:01 2026.
greet-1.2.0-1.noarch : Print a greeting, for teaching package managers
Repo        : teaching
Matched from:
Filename    : /usr/bin/greet
```

That is `apt-file` without the 346 MB. The glob matters: `dnf provides pdftotext` looks for a
package that *provides the capability* `pdftotext`, and `'*/bin/pdftotext'` looks for one that ships
a file at that path. Quote it, or the shell expands it first.

**`dnf history` is a transaction log**, which apt has no equivalent for:

```
root@vm:~# dnf history | head -6
ID     | Command line                                  | Date and time    | Action(s)      | Altered
----------------------------------------------------------------------------------------------------
     4 | remove greet                                  | 2026-09-15 08:46 | Removed        |    2
     3 | install greet-tools                           | 2026-09-15 08:46 | Install        |    2
     2 | -y remove greet-tools greet                   | 2026-09-15 08:38 | Removed        |    2
     1 | -y --refresh install greet-tools              | 2026-09-15 08:38 | Install        |    2
```

Every transaction, with the command line that caused it and how many packages it touched. **`dnf
history undo 3` rolls one back**, and `dnf history info 3` shows what it did in detail.

The nearest apt equivalent is reading `/var/log/apt/history.log`, which records the same facts and
cannot undo anything.

## `.rpmnew` and `.rpmsave`

When a package upgrade brings a new version of a config file you have edited, the two families do
different things. Debian **asks**, interactively, showing a diff. rpm does not ask: it writes the
new file as `config.rpmnew` next to yours, or — for a file the package considers yours — moves
yours to `config.rpmsave` and installs the new one.

**So after any large `dnf upgrade`, look for them:**

```
find /etc -name '*.rpmnew' -o -name '*.rpmsave'
```

An unreviewed `.rpmnew` is a configuration change the packagers made that you are not running. It is
the rpm side's quiet equivalent of a `rc` package, and it is the reason a service can behave
differently on two machines that report the same version.
