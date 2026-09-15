---
title: `zypper`, on SUSE and openSUSE
version: 1
---

SUSE uses `.rpm` files and `rpm` underneath, exactly as section 112 described — and a different
tool on top. Everything you learned about `rpm -q` applies here unchanged; only the high layer has
new words.

**Same caveat as section 112**: these transcripts were captured on Ubuntu with `zypper` installed
and the lesson's own repository configured. The commands and their output are real; the
distribution is not SUSE, and the one place that shows is pointed out below.

## Repositories

```
root@vm:~# zypper repos
Repository priorities are without effect. All enabled repositories share the same priority.

# | Alias    | Name     | Enabled | GPG Check | Refresh
--+----------+----------+---------+-----------+--------
1 | teaching | teaching | Yes     | (  ) No   | No
```

`zypper repos` — `zypper lr` for short — is `dnf repolist`. Note the columns: **zypper shows
priority and refresh state in the listing**, which dnf does not, and the first line is it telling
you that with one repository priorities cannot matter.

Adding and refreshing:

```
zypper addrepo <url> <alias>        # zypper ar
zypper refresh                      # zypper ref — this one IS like apt update
zypper removerepo <alias>           # zypper rr
zypper modifyrepo --disable <alias>
```

**`zypper refresh` is closer to `apt update` than dnf's behaviour is.** zypper does refresh
automatically when a repository is marked `Refresh: Yes`, and the lesson's is not, so it was done
by hand. On a normal SUSE machine the distribution repositories are set to auto-refresh.

Every zypper command has a two-letter short form — `lr`, `ar`, `ref`, `in`, `rm`, `se`, `if`, `up`,
`dup`. **SUSE documentation is written in them**, so the long forms below are for reading and the
short ones are what you will see.

## Finding and reading

```
root@vm:~# zypper search greet
Loading repository data...
Reading installed packages...

S | Name        | Summary                                         | Type
--+-------------+-------------------------------------------------+--------
  | greet       | Print a greeting, for teaching package managers | package
  | greet-tools | Extra commands that need greet                  | package
```

**The `S` column is status**, and it is the thing to read: blank is available, `i` is installed,
`i+` is installed because you asked for it rather than as a dependency. It appears again below.

```
root@vm:~# zypper info greet
Information for package greet:
------------------------------
Repository     : teaching
Name           : greet
Version        : 1.2.0-1
Arch           : noarch
Vendor         :
Installed Size : 66 B
Installed      : No
Status         : not installed
Source package : greet-1.2.0-1.src
Summary        : Print a greeting, for teaching package managers
Description    :
    A two-line shell script that prints a greeting. It exists so that a
    package manager has something real to install, remove and query.
```

`Installed: No` and `Status: not installed` say the same thing twice, which is zypper being
explicit rather than confused. `Vendor` is empty here because these packages were built without
one; on a real system it says `SUSE LLC` or the third party who built it, and **`zypper` uses vendor
to decide whether an upgrade is allowed to switch a package's origin.**

## Installing

```
root@vm:~# zypper install greet-tools
Loading repository data...
Reading installed packages...
Resolving package dependencies...

The following 2 NEW packages are going to be installed:
  greet greet-tools

2 new packages to install.
Overall download size: 12.6 KiB. Already cached: 0 B. After the operation, additional 89.0 B will be
used.
Continue? [y/n/v/...? shows all options] (y): y
Retrieving: greet-1.2.0-1.noarch (teaching)                                     (1/2),   6.4 KiB
Retrieving: greet-tools-0.3.0-1.noarch (teaching)                               (2/2),   6.2 KiB

Checking for file conflicts: .................................................................[done]
rpm: RPM should not be used directly install RPM packages, use Alien instead!
rpm: However assuming you know what you are doing...
(1/2) Installing: greet-1.2.0-1.noarch .......................................................[done]
rpm: RPM should not be used directly install RPM packages, use Alien instead!
rpm: However assuming you know what you are doing...
(2/2) Installing: greet-tools-0.3.0-1.noarch .................................................[done]
root@vm:~# greet-twice
hello from greet 1.2.0
hello from greet 1.2.0
```

The dependency was resolved and pulled in, as everywhere else. Three things are zypper's own:

