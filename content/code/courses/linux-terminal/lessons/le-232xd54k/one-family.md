---
title: One family, and what they actually share
version: 1
---

There is a reason a command you learn today works on a server in Frankfurt, on a Mac, inside a
container, and on a Raspberry Pi on your desk. It is not that they run the same software. **It is
that they agreed, decades ago, on what the commands would be called and how they would behave.**

That agreement has a name and a history, and both are worth ten minutes, because they explain what
carries from one machine to another and what does not — which is the difference between confidence
and superstition when you sit down at a system you have never seen.

## The family tree

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A family tree. Unix, from 1969, branches into System V and BSD; BSD leads to macOS. Linux sits apart, joined to Unix by a dashed line routed down the margin and marked as imitating the interface without sharing code. Windows NT stands on the far side of a divider, with no connection to any of them. A band along the foot marks POSIX as the agreement the four systems on the left share.\"><defs><marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"ahd\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"200\" y=\"18\" width=\"150\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Unix</text><text x=\"275.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Bell Labs, 1969</text><path d=\"M275 60 L180 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M275 60 L370 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"110\" y=\"102\" width=\"140\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">System V</text><rect x=\"300\" y=\"102\" width=\"140\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">BSD</text><path d=\"M370 140 L370 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"300\" y=\"188\" width=\"140\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">macOS</text><text x=\"370.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Darwin, from BSD</text><rect x=\"30\" y=\"188\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Linux, 1991</text><text x=\"105.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">written from scratch</text><path d=\"M200 39 L20 39 L20 210 L26 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#ahd)\"></path><text x=\"30\" y=\"158\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">imitates the interface</text><text x=\"30\" y=\"172\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">shares no code</text><path d=\"M540 14 L540 286\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"560\" y=\"102\" width=\"145\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"632.5\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Windows NT</text><text x=\"632.5\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">VMS lineage, 1993</text><text x=\"632\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">no shared ancestry</text><text x=\"632\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">nothing transfers</text><rect x=\"30\" y=\"250\" width=\"490\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".12\" stroke=\"var(--phosphor)\"></rect><text x=\"275\" y=\"269\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">POSIX · the written agreement these four keep</text><path d=\"M105 232 L105 248\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M370 232 L370 248\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "Linux is not a descendant of Unix: it is a reimplementation that kept the behaviour and none of the code. What the four on the left share is an agreement, not an ancestor — and Windows shares neither."}
```

**Unix** was written at Bell Labs starting in 1969. It was not the first operating system, but it
was the one whose *ideas* spread: small programs that do one thing, text as the universal format
between them, and a filesystem as one tree. Everything below inherits those three ideas.

It split into two lines that argued with each other for twenty years — the **System V** line, which
became the commercial Unixes, and the **BSD** line out of Berkeley. That argument is why two
machines can both be "Unix" and disagree about what `ps` prints.

**macOS is genuinely in the family.** Its core, Darwin, descends from BSD, and the certification
is not folklore: macOS is formally registered as UNIX. When you open Terminal on a Mac you are in
this tree, properly.

**Linux is not.** And this is the part that surprises people: Linux shares no code with Unix at
all. Linus Torvalds wrote a kernel from scratch in 1991, deliberately imitating the *interface* of
a system he could not have the source to. Around it went the GNU project's tools — which had been
written, also from scratch, for the same reason.

So Linux is not a descendant. **It is a reimplementation that kept the behaviour and threw away the
lineage** — which is why it is legally free of Unix, and why it behaves like Unix anyway.

## The promise is the interface, and it is written down

The thing being inherited is not code. It is a specification, and it is called **POSIX** — a
document that says what a compliant system must provide: that there is a command called `ls`, that
it lists a directory, that `|` sends one program's output into the next, that paths are separated
by `/`, that a file has an owner and permission bits, that a program can be sent a signal.

POSIX is why this holds:

```
$ uname -s
Linux
```

…and why the same command on a Mac prints `Darwin`, and on a FreeBSD server prints `FreeBSD`, and
in every one of those three cases the command exists, is spelled the same way, and means the same
thing. Different systems, one agreement.

**What POSIX guarantees you, and you can rely on it anywhere in this course:**

| | |
|---|---|
| the shape of a command | a name, then options, then arguments |
| one tree | `/` at the root, everything mounted somewhere inside it |
| the core commands | `ls`, `cd`, `cp`, `mv`, `rm`, `cat`, `grep`, `chmod`, `ps`, `kill` |
| pipes and redirection | `\|`, `>`, `<`, and the three streams behind them |
| the permission model | owner, group, other — three bits each |
| signals | a numbered message you can send to a running program |

## What it does not guarantee, and where you will get bitten

POSIX is a floor, not a ceiling, and every real system builds above it. The parts above the floor
are where two Unix-like machines stop agreeing:

**Flags beyond the standard ones.** GNU tools on Linux take long options — `ls --human-readable`,
`grep --recursive`. The BSD tools on macOS often do not. The single most common version of this is
`sed -i`, which edits a file in place: on Linux `sed -i 's/a/b/' f` works, and on macOS the same
line fails, because there `-i` wants an argument for the backup suffix.

**Which shell `sh` actually is.** POSIX says there is a shell called `sh`. It does not say which
one. On Ubuntu:

```
$ ls -l /bin/sh
lrwxrwxrwx 1 root root 4 Mar 31  2024 /bin/sh -> dash
```

`sh` is **dash**, a small strict shell — not bash. So a script that starts `#!/bin/sh` and uses a
bash feature works when you test it by typing, and fails when it runs. That one costs people an
afternoon, and lesson 9 comes back to it with the fix.

**Everything above the floor.** How software is installed, how services are started, where
configuration lives, which firewall there is — none of that is POSIX, all of it differs, and
lesson 2 is entirely about the differences.

## Windows is not in this tree at all

It is worth being precise here, because "Windows is different" is usually said as a complaint and
it is actually a fact about ancestry. Windows NT — the line every modern Windows descends from —
was designed in 1988 by a team from Digital, and its heritage is VMS, not Unix. Not a fork, not a
reimplementation, not a cousin. A different answer to the same problem, arrived at separately.

That is why nothing transfers. Paths use `\` and start at a drive letter. There is no
`/etc`. Permissions are access control lists rather than nine bits. Services are not daemons.
Case is preserved but not significant. Configuration is in a registry rather than in text files,
which means you cannot `grep` it or put it in git.

**And it is why WSL exists.** Microsoft's eventual answer to "developers need Unix" was not to
make Windows more Unix-like. It was to ship an actual Linux kernel alongside Windows and let you
open a terminal into it. That is an admission that the gap is not closeable by imitation — and,
for you, it is the easiest way to do this course on a Windows machine. The next section sets it
up.

## What this buys you, concretely

The practical shape of the inheritance, stated as a return on the seventy hours you are about to
spend:

- **On any Linux, anywhere** — a server, a container, a Pi, a cloud instance, WSL — essentially
  everything in this course applies directly. This is the large majority of machines you will meet.
- **On macOS** — the concepts all apply, most commands apply, some flags differ. You will be
  comfortable, and you will occasionally have to check. Many people fix this by installing the GNU
  tools alongside the BSD ones.
- **On BSD or a commercial Unix** — the concepts apply; assume flags differ and read the manual,
  which lesson 1 teaches you to do in section 16.
- **On Windows** — nothing applies natively, and everything applies inside WSL. Lesson 10 covers
  PowerShell, which is Windows' own good answer and a genuinely different idea.

One agreement, made before most people reading this were born, is why a single skill covers that
much ground. That is unusual, and it is the reason this course is worth more per hour than its
subject looks.
