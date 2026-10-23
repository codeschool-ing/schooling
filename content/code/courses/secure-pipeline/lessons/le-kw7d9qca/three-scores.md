---
title: CVSS, EPSS and KEV, three answers to three questions
version: 1
---

Three numbers travel with advisories, and they are often read as three versions of one number,
"how serious is it". **They answer different questions.** CVSS says how bad the flaw is if
somebody exploits it. EPSS estimates how likely it is that somebody will try, soon. KEV says that
somebody already has. A flaw can be high on one and absent from the others, and the decisions they
support are different.

### CVSS: how bad, in the abstract

The Common Vulnerability Scoring System, maintained by FIRST, describes a flaw as a **vector** of
properties and computes a score from 0 to 10 from them. The base score describes the flaw itself,
not your deployment. pip-audit's table carries no score; Trivy, which the next section uses as a
second opinion, does. Its report for gunicorn's first smuggling flaw holds two vectors:

@@CAPTURE cvss@@

Read the vector a field at a time. `AV:N`, reachable over the network. `AC:L`, no special
conditions. `PR:N`, no account needed. `UI:N`, no user has to click anything. `S:U`, the damage
stays within the component. Then the impact on confidentiality, integrity and availability: `H`
high, `L` low, `N` none.

**The two sources disagree**, and on one letter: GitHub's reviewers rate the confidentiality
impact `C:L` and Red Hat's rate it `C:N`, so one scores 8.2 and the other 7.5. Neither is wrong.
Each scored the same description and judged one consequence differently. That is the normal state
of CVSS, and it is why a severity printed by a tool says which source it chose, or should. Both
scores fall in CVSS's high band, 7.0 to 8.9, and Trivy reports `HIGH`.

What the base score cannot know is everything about you. It assumes the vulnerable code is reached
and exposed. The Flask flaw of the previous section scores the same for linkbox, which never
touches the session, as for a service built around it. CVSS has an environmental group of metrics
for exactly that adjustment, and almost nobody fills it in.

### EPSS: how likely, soon

The Exploit Prediction Scoring System, also from FIRST, gives each CVE a **probability**, between 0
and 1, that exploitation activity against it will be observed in the next thirty days. It is
produced by a model trained on what has actually been seen exploited, and republished every day,
so the number for one CVE moves over time. FIRST publishes it at `api.first.org`. This course's
machine cannot reach that address, so **no EPSS number is quoted in this lesson**; what is said
here is from FIRST's documentation.

EPSS answers the question CVSS does not ask. Most published flaws are never exploited at all, and
a high CVSS score on one of them is a statement about its consequences, not its odds.

### KEV: it has already happened

The Known Exploited Vulnerabilities catalogue, kept by CISA, the United States' cybersecurity
agency, lists CVEs with **reliable evidence of exploitation in the wild** and a remediation
available. It is a list, not a score: a CVE is on it or not. American federal agencies must fix
what is on it by a deadline, and everyone else can use the same list as the strongest signal there
is. CISA publishes it as JSON, and keeps a copy in a repository on GitHub:

@@CAPTURE kev@@

The catalogue of 21 October 2026 holds 1754 CVEs. `grep -cxFf` counts the lines of the catalogue
that exactly match a line of `/tmp/cves.txt`, linkbox's fifteen CVEs: **none of them is on it**.

### Three questions, side by side

| | asks | published by | changes | does not tell you |
|---|---|---|---|---|
| CVSS | how bad, if exploited | the CVE's sources: NVD, GitHub, vendors | rarely | whether anyone will try, or whether you are exposed |
| EPSS | how likely to be exploited in 30 days | FIRST | daily | how bad, or whether you are exposed |
| KEV | has it been exploited | CISA | when evidence arrives | anything about a CVE not yet on it |

**None of the three answers the question of the previous section**, whether linkbox reaches the
code. That one is yours. A reasonable order of attention, when there is more to fix than time:
anything on KEV first, whatever its score; then what is reachable and likely; then what is
reachable and severe; then the rest, in the next routine update. Lesson 7 writes rules of that kind
into the gate.

For linkbox the order hardly matters. Nothing is on KEV, three findings are reachable, every one
has a fix, and the fix is the last section of this lesson.
