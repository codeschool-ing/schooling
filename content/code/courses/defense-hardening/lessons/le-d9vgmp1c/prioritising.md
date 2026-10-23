---
title: Deciding what comes first
version: 1
---

**Severity says how bad a flaw would be. Priority says how soon you have to act, and it needs two
more facts.** The first is whether anybody is exploiting the flaw. The second is whether it can be
reached on your machine at all. Both are in the feed or in what you already know.

| signal | what it is | who publishes it |
|---|---|---|
| **KEV** | the Known Exploited Vulnerabilities catalogue: flaws with evidence of exploitation in real attacks | CISA, the US cybersecurity agency |
| **EPSS** | the Exploit Prediction Scoring System: the probability, from 0 to 1, that a flaw will be exploited in the next 30 days | FIRST, the maintainers of CVSS |
| **exposure** | whether the vulnerable program is reachable, here, from the network | you: lesson 1's scan, lesson 18's inventory |

KEV and EPSS were not downloaded for this course; the feed carries invented values in their shape.
The real KEV list holds somewhat over a thousand entries, out of the hundreds of thousands of CVEs
ever published, and **that ratio is the argument for using it**: most flaws are never used by anybody, and a
team that treats every 7.5 as urgent spends its weeks on the wrong ones.

The firm's policy, written as code so that it can be read, argued about and applied the same way
every time:

```schooling-example
{"language": "python", "file": "prioritise.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"prioritise.py FEED FOUND_ON < vulncheck output: rank what applies, and give each a due date.\"\"\"\nimport datetime, json, sys\nfrom cvss import score\n\n# Jatobá's policy, written down: what makes a finding urgent, and how long each level may take.\nEXPOSED = {\"nginx\", \"openssh-server\", \"vsftpd\"}   # listening on web, from the scan in lesson 1\nDAYS = {\"P1\": 7, \"P2\": 30, \"P3\": 60, \"P4\": 90}", "note": "The policy is at the top because it is the part people argue about: which packages are reachable from the network, from lesson 1's scan, and how many days each level gets."}, {"code": "\ndef level(adv, base):\n    if adv[\"kev\"]:\n        return \"P1\", \"exploited in the wild\"\n    if adv[\"epss\"] >= 0.10:\n        return \"P2\", \"likely to be exploited soon\"\n    if base >= 7.0 and adv[\"package\"] in EXPOSED:\n        return \"P2\", \"severe, and reachable from the network\"\n    if base >= 7.0:\n        return \"P3\", \"severe, not reachable from the network\"\n    return \"P4\", \"the rest\"", "note": "The levels, in order. Known exploitation beats everything; a high chance of exploitation comes next; then severity, weighted by whether the flaw can be reached from the network at all."}, {"code": "\nfeed = {a[\"id\"]: a for a in json.load(open(sys.argv[1]))}\nfound = datetime.date.fromisoformat(sys.argv[2])\nrows = []\nfor line in sys.stdin:\n    if line.rstrip().endswith(\"VULNERABLE\"):\n        adv = feed[line.split()[0]]\n        base = score(adv[\"cvss\"])\n        lv, why = level(adv, base)\n        rows.append((lv, -base, adv[\"id\"], adv[\"package\"], base, adv[\"epss\"], why))\nfor lv, _, ident, pkg, base, epss, why in sorted(rows):\n    due = found + datetime.timedelta(days=DAYS[lv])\n    print(f\"{lv}  due {due}  {ident}  {pkg:15} cvss {base:4}  epss {epss:5}  {why}\")", "note": "Only the lines `vulncheck.py` marked `VULNERABLE` are read. The output is sorted by level and then by score, highest first, and each line carries its due date, counted from the day the finding was made rather than the day the report was printed."}]}
```

Feed it what `vulncheck.py` found, with the date the finding was made:

```
ana@admin:~$ python3 vulncheck.py feed.json web | python3 prioritise.py feed.json 2026-10-23
P1  due 2026-10-30  JTB-2026-02  nginx           cvss  7.5  epss  0.41  exploited in the wild
P2  due 2026-11-22  JTB-2026-01  openssh-server  cvss  8.1  epss  0.02  severe, and reachable from the network
P2  due 2026-11-22  JTB-2026-05  vsftpd          cvss  7.5  epss  0.05  severe, and reachable from the network
P4  due 2027-01-21  JTB-2026-07  libssl3t64      cvss  5.9  epss  0.01  the rest
P4  due 2027-01-21  JTB-2026-04  curl            cvss  4.3  epss 0.003  the rest
```

Read it against the scores alone. **nginx comes first although OpenSSH scores higher**, because
nginx's flaw is on the exploited list: somebody is using it now. OpenSSH and vsftpd come next, both
severe and both listening on the network. libssl and curl come last; curl's flaw needs a user to
fetch something from a malicious site, and nobody browses from the portal.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-priority\" aria-label=\"The five findings that apply to web, placed by CVSS base score along the bottom and by EPSS, the probability of exploitation, up the side. nginx sits at 7.5 and 0.41 and is marked as known exploited, priority 1. OpenSSH at 8.1 and 0.02 and vsftpd at 7.5 and 0.05 are priority 2. libssl at 5.9 and 0.01 and curl at 4.3 and 0.003 are priority 4. The highest score is not the first priority.\"><path d=\"M90.0 250.0 L660.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 250.0 L90.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"204.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"318.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><text x=\"432.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"546.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"660.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><text x=\"80.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0</text><text x=\"80.0\" y=\"208.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.1</text><text x=\"80.0\" y=\"166.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2</text><text x=\"80.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.3</text><text x=\"80.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4</text><text x=\"80.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.5</text><text x=\"375.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">CVSS base score</text><text x=\"80.0\" y=\"24.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">EPSS</text><circle cx=\"489.0\" cy=\"77.8\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"499.0\" y=\"63.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">nginx  P1</text><circle cx=\"557.4\" cy=\"241.6\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"567.4\" y=\"227.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">openssh-server  P2</text><circle cx=\"489.0\" cy=\"229.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"499.0\" y=\"203.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">vsftpd  P2</text><circle cx=\"306.6\" cy=\"245.8\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"316.6\" y=\"231.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">libssl3t64  P4</text><circle cx=\"124.2\" cy=\"248.7\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"134.2\" y=\"234.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">curl  P4</text><text x=\"499.0\" y=\"81.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">known exploited</text></svg>", "caption": "Priority is not the highest score: it is the score, the likelihood and the exposure together."}
```

vsftpd's line deserves a second look. Its fix is a version upgrade, and its better fix is lesson 1's:
the portal does not need an FTP server at all. **Removal is remediation**, often the fastest kind,
and the verify step proves it the same way as a patch:

```
ana@web:~$ sudo apt-get purge -y -q vsftpd 2>&1 | grep -E "^(Removing|Purging)" | cut -d" " -f1,2
Removing vsftpd
Purging configuration
ana@admin:~$ python3 vulncheck.py feed.json web | grep vsftpd
JTB-2026-05  vsftpd          -                            fixed in 3.0.5-0ubuntu3.2           not installed
```

`not installed` is the strongest answer an assessment can give.
