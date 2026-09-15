---
title: Everything you install that the package manager does not know about
version: 1
---

The distribution's repositories do not have everything, and what they do have is often older than
you want. So people install software from elsewhere, and that is normal and fine — as long as you
know what you have taken on.

**The one sentence to keep: everything in this section is software your machine will not upgrade,
will not remove, and will not mention when it is the reason something broke.**

## Third-party repositories

This is the *good* option, because the package manager still manages it. Two steps, and section 105
showed what they produce:

```
root@vm:~# cat /etc/apt/sources.list.d/docker.list
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu   n
oble stable
```

A key in `/etc/apt/keyrings/`, and a source line that names it. From then on `apt upgrade` upgrades
Docker like anything else.

**The risk is not security, it is overlap.** A third-party repository can also carry versions of
packages your distribution already provides — a newer library, a newer compiler — and once one is
installed from there, that repository owns it. Section 111's pin is the defence:

```
Package: *
Pin: origin download.docker.com
Pin-Priority: 100
```

"Nothing from this origin unless I ask by name." On any repository that is not the distribution's
own, this is worth five minutes.

**PPAs on Ubuntu are third-party repositories with a nicer name.** `add-apt-repository ppa:name/x`
writes the source file and fetches the key for you. The same caution applies and one more: a PPA is
one person's build, and when they stop, it stops — and the packages you installed from it stay,
unsupported, until you notice. Section 105's transcript has two PPAs on this machine that no longer
fetch at all.

## Snap and Flatpak

Different model: the application ships with its own libraries, in its own sandbox, and does not
depend on what is on your system.

| | |
|---|---|
| **snap** | Canonical's. On Ubuntu, `snap list`, `snap install`, `snap refresh` |
| **flatpak** | cross-distribution, mostly desktop. `flatpak list`, `flatpak install` |

**They have their own update mechanism and their own idea of what is installed**, which is the part
that matters here: `apt list --installed` does not show a snap, and `dpkg -S` does not own its
files. Two package managers on one machine, each unaware of the other.

On Ubuntu specifically, **some `apt install` commands now install a snap instead** — Firefox and
Chromium are the well-known ones. `apt install firefox` succeeds and `dpkg -L firefox` shows a
transitional package that installed something else. When a program's files are not where `dpkg` says
they are, that is why.

The trade is real in both directions: a snap is up to date on an old distribution and starts more
slowly, uses more disk, and is harder to inspect. For a server, prefer the repository. For a desktop
application you want the current version of, the sandbox is a reasonable price.

## Language package managers

`pip`, `npm`, `gem`, `cargo`, `go install`. Each is a complete package manager for one language,
with its own registry, and **none of them knows about the system's**.

The specific collision worth naming, because it produces a broken machine:

```
pip install --user requests          # fine: your account only
pip install requests                 # on a modern distribution, refused
sudo pip install requests            # the one that breaks things
```

`sudo pip install` writes into the same directories the distribution's python packages live in. When
the distribution later upgrades `python3-requests`, the two disagree about what is installed, and
what breaks is usually some system tool written in python rather than the thing you were working on.

**Recent distributions refuse this**, and the refusal is the packaging system protecting itself:

```
root@vm:~# /usr/bin/python3 -m pip install requests 2>&1 | head -14
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
    
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
```

**That error is not in your way; it is the answer.** It names three alternatives in the order you
should consider them, which is the same order as the table below. The flag that overrides it —
`--break-system-packages` — is named honestly, and the machines it has broken are why.

The right answers, in order:

| | |
|---|---|
| `apt install python3-requests` | if the distribution has it, use it |
| a **virtual environment** | `python3 -m venv`, and the project's dependencies live in the project |
| `pipx install thing` | for a command-line tool: its own environment, one command on your PATH |
| `pip install --user` | acceptable, and still invisible to `apt` |

The same shape applies to `npm -g`, `gem install` and the rest: **global installs from a language
manager go into `/usr/local`, where section 107 showed `dpkg -S` finding nothing.**

## A binary from a release page

`curl | sh`, a tarball extracted into `/opt`, a single binary dropped into `/usr/local/bin`. This is
the most common and the least managed:

- nothing upgrades it;
- nothing removes it;
- `dpkg -S` and `rpm -qf` will not name it;
- and it will still be there, at the version you installed, long after you have forgotten.

**It is not wrong**, and it is how a lot of good software is distributed. What makes it survivable
is writing down what you did. `/usr/local` exists precisely so that this software is in one place
that is not managed, which is what lesson 3 was pointing at and what section 107's empty `dpkg -S`
answer demonstrates:

```
root@vm:~# dpkg -S /usr/local/bin/python3
dpkg-query: no path found matching pattern /usr/local/bin/python3
```

**That machine has a python3 in `/usr/local/bin` that no package put there.** Somebody installed it,
and the only record is the file itself.

## Containers, which are the other answer

The reason `docker` appears in section 111's transcripts is that containers are how a lot of people
now avoid this whole section: the application and its dependencies are packaged together, at
versions the application chose, and the host's package manager is responsible for exactly one thing
— the container runtime.

**That does not remove the problem, it moves it.** The image has a distribution inside it, with a
package manager, and the `apt-get install` in its Dockerfile is subject to everything in this
lesson. `--no-install-recommends` from section 104 is in every well-written Dockerfile for a reason.

## What to do about it

Three habits, and they are cheap:

**Write down what you installed outside the package manager**, in the repository that describes the
machine — a Dockerfile, an Ansible role, a `README`. A list that exists is worth more than one that
is accurate.

**Check before you add a repository** whether the distribution already has what you want, and how
old it really is. `apt policy thing` answers in a second, and the answer is often "recent enough".

**Prefer, in this order**: the distribution's repository, a third-party repository, a sandboxed
application, a language manager in a project-local environment, a binary in `/usr/local`. Each step
down that list is more current software and less of a machine that upgrades itself.
