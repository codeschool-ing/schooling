---
title: The interpreter that belongs to the operating system
version: 1
---

```sh
/usr/bin/python3 -m pip install requests
```

```sh
error: externally-managed-environment

× This environment is externally managed
╰─> To install a package, create a virtual environment.

note: You can override this, at the risk of breaking your Python installation
      or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

**The refusal is the feature.** On Debian, Ubuntu and Fedora the system Python is a dependency of
the operating system itself — package managers, printer configuration, firewall tools. Upgrading
a library under it changes the version those programs import.

Older distributions let you do it. What happened then is the reason for the message: a
`pip install --upgrade requests` for your script, and a system tool that stopped working an hour
later, with no connection anybody could see between the two.

## And the other reason, which is yours

```sh
project-a/   needs requests 2.26
project-b/   needs requests 2.31
```

One global installation can hold one version. With both projects installed into it, one of them
is broken, and which one depends on the order somebody installed them in.

## What an environment is

A directory containing its own `bin`, its own `lib/python3.x/site-packages`, and a small
configuration file. Activating it puts that `bin` first on your `PATH`, so `python` means that
one, and the interpreter it starts reads only that `site-packages`.

**It is not a sandbox.** It does not isolate the filesystem, the network or the processes — it
isolates which libraries `import` can find, which is the only thing this problem is about.

## `--break-system-packages`

It exists, it does exactly what it says, and the only defensible use of it is a container you
built and are about to throw away. On a machine you work on, a virtual environment costs five
seconds and this flag costs an afternoon somewhere in the next year.
