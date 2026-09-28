---
title: Two engines, one language
version: 1
---

**Snort** was written in 1998 and defined how network intrusion detection is done in the open: a
rule language that describes a packet or a conversation, and an engine that matches every rule
against the traffic. **Suricata** arrived in 2010 and deliberately read the same rules. That shared
language is the most useful thing to know about either, because rules are where the work is, and a
rule written for one is, most of the time, a rule for the other.

| | Snort 2 | Snort 3 | Suricata |
|---|---|---|---|
| rule language | the original | the original, with small changes | the original, plus keywords of its own |
| processing | one thread per process | multi-threaded | multi-threaded |
| configuration | `snort.conf` | Lua | YAML |
| output most used | unified2 files, alert lines | JSON and alert lines | `eve.json`, one JSON object per event |
| also records | alerts | alerts, and application data with add-ons | alerts, flows, and HTTP, DNS, TLS and more, by default |

**The last row is the practical difference** for a defender with one engine to choose. Suricata writes
a record of every HTTP request, DNS query and TLS handshake it sees whether or not a rule matched, which
lesson 2 used to name protocols and this lesson uses to find something no rule was written for.

This course runs Suricata, the version Ubuntu 24.04 packages. Snort is not installed in the lab and no
command in this lesson was run on it; where Snort's syntax differs, the prose says so.

The rules themselves come from two places. **Published rule sets**, of which the free Emerging Threats
Open set is the best known, hold tens of thousands of signatures for known malware, exploits and
policy violations, maintained by people whose job it is and updated daily. **Local rules** describe
what only this network knows: which paths are private, which protocols have no business on which
segment, which login is sensitive. Every deployment needs both, and this lesson is about writing the
second kind.
