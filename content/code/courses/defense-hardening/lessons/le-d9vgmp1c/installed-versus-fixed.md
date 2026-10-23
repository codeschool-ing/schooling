---
title: What is installed, against what is fixed
version: 1
---

**An advisory says which version of a package fixes a flaw. A machine says which version it has.**
Assessment is putting the two side by side. Everything else a scanner does, the dashboards, the
categories, the history, is built on that one comparison, and doing it by hand once shows what the
tools are doing and where they go wrong.

Start with what `web` has:

```
ana@web:~$ dpkg-query -W -f='${Package} ${Version}\n' openssh-server nginx sudo curl
curl 8.5.0-2ubuntu10.16
nginx 1.24.0-2ubuntu7.18
openssh-server 1:9.6p1-3ubuntu13.20
sudo 1.9.15p5-3ubuntu5.24.04.4
```

These are Debian version strings, and each has up to three parts. `1:` in front of OpenSSH's is the
**epoch**, which overrides everything after it. `9.6p1` is the upstream version, the one OpenSSH's
own developers released. `-3ubuntu13.20` is the packaging revision: Ubuntu's twentieth update of
that package for this release, and **every security fix Ubuntu ships goes into that last number**,
because Ubuntu backports fixes into the version it shipped instead of moving to a newer upstream.

## An advisory feed

Real advisories come from the distribution (Ubuntu's USNs, with their OVAL data), from vendors and
from the CVE list. The feed below is not one of them: **it was written for this lesson**, with
invented identifiers, so that its numbers can sit next to the packages in your lab without claiming
anything about real flaws. Its shape is the shape of a real one: a package, the version that fixes
it, a severity vector, a probability of exploitation, and whether it is known to be exploited.
Write it on `admin` as `feed.json`:

```json
[
  {"id": "JTB-2026-01", "package": "openssh-server", "fixed": "1:9.6p1-3ubuntu13.21",
   "cvss": "AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:H", "epss": 0.02, "kev": false},
  {"id": "JTB-2026-02", "package": "nginx", "fixed": "1.24.0-2ubuntu7.19",
   "cvss": "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H", "epss": 0.41, "kev": true},
  {"id": "JTB-2026-03", "package": "sudo", "fixed": "1.9.15p5-3ubuntu5.24.04.2",
   "cvss": "AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H", "epss": 0.06, "kev": false},
  {"id": "JTB-2026-04", "package": "curl", "fixed": "8.5.0-2ubuntu10.17",
   "cvss": "AV:N/AC:L/PR:N/UI:R/S:U/C:L/I:N/A:N", "epss": 0.003, "kev": false},
  {"id": "JTB-2026-05", "package": "vsftpd", "fixed": "3.0.5-0ubuntu3.2",
   "cvss": "AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N", "epss": 0.05, "kev": false},
  {"id": "JTB-2026-06", "package": "python3.12", "fixed": "3.12.3-1ubuntu0.15",
   "cvss": "AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H", "epss": 0.11, "kev": false},
  {"id": "JTB-2026-07", "package": "libssl3t64", "fixed": "3.0.13-0ubuntu3.17",
   "cvss": "AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:N/A:N", "epss": 0.01, "kev": false}
]
```

Then the script that compares them. It runs on `admin` and reads `web` over SSH, using the key the
lab already trusts. The copy button hands over the program without the notes:

```schooling-example
{"language": "python", "file": "vulncheck.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"vulncheck.py FEED HOST: which advisories in FEED apply to the packages installed on HOST.\"\"\"\nimport json, subprocess, sys", "note": "The feed is a list of advisories; the second argument is the machine to check. Nothing is installed on that machine: the script runs on `admin` and asks over SSH, which is what makes it an **authenticated** check, one that reads the package database instead of guessing from the outside."}, {"code": "\nfeed = json.load(open(sys.argv[1]))\nout = subprocess.run([\"ssh\", sys.argv[2], \"dpkg-query -W -f='${Package} ${Version}\\\\n'\"],\n                     capture_output=True, text=True, check=True).stdout\ninstalled = dict(line.split(\" \", 1) for line in out.splitlines())", "note": "One SSH command lists every installed package with its exact version, and the answer becomes a dictionary from name to version."}, {"code": "\nfor adv in feed:\n    have = installed.get(adv[\"package\"])\n    if have is None:\n        state = \"not installed\"\n    elif subprocess.run([\"dpkg\", \"--compare-versions\", have, \"lt\", adv[\"fixed\"]]).returncode == 0:\n        state = \"VULNERABLE\"\n    else:\n        state = \"fixed\"\n    print(f'{adv[\"id\"]}  {adv[\"package\"]:15} {have or \"-\":28} fixed in {adv[\"fixed\"]:26} {state}')", "note": "The comparison is `dpkg --compare-versions`, never a comparison of strings. Debian versions carry an epoch (`1:`), the upstream version and a packaging revision, and `3ubuntu13.9` is older than `3ubuntu13.20` although it sorts after it as text. The exit status says whether the installed version is lower than the one that fixes the flaw."}]}
```

Run it against `web`:

```
ana@admin:~$ ls
cvss.py
feed.json
prioritise.py
vulncheck.py
ana@admin:~$ python3 vulncheck.py feed.json web
JTB-2026-01  openssh-server  1:9.6p1-3ubuntu13.20         fixed in 1:9.6p1-3ubuntu13.21       VULNERABLE
JTB-2026-02  nginx           1.24.0-2ubuntu7.18           fixed in 1.24.0-2ubuntu7.19         VULNERABLE
JTB-2026-03  sudo            1.9.15p5-3ubuntu5.24.04.4    fixed in 1.9.15p5-3ubuntu5.24.04.2  fixed
JTB-2026-04  curl            8.5.0-2ubuntu10.16           fixed in 8.5.0-2ubuntu10.17         VULNERABLE
JTB-2026-05  vsftpd          3.0.5-0ubuntu3.1             fixed in 3.0.5-0ubuntu3.2           VULNERABLE
JTB-2026-06  python3.12      3.12.3-1ubuntu0.17           fixed in 3.12.3-1ubuntu0.15         fixed
JTB-2026-07  libssl3t64      3.0.13-0ubuntu3.16           fixed in 3.0.13-0ubuntu3.17         VULNERABLE
```

Five of the seven apply. Two are `fixed`: `web` already has a later `sudo` and a later `python3.12`
than the versions that fixed those flaws, so nothing needs doing, and a report that listed them
anyway would be noise that trains people to skim. The other five are `VULNERABLE`: the installed
version is lower than the fixed one.

**This is the core of every authenticated scanner**, which logs in to the machine, reads the package
database and compares it with advisories. The next section is about scanners that do not log in, and
why their answers are worth less.
