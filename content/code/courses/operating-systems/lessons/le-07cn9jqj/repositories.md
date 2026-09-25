---
title: Where the software comes from
version: 1
---

On Windows a program is usually downloaded from its maker's website. On a Linux distribution it
usually comes from the **distribution's own repositories**: servers holding every package it has
built, signed with its key. The server's list of them is one file:

```
ana@server:~$ cat /etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
ana@server:~$ apt-cache show bash cowsay | grep -E '^(Package|Section)'
Package: bash
Section: shells
Package: cowsay
Section: universe/games
```

- **`URIs`** are the servers. `security.ubuntu.com` is separate so that security fixes reach machines
  even when a mirror of the main archive is behind.
- **`Suites`**: `noble` is the release as it came out, `noble-updates` the fixes since, and
  `noble-security` the security fixes. `noble-backports` offers some newer versions, and apt does not
  pick from it unless asked.
- **`Signed-By`** is the key every package list must be signed with. A download that does not match
  it is refused, which is lesson 3's checksum done by apt every time.
- **`Components`** are four sections of the archive, and they differ in **who fixes the software**:

| component | what it holds | security fixes from |
|---|---|---|
| `main` | free software Canonical supports | Canonical, standard support |
| `restricted` | proprietary drivers | Canonical, where it can |
| `universe` | free software the community maintains | the community; Ubuntu Pro adds Canonical |
| `multiverse` | software with licence restrictions | nobody promises |

The last command shows it on two packages: `bash` is in `main`, so its section carries no prefix, and
`cowsay` is `universe/games`. The component is how you know, before installing, whose promise the
support dates of section 04 are.

## Outside the repositories

Some software is not in them, or is too old there. The ways around it, in order of how much trust they
ask for:

- **Snap** and **Flatpak**, formats that bundle a program with what it needs and run on any
  distribution.
- **The maker's own repository**, added as another `.sources` file with its key. Browsers, Docker and
  databases often ship this way.
- **A PPA**, a *Personal Package Archive*: one person's repository on Launchpad. It can replace any
  package on the system, and whoever runs it can push anything to every machine that trusts it.

Lesson 11 installs software each of these ways.
