---
title: Reading the version completely
version: 1
---

"Which Windows is it?" has four answers, and a support ticket needs all of them. Lesson 2 opened the
`winver` window; this is what its line means.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The text winver prints, Windows 11 Pro, Version 24H2, OS Build 26100.4351, taken apart into four pieces. Windows 11 Pro is the product and the edition, which decides the features and how the PC can be managed. Version 24H2 is the feature update: the year and the half it came out in, and it decides whether support lasts 24 or 36 months. OS Build 26100 is the release, which is what programs check; 22000 or more means Windows 11. And .4351, the revision, is the monthly patches: it rises every Patch Tuesday and says how up to date the PC is.\"><defs><marker id=\"bd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what winver prints, taken apart</text><rect x=\"20\" y=\"32\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Windows 11 Pro</text><path d=\"M105.0 68 L105.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"105.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">product and edition</text><text x=\"105.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which features</text><text x=\"105.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and management</text><rect x=\"200\" y=\"32\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"285.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Version 24H2</text><path d=\"M285.0 68 L285.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"285.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the feature update</text><text x=\"285.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which year, which half</text><text x=\"285.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">24 or 36 months of support</text><rect x=\"380\" y=\"32\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">OS Build 26100</text><path d=\"M470.0 68 L470.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the release</text><text x=\"470.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what programs check</text><text x=\"470.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">22000 or more: Windows 11</text><rect x=\"570\" y=\"32\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.4351</text><path d=\"M635.0 68 L635.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"635.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the monthly patches</text><text x=\"635.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rises every Patch Tuesday</text><text x=\"635.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">how up to date it is</text></svg>", "caption": "Two PCs that both say \"Windows 11\" can differ in all four. A support ticket needs the whole line."}
```

- **The product and edition**, *Windows 11 Pro*. The edition is the subject of section 03.
- **The version**, *24H2*: the **feature update**, named for the year and the half it came out in.
  24H2 is the second half of 2024, and 25H2 followed a year later. Section 02 is about why it matters.
- **The build**, *26100*. Every feature update has one, and it is what programs and installers check,
  because it is a number. 22000 and above is Windows 11; Windows 10's last was 19045.
- **The revision**, *.4351*. It rises each time the month's security updates are installed, so two
  PCs on the same build can be months apart.

## Asking from the command line

```sh
winver                                     # the window: edition, version, build
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
  Select-Object ProductName, EditionID, DisplayVersion, CurrentBuild, UBR
```

**None of these were run for this lesson**; they are Windows commands, and the transcripts in this
course come from Linux. `Get-ItemProperty` reads the registry, which lesson 15 opens properly.

One of its values is famous for being wrong. **`ProductName` still says *Windows 10* on Windows 11**,
because Microsoft kept the value unchanged so that old programs checking it would not break. A script
that reads it to decide "is this Windows 11?" answers no on every Windows 11 PC. The build number and
`Caption` from `Get-CimInstance` are right; that is the general lesson too: **decide by the number, not
by the name**.
