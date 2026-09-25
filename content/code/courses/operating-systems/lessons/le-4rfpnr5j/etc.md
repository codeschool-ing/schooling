---
title: /etc: the machine's settings, as text
version: 1
---

**`/etc`** holds the configuration of the whole machine, and almost all of it is **plain text**.

```
ana@server:~$ ls /etc | wc -l
122
ana@server:~$ cat /etc/hostname
server
ana@server:~$ cat /etc/hosts
127.0.0.1 localhost
127.0.1.1 server
ana@server:~$ dpkg -S /etc/hosts /etc/crontab
dpkg-query: no path found matching pattern /etc/hosts
cron-daemon-common: /etc/crontab
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two ways of keeping settings. On Linux, text files in /etc, such as /etc/hostname, /etc/hosts, /etc/systemd/journald.conf and the files in /etc/apt/apt.conf.d; any editor opens them, one program per file. On Windows, one tree called the registry: HKEY_LOCAL_MACHINE, then SOFTWARE, Microsoft, Windows NT and CurrentVersion, each a key inside the one before; it is opened with regedit, reg or PowerShell.\"><defs><marker id=\"md-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Linux: text files in /etc</text><text x=\"380\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Windows: one tree, the registry</text><rect x=\"20\" y=\"30\" width=\"320\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/hostname</text><rect x=\"20\" y=\"70\" width=\"320\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/hosts</text><rect x=\"20\" y=\"110\" width=\"320\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/systemd/journald.conf</text><rect x=\"20\" y=\"150\" width=\"320\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/apt/apt.conf.d/…</text><text x=\"20\" y=\"206\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">open with any editor, one program per file</text><rect x=\"380\" y=\"30\" width=\"300\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HKEY_LOCAL_MACHINE</text><path d=\"M388 60 L388 77 L396 77\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"396\" y=\"64\" width=\"284\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"406\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SOFTWARE</text><path d=\"M404 94 L404 111 L412 111\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"412\" y=\"98\" width=\"268\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"422\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft</text><path d=\"M420 128 L420 145 L428 145\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"428\" y=\"132\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"438\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Windows NT</text><path d=\"M436 162 L436 179 L444 179\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"444\" y=\"166\" width=\"236\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"454\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CurrentVersion</text><text x=\"380\" y=\"206\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">opened with regedit, reg or PowerShell</text></svg>", "caption": "Same job, two shapes. A text file can be read, compared and copied with the tools of lesson 12; a registry key needs tools that understand the registry."}
```

- **122 entries** in `/etc` on this minimal server, files and folders. A desktop has a few hundred.
- **`/etc/hostname`** is one line: the machine's name, the one in every prompt of this course.
- **`/etc/hosts`** maps names to addresses before any DNS server is asked. `127.0.1.1 server` is how the
  machine finds itself by name. Section 03 adds a line to it.
- **`dpkg -S`** asks which package installed a file. `/etc/crontab` belongs to `cron-daemon-common`;
  `/etc/hosts` belongs to **no package**, because the installer wrote it for this machine. That
  difference matters on upgrade: a package's configuration files are ones apt knows how to update, and
  asks about when you have changed them.

Being text, `/etc` is readable with everything lesson 12 taught: `cat`, `grep`, `less`, `diff`. It is
also why many administrators keep `/etc` under version control, the git course's subject, so that every
change has a date and a reason.
