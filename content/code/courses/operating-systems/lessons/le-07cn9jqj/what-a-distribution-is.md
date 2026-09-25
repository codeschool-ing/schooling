---
title: What a distribution is
version: 1
---

Lesson 1 said that Linux, strictly, is only the **kernel**. Nobody installs a kernel on its own.
A **distribution** is the kernel together with everything a working system needs around it, chosen,
built and tested by one group of people, and published with a promise about how long they will keep
fixing it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A distribution drawn as five layers, from the bottom. The kernel, Linux from kernel.org, the same project everywhere. Tools and libraries, such as GNU coreutils, bash and glibc, mostly the same. The package manager, on this server apt and .deb packages, which differs by family. The repositories, on this server archive.ubuntu.com, which differ by distribution. And releases and support, here an LTS release every two years, which is the part you are really choosing.\"><defs><marker id=\"ly-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">layer</text><text x=\"250\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on this server</text><text x=\"480\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">across distributions</text><rect x=\"20\" y=\"30\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">releases and support</text><text x=\"250\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">an LTS every two years</text><text x=\"480\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the part you are choosing</text><rect x=\"20\" y=\"72\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the repositories</text><text x=\"250\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">archive.ubuntu.com</text><text x=\"480\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">differs by distribution</text><rect x=\"20\" y=\"114\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the package manager</text><text x=\"250\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">apt and .deb</text><text x=\"480\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">differs by family</text><rect x=\"20\" y=\"156\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tools and libraries</text><text x=\"250\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">GNU coreutils, bash, glibc</text><text x=\"480\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mostly the same</text><rect x=\"20\" y=\"198\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the kernel</text><text x=\"250\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Linux, from kernel.org</text><text x=\"480\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the same project everywhere</text></svg>", "caption": "Going up, the layers differ more. Choosing a distribution is mostly choosing the top two: where the software comes from, and for how long somebody fixes it."}
```

The server can say which one it is. Every modern distribution writes the answer to the same file:

```
ana@server:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.5 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
```

Three lines of that are for programs rather than people:

- `ID=ubuntu` is the distribution, in a form a script can compare.
- `ID_LIKE=debian` is the family it belongs to. A script that knows how to install something on
  Debian can read this line and conclude that the same commands work here. That is section 02.
- `VERSION_CODENAME=noble` is the release, by name. Ubuntu's codenames go alphabetically, so the
  letter tells you roughly how old a release is.

`/etc/os-release` exists on Fedora, Debian, Arch, SUSE and Alpine too, with the same keys. It is the
first thing to read on a machine somebody else set up, before typing any command that installs
anything.

## Why the differences matter

The kernel and the basic commands are close to identical everywhere, which is why most of lesson 12's
commands work on any of them. What changes are the *top layers*: the command that installs
software, the name of a package, the path of a configuration file, and above all **how long the
release in front of you will receive security fixes**. A tutorial that says `dnf install` is no use
on this server, and a forum answer for Arch can quietly assume a newer version of everything.