**`Continue? [y/n/v/...? shows all options] (y)`** — the default is `y`, like apt and unlike dnf,
and `v` shows the full version numbers before you decide. Typing `?` lists the rest.

**`Checking for file conflicts:`** is a step neither apt nor dnf announces. zypper verifies that no
two packages want to write the same path before it writes anything.

**Those `rpm:` lines are the Ubuntu artefact**, the same wrapper warning as section 112. zypper is
calling `rpm`, and Debian's `rpm` is telling it off. On SUSE they are not there.

## Which package owns a file

```
root@vm:~# zypper search --provides --file-list /usr/bin/greet
Loading repository data...
Reading installed packages...

S  | Name        | Summary                                         | Type
---+-------------+-------------------------------------------------+--------
i  | greet       | Print a greeting, for teaching package managers | package
i+ | greet-tools | Extra commands that need greet                  | package
```

`zypper se --provides --file-list` — usually written `zypper se --provides` — searches file lists
rather than names. **And now the `S` column has content**: `i` for `greet`, which came in as a
dependency, and `i+` for `greet-tools`, which is what was asked for.

That `+` is the same distinction as `apt-mark showmanual` in section 108, kept in the listing where
you can see it rather than in a separate command.

`rpm -qf /usr/bin/greet` also works here, and is shorter.

## Removing

```
root@vm:~# zypper remove greet
Reading installed packages...
Resolving package dependencies...

The following 2 packages are going to be REMOVED:
  greet greet-tools

2 packages to remove.
After the operation, 89.0 B will be freed.
Continue? [y/n/v/...? shows all options] (y): y
(1/2) Removing greet-tools-0.3.0-1.noarch ....................................................[done]
(2/2) Removing greet-1.2.0-1.noarch ..........................................................[done]
Problem occurred during or after installation or removal of packages:
Failed to cache rpm database (1).
History:
 - 'rpmdb2solv' '-r' '/' '-D' '/var/lib/rpm' '-X' '-p' '/etc/products.d' '/var/cache/zypp/solv/@Syst
em/solv' '-o' '/var/cache/zypp/solv/@System/solvpCAveU'
   rpmdb2solv: no error

Please see the above error message for a hint.
root@vm:~# greet-twice
bash: greet-twice: command not found
```

Both packages removed, for the reason section 108 gave, and then **an error that is this machine
and not zypper**. `rpmdb2solv` builds zypper's cache of the installed-package database, and it
needs `/etc/products.d` — a directory that describes which SUSE products are installed, which an
Ubuntu machine does not have.

It is left in because the alternative is quoting a transcript with a line removed. **The removal
itself worked**: `greet-twice` was gone immediately afterwards. On SUSE this block does not appear.

## `up` against `dup`, which is the one real difference

```
zypper update              # zypper up  — newer versions, without changing vendors
zypper dist-upgrade        # zypper dup — the whole distribution, vendor changes allowed
```

On a fixed release — Leap, SLES — `zypper up` is the routine one and behaves like `apt upgrade`.

**On Tumbleweed, the rolling release, `zypper dup` is the routine one and `up` is wrong.** A rolling
distribution replaces whole sets of packages at once, and `up` refuses the vendor and architecture
changes that requires. Running `up` on Tumbleweed for a few months produces a machine that is
half-upgraded in a way nothing else in this lesson can produce.

That is the single most SUSE-specific fact in this section, and it is the one people get wrong.

## The rest

```
zypper patches             # security patches specifically, as a list
zypper patch               # apply them, and only them
zypper ps                  # what is running that needs restarting after an update
zypper addlock <package>   # the hold from section 111; zypper locks lists them
zypper packages --unneeded # the autoremove candidates
```

**`zypper ps` deserves its own line.** After an upgrade, it lists the processes still running code
from files that have been replaced — the services that need restarting before the update has really
taken effect:

```
root@vm:~# zypper --non-interactive ps 2>&1 | head -6
No processes using deleted files found.

No core libraries or services have been updated since the last system boot.
Reboot is probably not necessary.
```

Nothing to do here, which is the answer you want — and read the first line against section 98.
**"Processes using deleted files" is exactly the open-descriptor-on-a-deleted-file situation**, and
this is what it looks like when a package manager uses it deliberately: a library replaced on disk
while something still has the old one open is a service running code that no longer exists.

Debian's `needrestart` package does the same job; zypper has it built in.
