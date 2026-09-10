---
format: 5
course: cloud-security
---

# cloud-security

**Cloud Security** · `co-9vbtjae4` · 50 h declared · intermediate · 17 lessons · `security` · paid

## Reach

In **2 tracks** — `devsecops`(15), `security`(13).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `cloud` — regions, managed services and the shared-responsibility line, which lesson 2 then makes the course's spine.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 50 h |
| lessons | 17 |
| **hours per lesson** | **2.94** |
| section budget | ~107, about 6.3 a lesson |
| exercises | ~500, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a real cloud account**, and lesson 5 wants three of them |
| browser · database | the consoles are browser interfaces · no |
| exercises **blocked** | **~350 (65%), by a bill rather than by engineering** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~50 — the responsibility line moving across SaaS, PaaS and IaaS; an escalation path; a bucket exposed; egress control |

## Ageing

**Moderate to severe.** Lesson 5 is three providers' equivalent services and lesson 15 names CloudTrail. The shared-responsibility model itself is permanent.

## Flags

**1 ·** **The thirteenth course blocked by a vendor bill**, after the twelve `aws-`/`azure-`/`gcp-` courses. Unlike those it is not tied to one provider — lesson 5 is explicitly the three side by side — so it needs accounts at all three to be taught as written, which is worse rather than better.

**2 ·** **Lesson 9 is the course in one line** — *"Exposed storage: public buckets and the most common mistake of the decade"* — and it is demonstrable without any account at all, from public incident write-ups. **The design instruction is to lean on real incidents where the sandbox fails**, which is available here in a way it is not for a course about building something.

**3 ·** **Two tracks, no dependents, and it arrives late in both** — `security`(13) and `devsecops`(15). Its prerequisite `cloud` is the `infra` hub with six dependents, so this course is well-supported from below and supports nothing above.
