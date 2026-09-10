---
format: 5
course: non-functional-testing
---

# non-functional-testing

**Non-functional Testing** · `co-61h5mnry` · 60 h declared · intermediate · 24 lessons · `quality` · paid

## Reach

In **1 track** — `qa`(10).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `web-automation` — a suite exists before you load-test with it or audit it.

**Leaves ready:** **nothing.** It ends the chain and the track's subject courses.

## Shape

| | |
|---|---|
| declared hours | 60 h |
| lessons | 24 |
| **hours per lesson** | **2.50** |
| section budget | ~129, about 5.4 a lesson |
| exercises | ~610, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a load generator, an application under load, and a screen reader** — three different things |
| browser · database | **yes**, for Lighthouse, AXE and keyboard navigation · no |
| exercises **blocked** | **~450 (65%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~70 — load shapes side by side, a percentile distribution against its mean, a bottleneck traced through four layers, tab order drawn over a page, Core Web Vitals |

## Ageing

**Moderate.** WCAG revises on a long cycle; JMeter and K6 move; lesson 22 names five monitoring SaaS products.

## Flags

**1 ·** **Three subjects in one course, and only the first is what the title suggests.** Lessons 1 to 11 are performance, 12 to 15 are accessibility, 16 to 21 are security, 22 to 24 are monitoring. That is defensible — they are the non-functional requirements — but **each third has a different environment and a different grader**, and a single 24-lesson arc will flatten them.

**2 ·** **The accessibility third is the platform's own obligation and its own tooling.** `tools/a11y-test` runs AXE against the student interface in CI; lesson 13 is *"Wave, AXE and the browser accessibility audit"*. **Second course in this batch that could be written from this repository**, and this one on material the platform is already held to.

**3 ·** **The security third duplicates `security` at overview depth, and no student meets both.** Lessons 16 to 21 — OWASP Top 10, injection, XSS, CSRF, secrets, scanning — are `attacks-threats` and `secure-code` compressed. `qa` reaches `security-fundamentals`(11) but never `secure-code`, so the overview is the only exposure a tester gets and is correctly placed. **Third instance of a compressed overview**, and the first one that is unambiguously right — unlike `ai-dev` in `ai` and `bi-techniques` in `data-science`.

**4 ·** **Lesson 8 is the statistical point and it is one lesson** — *"percentiles, throughput, error rate and why the mean misleads"*. `statistics` teaches exactly this and `qa` never reaches it. `numeric` grades it today.
