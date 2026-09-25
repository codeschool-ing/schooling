---
title: How long a release lasts
version: 1
---

Every release has an **end of life**, the day its security fixes stop. After it, the machine keeps
running and gets no more fixes, which is lesson 5's Windows 10 problem with a different name.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A bar chart of how many years each kind of release receives security fixes. An Ubuntu interim release, nine months. Fedora, about thirteen months. Debian stable, three years, and five with the Debian LTS team. Ubuntu LTS, five years, and ten with Ubuntu Pro. RHEL and its rebuilds, ten years.\"><defs><marker id=\"sp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ubuntu, interim release</text><rect x=\"220\" y=\"20\" width=\"34.5\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Fedora</text><rect x=\"220\" y=\"58\" width=\"50.6\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Debian stable</text><rect x=\"220\" y=\"96\" width=\"138\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"358\" y=\"96\" width=\"92\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ubuntu LTS</text><rect x=\"220\" y=\"134\" width=\"230\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"450\" y=\"134\" width=\"230\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RHEL and its rebuilds</text><rect x=\"220\" y=\"172\" width=\"460\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M220 206 L220 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"220\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M312 206 L312 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"312\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M404 206 L404 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"404\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M496 206 L496 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"496\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><path d=\"M588 206 L588 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"588\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><path d=\"M680 206 L680 214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"450\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">years of security fixes</text><rect x=\"220\" y=\"260\" width=\"22\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">free</text><rect x=\"330\" y=\"260\" width=\"22\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"358\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">with LTS teams or Ubuntu Pro</text></svg>", "caption": "A server is installed for years. Only the last three rows outlive the hardware refresh it will be replaced in."}
```

The dates are published, and on Ubuntu the package `distro-info` carries them, so the server can
answer for itself:

```
ana@server:~$ ubuntu-distro-info --series noble --fullname
Ubuntu 24.04 LTS "Noble Numbat"
ana@server:~$ ubuntu-distro-info --series noble --days=eol
979
ana@server:~$ ubuntu-distro-info --series noble --days=eol-esm
2769
ana@server:~$ ubuntu-distro-info --supported --fullname
Ubuntu 22.04 LTS "Jammy Jellyfish"
Ubuntu 24.04 LTS "Noble Numbat"
Ubuntu 26.04 LTS "Resolute Raccoon"
Ubuntu 26.10 "Stonking Stingray"
ana@server:~$ ubuntu-distro-info --lts
resolute
ana@server:~$ ubuntu-distro-info --devel
stonking
```

- `--days=eol` counts the days to the end of *standard support* for 24.04: 979 from the day this was
  recorded, a little over two and a half years.
- `--days=eol-esm` counts to the end of *Expanded Security Maintenance*: 2769 days, the ten-year
  mark. ESM comes with **Ubuntu Pro**, free for personal use on a few machines and paid for companies.
- `--supported` lists what is still maintained. **24.04 is no longer the newest LTS**: 26.04,
  *Resolute Raccoon*, came out in April 2026. 26.10 is in the list too, and `--devel` shows it is the
  one still being prepared.

Debian's list has the same shape:

```
ana@server:~$ debian-distro-info --stable --fullname
Debian 13 "Trixie"
ana@server:~$ debian-distro-info --supported
trixie
forky
sid
experimental
```

Debian 13 is the stable release. `forky` is what will become 14, `sid` is the rolling branch from
section 03, and `experimental` is what it sounds like.

## What the numbers are for

- A **server** is installed for years, so it goes on a release with years left. Installing 24.04 on a
  new server in September 2026 wastes two of them; 26.04 is the choice.
- **An LTS release gets its first point release a few months after launch**, *26.04.1*. Only then
  does `do-release-upgrade` offer the jump from the previous LTS, and careful administrators wait for
  it anyway, because the first weeks find the bugs.
- Knowing the end date is only half. **Put it in the calendar** with a year's notice, because moving a
  server between releases is a project, not an evening.
