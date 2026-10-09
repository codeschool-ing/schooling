---
title: Linux: the journal
version: 1
---

A common belief is that `/var/log/syslog` is where Linux keeps its log, and the journal is a newer copy of
it. **On Ubuntu 24.04 it is the other way round.** Every message is first received by `journald`, part of
systemd, which stores it in a binary journal with all its fields; rsyslog receives a copy from journald and
writes the text files of the previous section. Two roads from the same message:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"How a log line travels on Ubuntu 24.04. Programs such as sshd, su and the kernel hand their messages to journald, which keeps them in its binary journal under /var/log/journal and passes a copy to rsyslog. rsyslog sorts the copy by facility into text files: auth and authpriv to auth.log, kern to kern.log, everything else to syslog.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">programs</text><rect x=\"20\" y=\"40\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sshd</text><path d=\"M130 60 L210 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M210 120 L206.0 112.0 L201.2 118.4 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"20\" y=\"92\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">su</text><path d=\"M130 112 L210 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M210 120 L202.4 115.2 L201.6 123.2 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"20\" y=\"144\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kernel</text><path d=\"M130 164 L210 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M210 120 L201.1 120.4 L204.9 127.4 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"210\" y=\"95\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">journald</text><path d=\"M275 145 L275 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M275 190 L279.0 182.0 L271.0 182.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"195\" y=\"190\" width=\"160\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/var/log/journal</text><text x=\"275.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">binary, every field</text><path d=\"M340 120 L410 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 120 L402.0 116.0 L402.0 124.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"410\" y=\"95\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rsyslog</text><path d=\"M530 110 L565 110 L565 50 L580 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M580 50 L572.0 46.0 L572.0 54.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 120 L580 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M580 120 L572.0 116.0 L572.0 124.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 130 L565 130 L565 190 L580 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M580 190 L572.0 186.0 L572.0 194.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"580\" y=\"30\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">auth.log</text><rect x=\"580\" y=\"100\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">syslog</text><rect x=\"580\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kern.log</text><text x=\"645\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">auth, authpriv</text><text x=\"645\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the rest</text><text x=\"645\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kern</text></svg>", "caption": "Two roads from one message: a binary journal with every field, and text files sorted by facility."}
```

The journal keeps more than the text file does. Each entry carries **fields**: the message, but also the
process number, the user id, the systemd unit the process belongs to, the boot it happened in, the exact
executable. That makes questions like "everything `ssh.service` said since the last boot" a filter
rather than a `grep`.

The commands below are the ones an analyst uses most. **They were not run on the machine this course was
recorded on**, which had no systemd running; run them on your own virtual machine, where they work, and
compare what you see with the text files:

```
journalctl -u ssh.service --since "2026-09-17 00:00" --until "2026-09-17 06:00"
journalctl _COMM=sudo -o short-iso
journalctl -p warning -b
journalctl --list-boots
journalctl -u ssh.service -o json-pretty -n 1
```

`-u` filters by unit, `_COMM=` by program name, `-p` by severity (and everything worse), `-b` to the
current boot, and `-o json-pretty` shows every field of an entry, which is what a collector would ship.
**Where the journal lives decides whether it survives a reboot**: `/var/log/journal` is persistent, and if
that directory does not exist, journald keeps the journal in `/run/log/journal`, in memory, and loses it on
every restart. Ubuntu creates the persistent one; a minimal container image does not.

Two consequences for an investigation. The journal is binary, so **it cannot be read with `grep` or
copied into a ticket as text** without `journalctl` exporting it. And it rotates by size
(`SystemMaxUse=` in `/etc/systemd/journald.conf`), not by date, so a noisy service can push last week out of
it sooner than anybody expects. Lesson 3 is about deciding that on purpose.
