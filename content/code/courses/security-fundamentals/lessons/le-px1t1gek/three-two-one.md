---
title: The 3-2-1 rule
version: 1
---

How many copies, and where? The rule of thumb that has survived several generations of technology is
**3-2-1**:

```schooling-figure
{"svg": "<svg id=\"sf-three-two-one\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The 3-2-1 rule at the shop. Three copies: the live data on the server db, a nightly backup on a disk in the office, and a weekly copy off site. Two kinds of storage: the server's disk and an external or cloud copy. One copy away from the shop.\"><defs><marker id=\"sf-three-two-one-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"440\" height=\"140\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the shop's office</text><rect x=\"40\" y=\"60\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 · live data</text><text x=\"130\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on db</text><rect x=\"260\" y=\"60\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2 · nightly backup</text><text x=\"350\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">disk in the office</text><rect x=\"510\" y=\"60\" width=\"190\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 · weekly copy</text><text x=\"605\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">off site, encrypted</text><path d=\"M220 95 L260 95\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-three-two-one-ah-wire)\"></path><path d=\"M440 95 L510 95\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-three-two-one-ah-wire)\"></path><text x=\"20\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">3 copies</text><text x=\"250\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">2 kinds of storage</text><text x=\"510\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">1 off site</text><text x=\"20\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and today, one of them offline or immutable</text></svg>", "caption": "Three copies, two kinds of storage, one away from the building."}
```

- **3** copies of the data: the original and two backups;
- on **2** different kinds of storage, so that one kind of failure does not take both: a disk and a
  cloud service, a server and a tape;
- **1** of them **off site**, somewhere a fire, a flood or a theft at the shop cannot reach.

For the shop: the live data on `db`; a nightly backup on the backup disk in the office; and a weekly
copy taken home by one of the owners on an encrypted external disk, or sent to a cloud storage
service. Three copies, two media, one away.

### The copy ransomware cannot reach

The original rule predates ransomware, and ransomware changed one thing: an attacker who controls the
server can delete or encrypt every backup the server can write to. A backup disk permanently plugged
into the server, or a cloud bucket the server's credentials can delete from, falls with the server.
So the modern version adds a requirement, often written **3-2-1-1-0**:

| addition | what it means |
|---|---|
| **1** copy offline or immutable | disconnected (a disk in a drawer) or stored where nothing, not even an administrator, can change it until a date has passed |
| **0** errors | every backup is verified and restore-tested, and the count of failures is zero |

The offline copy is lesson 3's R2 control, the one that saved the shop R$ 2,100 a year, and lesson
6's air gap: ransomware cannot encrypt what it cannot reach.

### Backups need protecting too

A backup holds the same customer list as the database, and lesson 1 warned that copies multiply the
places data can leak from. So backups are **encrypted**, and the key is kept somewhere other than the
backup, and somewhere other than the server it protects. Lose the key and the backups are useless;
store it on the server and ransomware takes it too. Lesson 1's tension between confidentiality and
availability lives exactly here, and the answer is a key with its own backup, held by a person.
