---
title: `remove`, `purge` and `autoremove`
version: 1
---

Uninstalling has three commands and they do three different things. Choosing the wrong one is not
dangerous; it is just how a machine ends up with configuration for software that left two years
ago, and how "I reinstalled it and it still has my old settings" happens.

Here is all of it in one session:

```
root@vm:~# apt-get install -y -qq screen
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package screen.
(Reading database ... 58861 files and directories currently installed.)
Preparing to unpack .../screen_4.9.1-1ubuntu1_amd64.deb ...
Unpacking screen (4.9.1-1ubuntu1) ...
Setting up screen (4.9.1-1ubuntu1) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. a
t /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 79.)
debconf: falling back to frontend: Readline
Processing triggers for debianutils (5.17build1) ...
root@vm:~# dpkg -l screen | tail -1
ii  screen         4.9.1-1ubuntu1 amd64        terminal multiplexer with VT100/ANSI terminal emulati
on
```

Installed, `ii`. Now remove it:

```
root@vm:~# apt-get remove -y -qq screen
(Reading database ... 58921 files and directories currently installed.)
Removing screen (4.9.1-1ubuntu1) ...
Processing triggers for debianutils (5.17build1) ...
root@vm:~# dpkg -l screen | tail -1
rc  screen         4.9.1-1ubuntu1 amd64        terminal multiplexer with VT100/ANSI terminal emulati
on
root@vm:~# ls -l /etc/screenrc
-rw-r--r-- 1 root root 3663 Jun 20  2016 /etc/screenrc
```

**`rc`, and the config file is still there.** Read the two letters with section 05's legend:

| | |
|---|---|
| `r` | **desired**: remove |
| `c` | **status**: only the configuration files are left |

That is `remove` doing exactly what it promises. The program is gone; `/etc/screenrc` is not.

Now purge:

```
root@vm:~# apt-get purge -y -qq screen
(Reading database ... 58863 files and directories currently installed.)
Purging configuration files for screen (4.9.1-1ubuntu1) ...
removed '/etc/tmpfiles.d/screen-cleanup.conf'
root@vm:~# dpkg -l screen | tail -1
dpkg-query: no packages found matching screen
root@vm:~# ls -l /etc/screenrc
ls: cannot access '/etc/screenrc': No such file or directory
```

**Gone from the database and gone from the disk.** `dpkg -l` no longer has a row at all, which is
the difference between `rc` and nothing.

## Which one to use

| | |
|---|---|
| `remove` | when you might put it back, and want your settings when you do |
| `purge` | when you are finished with it, or when the configuration is the problem |

**`purge` is the right answer far more often than people use it**, for one specific reason: a `rc`
package's configuration is *reused* on reinstall. So the classic "I removed it and reinstalled it
and it is still broken" is `remove` working correctly — it kept the broken config for you.

Finding what is lying around:

```
dpkg -l | grep '^rc'                        # packages that left configuration behind
dpkg -l | awk '/^rc/ {print $2}' | xargs apt-get purge -y
```

The second line is worth reading before running: it takes the names from the first column and purges
all of them. On a machine that has been upgraded across releases a few times, it usually finds a
dozen.

## `autoremove`, and the mark that drives it

```
root@vm:~# apt remove -y cowsay
The following package was automatically installed and is no longer required:
  libtext-charwidth-perl
Use 'apt autoremove' to remove it.
The following packages will be REMOVED:
  cowsay
0 upgraded, 0 newly installed, 1 to remove and 168 not upgraded.
After this operation, 93.2 kB disk space will be freed.
(Reading database ... 58935 files and directories currently installed.)
Removing cowsay (3.03+dfsg2-8) ...
root@vm:~# apt autoremove -y
The following packages will be REMOVED:
  libtext-charwidth-perl
0 upgraded, 0 newly installed, 1 to remove and 168 not upgraded.
(Reading database ... 58874 files and directories currently installed.)
Removing libtext-charwidth-perl:amd64 (0.04-11build3) ...
```

Removing `cowsay` left `libtext-charwidth-perl` behind and said so. It is not orphaned by accident:
apt marked it `auto` when it pulled it in for `cowsay`, and **nothing else on the machine asked for
it**, so it is now a candidate.

`autoremove` collects every such package and removes them together. Running it after any large
removal is how a machine stays the size it should be.

**One caution and it is a real one.** `autoremove` trusts the `auto` mark, and the mark can be
wrong — you installed A, it pulled in B, and you have since come to depend on B directly.
`apt-mark manual B` fixes that permanently, and section 06 is where the marks live.

The version to be careful with is `apt autoremove --purge`, which removes those packages *and*
their configuration. It is the right thing on a machine you are cleaning up and the wrong thing to
run without reading the list.

## On the rpm side

```
dnf remove thing           # removes it, and anything that requires it
dnf autoremove             # the same idea as apt's
rpm -e thing               # the low layer: one package, and it refuses if something needs it
```

**There is no `purge`**, because rpm handles configuration differently: a config file you have
edited is saved as `.rpmsave` when the package is removed, and a config file from a package that
has been upgraded may appear as `.rpmnew` next to yours. Section 10 says more; the short version is
that the rpm side leaves files with new extensions where the Debian side leaves a database row.
