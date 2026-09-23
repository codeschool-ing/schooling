---
title: The interpreter that belongs to the operating system
version: 2
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"The machine Python belongs to the operating system and has the tools that depend on it. Each project has a directory of its own holding its own copies of its libraries, so two projects can want two versions of the same package and neither touches the system.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the machine's own Python</text> <text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the package manager, the firewall tool, the printer settings</text> <rect x=\"20\" y=\"112\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"192\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">project a — .venv</text> <rect x=\"50\" y=\"154\" width=\"284\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"192\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">requests 2.31</text> <rect x=\"50\" y=\"192\" width=\"284\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"192\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pandas 3.0</text> <rect x=\"376\" y=\"112\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"548\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">project b — .venv</text> <rect x=\"406\" y=\"154\" width=\"284\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"548\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">requests 2.26</text> <rect x=\"406\" y=\"192\" width=\"284\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"548\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">flask 3.1</text> <text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">neither of these is on the other one’s path, and neither is on the system’s</text> </svg>", "caption": "The refusal to install into the system Python is the feature. What depends on it is not your program."}
```

Older distributions let you do it. What happened then is the reason for the message: a
`pip install --upgrade requests` for your script, and a system tool that stopped working an hour
later, with no connection anybody could see between the two.

## And the other reason, which is yours

```localised
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
