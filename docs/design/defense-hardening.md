---
format: 5
course: defense-hardening
---

# defense-hardening

**Endpoint Defence and Hardening** · `co-6xtb31q2` · 70 h declared · advanced · 19 lessons · `security` · paid

## Reach

In **1 track** — `security`(10).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `attacks-threats` — hardening is a list of answers, and it is unreadable without the questions.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 19 |
| **hours per lesson** | **3.68** |
| section budget | ~150, about 7.9 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a host the student can harden and break** — and lesson 3 is Group Policy, so a **Windows** one |
| browser · database | no · no |
| exercises **blocked** | **~450 (65%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~60 — a hardened host drawn against a default one, an ACL resolving, a honeypot in a network, the patch window as a timeline |

## Ageing

**Moderate.** CIS Benchmarks revise per operating-system release, and lesson 19 names five online analysis services. The rest holds.

## Flags

**1 ·** **It needs Windows, and that is the same wall `operating-systems` hit.** Group Policy, centralised configuration and per-application host firewall rules are Microsoft-shaped, and the `infra` sweep already found that three desktop operating systems cannot be handed out from a browser at any price. **This is the second course to need one**, and unlike `operating-systems` it cannot be re-framed as "the environment is the student's own" — a hardening exercise needs a machine that can be reset.

**2 ·** **Nineteen lessons that are a checklist, and lesson 18 says so.** *"Inventory and configuration as the basis of any defence"* is the argument the other eighteen rest on, and it arrives second from last. A course of controls needs its organising principle early or it reads as a list — **that is a sequencing note the section design can act on without moving the lesson.**

**3 ·** **`ordering` and `matching` carry this course further than they look.** Given this threat, which control; given these five controls, which order do you apply them in; which of these four is defence in depth and which is one layer twice. The material is unusually suited to the graders that exist, even where the practice is blocked.
