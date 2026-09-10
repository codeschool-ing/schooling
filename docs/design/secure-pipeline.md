---
format: 5
course: secure-pipeline
---

# secure-pipeline

**Pipeline and Supply Chain Security** · `co-dkfznjdd` · 70 h declared · advanced · 20 lessons · `security` · paid

## Reach

In **1 track** — `devsecops`(13).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `testing-cicd` and `threat-modeling` — a pipeline to secure, and the risk vocabulary to decide what to break the build over.

**Leaves ready:** **nothing.** It ends the catalogue's deepest chain.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 20 |
| **hours per lesson** | **3.50** |
| section budget | ~150, about 7.5 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a CI pipeline with scanners in it**, plus a container registry and a cluster for lessons 8 to 10 |
| browser · database | no · no |
| exercises **blocked** | **~400 (60%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~60 — the pipeline with gates on it, a supply chain drawn end to end, an SBOM, signing and verification, false positives as a distribution |

## Ageing

**Moderate.** SLSA, Sigstore and SBOM formats are young and moving; SAST, DAST and SCA as categories are not. Lesson 11 names four scanners.

## Flags

**1 ·** **The end of the deepest chain in the catalogue.** `security-fundamentals` → `cryptography` → `attacks-threats` → `secure-code` → `threat-modeling` → here, **six deep**, plus `testing-cicd` from another category. Nothing else in the catalogue is behind six prerequisites, and 360 hours have to be right before this course means anything.

**2 ·** **This repository is a worked example of two thirds of it.** Quality gates that break the build, secret scanning, runner permissions, pinned dependencies, policy checks in CI — `.github/workflows/` does these, and `tools/check-origin` is policy-as-code by another name. **Third instance in the sweep of the platform being able to teach from itself**, after `tools/restore-drill` for `db-reliability` and `internal/privacy` for `data-governance`.

**3 ·** **Lesson 7 is the judgement the whole course turns on** — *"Quality gates: when to break the build and when to just warn"* — and it is judgement rather than technique, so it needs the scenario treatment. Get it wrong in the material and the reader learns to fail builds on false positives, which is how a security programme gets switched off.
