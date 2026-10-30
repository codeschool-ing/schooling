---
title: What a finding is, and where findings come from
version: 1
---

**Security Command Center collects findings about an organisation's resources into one list: a finding is one
problem, on one resource, from one source, with a severity and a state.** It is the place where lesson 2's
vulnerability scan, a misconfigured bucket and a suspicious change of permissions end up side by side, so that
somebody can decide what to do first. **Nothing in this lesson reaches Security Command Center**, which has no
emulator and works at the level of an organisation. It is taught from Google's documentation; the practice is
triage, on a list of findings the course writes, in the next section.

## Where findings come from

| source | what it finds | finding class |
|---|---|---|
| Security Health Analytics | misconfigurations: a public bucket, a firewall open to the world, a key never rotated | `MISCONFIGURATION` |
| vulnerability scanning | known vulnerabilities in images and in machines' packages (lesson 2's scan, among others) | `VULNERABILITY` |
| Event Threat Detection | suspicious activity read from the logs: an unusual permission grant, access from a known bad address | `THREAT` |
| Container Threat Detection | suspicious behaviour inside running GKE containers | `THREAT` |

The first kind is about what is configured, the second about what is installed, the third and fourth about what
is happening. A misconfiguration is a door left open; a threat finding says somebody may have walked through one.

## The fields that matter for triage

- **`severity`**: `CRITICAL`, `HIGH`, `MEDIUM` or `LOW`, set by the source from how exploitable and damaging the
  problem is in general. It does not know whether the resource matters to you.
- **`state`**: `ACTIVE` while the problem is there, `INACTIVE` once the source sees it fixed. A misconfiguration
  finding goes inactive on its own when the configuration is corrected; nobody closes it by hand.
- **`mute`**: `MUTED` hides a finding from the default views without fixing anything. Muting is for a finding
  somebody has judged acceptable (a sandbox nobody uses for anything real), and **a mute rule is a decision that
  has to be written down with its reason**, because it hides every future finding that matches it.
- **`resourceName`**: the full name of what the finding is about, which is how a finding is tied to an owner
  (lesson 23's labels answer "whose is this?").

## Tiers

Security Command Center has a **Standard** tier, at no charge, with a subset of Security Health Analytics' checks,
and **Premium** and **Enterprise** tiers that add the rest of the detectors, threat detection, attack path
simulation and compliance reports. Google's pricing page, read on 30 October 2026, says that only the Premium and
Enterprise tiers are charged, priced by subscription or by usage; the numbers depend on the organisation's
overall Google Cloud spend and are not quoted here.
