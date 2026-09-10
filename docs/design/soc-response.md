---
format: 5
course: soc-response
---

# soc-response

**SOC, Monitoring and Incident Response** · `co-1amdw8bz` · 70 h declared · advanced · 21 lessons · `security` · paid

## Reach

In **2 tracks** — `devsecops`(16), `security`(11).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `attacks-threats` — an analyst recognises what they have already been shown.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 21 |
| **hours per lesson** | **3.33** |
| section budget | ~150, about 7.1 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **logs containing a real attack** — authored fixtures, plus Wireshark, Autopsy and a SIEM |
| browser · database | SIEM dashboards are browser interfaces · no |
| exercises **blocked** | **~400 (55%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~70 — log sources mapped onto a network, a correlation rule firing, the six incident-response phases, a chain of custody, a packet capture annotated |

## Ageing

**Low.** Wireshark, tcpdump, dd and Autopsy are decades old. SIEM and SOAR products move, and they are named generically here rather than by vendor — which is why this course ages better than its subject suggests.

## Flags

**1 ·** **The fixture is the course, and it is the most expensive authored material the sweep has found.** Triage, hunting, IoCs, forensics and traffic analysis all need **realistic logs and captures containing a real attack, with the answer known** — not a machine, not an account, but data somebody has to construct so that the evidence is findable and the noise is convincing. That is harder than a vulnerable application, because the attack has to be legible in retrospect.

**2 ·** **And once built, it grades better than almost anything in `security`.** A packet capture, a log excerpt or a memory dump is a fixed artefact, so "which of these five events is the compromise" is a `quiz`, "order these into the kill chain" is an `ordering`, and "mark the indicator" is `labelling`. **The authored data unlocks the graders that already exist**, which is a much better return than most blocked courses offer.

**3 ·** **Lessons 11 to 15 are one method split five ways**, and lesson 19 is communicating with management, HR and legal. The same judgement problem `management` has, inside a technical course — and here the scenario-with-four-replies is the right shape, in five lessons rather than twenty-four.
