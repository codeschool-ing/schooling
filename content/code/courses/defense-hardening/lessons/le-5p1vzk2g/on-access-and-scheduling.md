---
title: When the scan runs, and what happens to what it finds
version: 1
---

**A scanner protects at the moments it runs, and the choice of moment is a design decision.** There
are three, and a desktop antivirus does all of them:

| | when | what it costs | what it misses |
|---|---|---|---|
| **on access** | every time a file is opened, written or executed | a delay on every file operation | nothing that is touched, if it is fast enough to keep up |
| **on demand, scheduled** | a full scan at night or weekly | disk activity for the length of the scan | everything between scans |
| **at the gate** | mail, downloads and removable media, as they arrive | delay at the gate | files that arrive another way |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l07-moments\" aria-label=\"The life of a file on a workstation, from left to right, and the three moments a scanner can look at it. At the gate, when it arrives by mail, download or USB stick. On access, every time it is opened, written or run. On a schedule, in the nightly scan, whether or not anybody touched it. Between scheduled scans, a file nobody opens is only seen on access if it is opened.\"><defs><marker id=\"l07-moments-dh-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M40.0 120.0 L690.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l07-moments-dh-ah-wire)\"></path><circle cx=\"90.0\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"90.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arrives</text><rect x=\"15.0\" y=\"145.0\" width=\"150.0\" height=\"34.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">at the gate</text><path d=\"M90.0 126.0 L90.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"300.0\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"300.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">opened, written, run</text><rect x=\"225.0\" y=\"145.0\" width=\"150.0\" height=\"34.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">on access</text><path d=\"M300.0 126.0 L300.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"560.0\" cy=\"120.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"560.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every night</text><rect x=\"485.0\" y=\"145.0\" width=\"150.0\" height=\"34.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">scheduled scan</text><path d=\"M560.0 126.0 L560.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the lab ran only on-demand scans</text></svg>", "caption": "Each moment covers a different gap; a desktop product uses all three."}
```

## On access, and why the lab cannot show it

ClamAV's on-access scanner, `clamonacc`, asks the kernel to hold every file open until the scanner
has looked at it. It uses **fanotify**, a kernel interface that belongs to the whole computer, so it
must run on the host itself, as root, and a container cannot use it. **On-access scanning was not run
for this course.** On a Linux computer of your own it is set up in `/etc/clamav/clamd.conf`, with
`OnAccessIncludePath` naming the directories to watch and `OnAccessPrevention yes` making the kernel
refuse access to a file that matches, rather than only reporting it.

Windows does the same in Microsoft Defender Antivirus, where it is called **real-time protection** and
is on by default; it is also how most commercial products work on every platform.

## Scheduled scans and quarantine

A scheduled scan is `clamscan` or `clamdscan` run by a timer, in exactly the way lesson 3 ran a
playbook. What matters is what it does with a match. Moving a file to a **quarantine** directory that
only root can read takes it out of reach without destroying the evidence:

```
ana@desk:~$ sudo install -d -m 700 /var/quarantine && sudo clamscan --no-summary -r -d lab.ndb --move=/var/quarantine samples/; ls samples; sudo ls /var/quarantine
samples/copy.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/copy.txt (real path: '/home/ana/samples/copy.txt'): moved to '/var/quarantine/copy.txt'
samples/changed.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/changed.txt (real path: '/home/ana/samples/changed.txt'): moved to '/var/quarantine/changed.txt'
samples/invoice.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/invoice.txt (real path: '/home/ana/samples/invoice.txt'): moved to '/var/quarantine/invoice.txt'
changed.txt
copy.txt
invoice.txt
```

`--move` moved each match and said where. The original directory is empty, the files are in
`/var/quarantine` with mode `700`, and a person can look at them, restore one that was a false
positive, or hand one to an analyst. **Deleting on detection is the one choice that cannot be
undone**, and with heuristics in the picture, some detections are wrong.

## The updater is part of the control

A scanner is only as current as its last update, and the updater is a service like any other:

```
ana@desk:~$ systemctl is-enabled clamav-freshclam; systemctl is-active clamav-freshclam; grep -E "^(DatabaseMirror|Checks)" /etc/clamav/freshclam.conf
disabled
inactive
Checks 24
DatabaseMirror db.local.clamav.net
DatabaseMirror database.clamav.net
```

On `desk` the service is disabled and inactive, because the lab has no network; it checks 24 times a
day when it runs, against two mirrors. On a real machine, **an updater that stopped working is a
scanner that quietly ages**, still reporting clean, and a monitoring check on the age of the
signature database belongs beside the check on the scanner itself.
