---
title: A repository of your own
version: 1
---

**Machines that install updates from the internet each decide for themselves when, and from what.**
A firm that wants to decide instead points its machines at a repository it controls: a mirror of
the distribution's archive, refreshed on its schedule, plus its own packages. Then "which version of
nginx may the portal run" has one answer, kept in one place, and a broken update can be stopped
before it reaches anybody.

## Two versions of one package

A Debian package is a directory with a `DEBIAN/control` file describing it and the files to install,
packed by `dpkg-deb`. On `admin`, as yourself, build two versions of `jatoba-health`:

```
ana@admin:~$ mkdir -p ~/repo && for v in 1.0 1.1; do
  d=~/pkg/jatoba-health_$v
  mkdir -p $d/DEBIAN $d/usr/bin
  printf 'Package: jatoba-health\nVersion: %s\nArchitecture: all\nMaintainer: Jatoba IT <ti@jatoba.example>\nDepends: curl\nDescription: checks that the client portal answers\n' $v > $d/DEBIAN/control
  printf '#!/bin/sh\necho "jatoba-health %s"\ncurl -s -o /dev/null -w "portal %%{http_code}\\n" http://web/healthz\n' $v > $d/usr/bin/jatoba-health
  chmod 755 $d/usr/bin/jatoba-health
  dpkg-deb --root-owner-group --build $d ~/repo/
done
dpkg-deb: building package 'jatoba-health' in '/home/ana/repo//jatoba-health_1.0_all.deb'.
dpkg-deb: building package 'jatoba-health' in '/home/ana/repo//jatoba-health_1.1_all.deb'.
ana@admin:~$ cat ~/pkg/jatoba-health_1.1/usr/bin/jatoba-health
#!/bin/sh
echo "jatoba-health 1.1"
curl -s -o /dev/null -w "portal %{http_code}\n" http://web/healthz
```

The loop writes the same package twice with a different `Version:` line. In real life the second one
carries a fix; here **the only difference is the version**, because what this lesson exercises is
delivering an update, and a change in the program would only distract from that. The program checks
the portal from wherever it runs and prints its own version first, so every transcript below says
which one ran.

## An index and a server

apt does not browse directories. It reads an index, `Packages`, listing every package with its
version and checksum, and a `Release` file describing the repository. `apt-ftparchive` writes both;
the `Origin` and `Label` it is given matter later, when unattended upgrades decide which
repositories they may install from:

```
ana@admin:~$ cd ~/repo && apt-ftparchive packages . > Packages && apt-ftparchive -o APT::FTPArchive::Release::Origin=Jatoba -o APT::FTPArchive::Release::Label=Jatoba release . > Release && ls
Packages
Release
jatoba-health_1.0_all.deb
jatoba-health_1.1_all.deb
root@admin:~# systemd-run --unit=repo --uid=ana --working-directory=/home/ana/repo python3 -m http.server 8000; sleep 1; systemctl is-active repo
Running as unit: repo.service; invocation ID: 0cd8064dde7c4842979c2c1a02f8ab46
active
```

Python's built-in web server, started as a temporary service with `systemd-run`, makes the directory
reachable at `http://admin:8000/`. A real mirror is served by nginx or Apache, often with a tool
such as `aptly` or `reprepro` maintaining it, but what apt sees is the same.

## Pointing a machine at it

On `desk`, as root, set the distribution's archive aside, since the lab cannot reach it anyway, and
add the firm's repository:

```
root@desk:~# mv /etc/apt/sources.list /root/sources.list.archive; echo "deb [trusted=yes] http://admin:8000 ./" > /etc/apt/sources.list.d/jatoba.list
root@desk:~# apt-get update 2>&1 | tail -2; apt-cache policy jatoba-health
Fetched 1861 B in 0s (84.0 kB/s)
Reading package lists...
jatoba-health:
  Installed: (none)
  Candidate: 1.1
  Version table:
     1.1 500
        500 http://admin:8000 ./ Packages
     1.0 500
        500 http://admin:8000 ./ Packages
```

`apt-cache policy` lists both versions and offers `1.1` as the candidate, the highest version
available. The `500` beside each is its priority, the same for both, so the higher version wins.

**`[trusted=yes]` is a lab shortcut and nothing else.** It tells apt to install packages from this
repository without checking a signature, which means anybody who can answer for `admin:8000` can
put any program on the machine as root. A real repository signs its `Release` file with a key, and
each machine names the key it trusts with `signed-by=` in the same line. The lab images have no
`gpg` to sign with, and the prose says so in order that the line is never copied: **package
signatures are the control that makes a repository safe to use**, and turning them off is the
weakening this course keeps warning about.
