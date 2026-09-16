---
title: Four families and the independents
version: 1
---

A hundred distributions is not a hundred things to learn. Almost all of them are descended from a
handful of ancestors, and **what you inherit from a family is the package manager, the service
names and the layout** — which is most of what you needed to know.

Learn the families and an unfamiliar distribution stops being unfamiliar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Four family heads across the top — Debian with apt, Red Hat with dnf, SUSE with zypper and Arch with pacman — each with an arrow down to a descendant: Ubuntu, Fedora, openSUSE and Manjaro. Two go one generation further, to Linux Mint and to Rocky and Alma. A band along the foot lists the independents, which descend from nobody.\"><defs><marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"18\" y=\"26\" width=\"162\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"99.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">Debian</text><text x=\"99.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">apt · .deb</text><rect x=\"192\" y=\"26\" width=\"162\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"273.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">Red Hat</text><text x=\"273.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dnf · .rpm</text><rect x=\"366\" y=\"26\" width=\"162\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">SUSE</text><text x=\"447.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zypper · .rpm</text><rect x=\"540\" y=\"26\" width=\"162\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"621.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">Arch</text><text x=\"621.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pacman</text><path d=\"M99 68 L99 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"18\" y=\"106\" width=\"162\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"99.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Ubuntu</text><path d=\"M273 68 L273 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"192\" y=\"106\" width=\"162\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"273.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Fedora</text><text x=\"273.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">upstream</text><path d=\"M447 68 L447 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"366\" y=\"106\" width=\"162\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">openSUSE</text><path d=\"M621 68 L621 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"540\" y=\"106\" width=\"162\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"621.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Manjaro</text><path d=\"M99 144 L99 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"18\" y=\"180\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"99.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Linux Mint · Pop!_OS</text><path d=\"M273 144 L273 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><rect x=\"192\" y=\"180\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"273.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Rocky · Alma</text><text x=\"273\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rebuilt from RHEL, source for source</text><rect x=\"18\" y=\"252\" width=\"684\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"40\" y=\"273\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">No parent</text><text x=\"232\" y=\"273\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Alpine · Gentoo · NixOS · Void · Slackware</text><text x=\"360\" y=\"306\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the family decides your package manager, your service names and half your paths</text></svg>", "caption": "A hundred distributions, four families and a handful of independents. What you inherit from a family is the package manager, the package format, the service names and the security framework — which is most of what you needed to know."}
```

## The four that matter

**Debian**, and its enormous descendant Ubuntu. `apt` and `.deb` packages. Volunteer-run, with a
constitution and a famously slow, careful release. Ubuntu is a company's product built on top of
it, and between them they are what most tutorials assume. Section 04.

**Red Hat**, and the rebuilds — Rocky and Alma — plus Fedora upstream of all of them. `dnf` and
`.rpm` packages. This is the enterprise family: support contracts, certifications, and the
software vendors who publish for it and nothing else. Section 05, and it has a story.

**SUSE**, with openSUSE beside it. `zypper` and `.rpm`. Smaller than the other two and strong in
German-speaking Europe, in manufacturing, and at SAP shops. Section 06.

**Arch**, and Manjaro below it. `pacman`, rolling release, and an assumption that you want to
assemble the machine yourself. Its documentation — the Arch Wiki — is used by people running
every other distribution, which is the most useful thing to know about it.

## And the ones with no parent

Some distributions were written from scratch rather than derived:

| | why it exists |
|---|---|
| **Alpine** | to be tiny. 5 MB, busybox, musl — and the reason it is in containers everywhere. Section 07 |
| **Gentoo** | you compile everything, and choose the options while doing it |
| **NixOS** | the whole machine is one declarative file, and changes roll back |
| **Void, Slackware** | their own answers, and Slackware is older than all of this |

You are unlikely to be handed one of these at work, and Alpine is the exception that you will meet
within a week of touching Docker.

## What "family" actually buys you

It is not sentiment. Knowing the family tells you four things before you look at anything else:

1. **The package manager** — `apt` on Debian's side, `dnf` on Red Hat's, `zypper` on SUSE's.
2. **The package format** — `.deb` or `.rpm`, which decides what a vendor's download page offers.
3. **The service and path conventions** — `apache2` against `httpd`, and which directory holds it.
4. **The security framework** — AppArmor on Debian's side, SELinux on Red Hat's. Lesson 4.

That is why section 11's `ID_LIKE` is the useful field. A distribution you have never heard of
that says `ID_LIKE=debian` is one whose commands you already know.

## Two things people believe that are not true

**They are not compatible in the package sense.** A `.deb` does not install on Rocky, and `.rpm`
does not install on Ubuntu. Tools exist to convert; they are a last resort and lesson 7 says so.

**And derived does not mean identical.** Ubuntu is Debian-derived and diverges in real ways —
its own release cycle, its own repositories, snaps, and a `/etc/debian_version` that names a
Debian release you are not running. Section 04 shows that file lying to you in a listing.
