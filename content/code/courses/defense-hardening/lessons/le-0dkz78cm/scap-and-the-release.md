---
title: SCAP, and a guide for the wrong release
version: 1
---

**SCAP is the format that lets a guide be read by a program.** The Security Content Automation
Protocol is a family of standards from NIST: XCCDF describes a checklist of rules grouped into
profiles, OVAL describes how to test each rule on a machine, and CPE names the platforms a rule
applies to. A guide published as SCAP content can be evaluated by any SCAP scanner, and
**OpenSCAP** is the open-source one, packaged by Ubuntu as `oscap`.

The content comes from the ComplianceAsCode project, packaged as `ssg-debderived`. Here is what
Ubuntu 24.04's package carries:

```
ana@web:~$ ls /usr/share/xml/scap/ssg/content/ | grep ds.xml
ssg-ubuntu1604-ds.xml
ssg-ubuntu1804-ds.xml
ssg-ubuntu2004-ds.xml
ssg-ubuntu2204-ds.xml
ana@web:~$ oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml
xccdf_org.ssgproject.content_profile_cis_level1_server:CIS Ubuntu 22.04 Level 1 Server Benchmark
xccdf_org.ssgproject.content_profile_cis_level1_workstation:CIS Ubuntu 22.04 Level 1 Workstation Benchmark
xccdf_org.ssgproject.content_profile_cis_level2_server:CIS Ubuntu 22.04 Level 2 Server Benchmark
xccdf_org.ssgproject.content_profile_cis_level2_workstation:CIS Ubuntu 22.04 Level 2 Workstation Benchmark
xccdf_org.ssgproject.content_profile_standard:Standard System Security Profile for Ubuntu 22.04
```

A **data stream** (`-ds.xml`) is one file holding the checklist, the tests and the platform names
together. There is one per Ubuntu release up to 22.04, and none for 24.04: the package in the
archive was built before content for the new release existed. The 22.04 data stream offers five
profiles, and two of them are the CIS Level 1 and Level 2 profiles for servers.

## Evaluating the wrong one

It is tempting to assume that 22.04's rules are close enough. Evaluate the CIS Level 1 server
profile on `web` and count the results:

```
ana@web:~$ sudo oscap xccdf eval --profile cis_level1_server /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml | grep ^Result | sort | uniq -c
    291 Result
	notapplicable
```

Every rule in the profile came back **notapplicable**. No rule passed and no rule failed: the
scanner did not test anything at all. The reason is the platform each rule declares:

```
ana@web:~$ grep -o 'cpe:/o:canonical:ubuntu_linux:[0-9.]*' /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml | sort -u
cpe:/o:canonical:ubuntu_linux:16.04
cpe:/o:canonical:ubuntu_linux:18.04
cpe:/o:canonical:ubuntu_linux:20.04
cpe:/o:canonical:ubuntu_linux:22.04
ana@web:~$ grep VERSION_ID /etc/os-release
VERSION_ID="24.04"
```

The file names four Ubuntu releases, the newest of them 22.04, and the machine is 24.04. OpenSCAP
compares the two before it runs a single test, and with no platform matching it refuses the whole
profile. That refusal is the right answer, and it is the lesson: **a guide is written for one
release, and a scanner that applied it to another would report results that mean nothing**, some
rules testing files that moved, others passing because a package was renamed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l02-wrong-release\" aria-label=\"Why every rule came back not applicable. The 22.04 data stream holds 291 rules for the CIS Level 1 server profile, and each rule names the platforms it applies to, up to Ubuntu 22.04. Before any test runs, OpenSCAP compares that list with the machine, which is Ubuntu 24.04. No platform matches, so the test is never run and the result is notapplicable, for all 291 rules.\"><defs><marker id=\"l02-wrong-release-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-wrong-release-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"200.0\" height=\"140.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ssg-ubuntu2204-ds.xml</text><text x=\"120.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">291 rules in the profile</text><text x=\"120.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each applies to</text><text x=\"120.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ubuntu_linux:22.04</text><text x=\"120.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(and older)</text><rect x=\"270.0\" y=\"80.0\" width=\"180.0\" height=\"80.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">platform check</text><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">before any test</text><path d=\"M220.0 120.0 L270.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-wrong-release-dh-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"50.0\" width=\"200.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"600.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VERSION_ID=&quot;24.04&quot;</text><path d=\"M500.0 85.0 L450.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-wrong-release-dh-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"140.0\" width=\"200.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">291 notapplicable</text><text x=\"600.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nothing was tested</text><path d=\"M450.0 140.0 L500.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-wrong-release-dh-ah-amber)\"></path></svg>", "caption": "The scanner refused before it measured. A guide written for another release has no results to give."}
```

There are three honest ways forward, and none of them was run here. Use content built for 24.04,
which ComplianceAsCode publishes in its own releases and which a newer package will carry. Use
Canonical's `usg`, which ships 24.04 profiles with Ubuntu Pro. Or write the checks yourself for
the controls you care about, which is the next section. What is not honest is editing the
platform line in the 22.04 file to make the scanner run.

## What SCAP buys when it fits

When the content matches the release, the same command produces a pass or fail per rule and an
HTML report with `--report`, and `--remediate` applies the fixes the content carries. The format
is what makes a guide portable: an auditor can hand you the exact checklist they will use, and you
can run it before they arrive.
