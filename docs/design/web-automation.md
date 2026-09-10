---
format: 5
course: web-automation
---

# web-automation

**Web Test Automation** · `co-kqqqxb7w` · 70 h declared · intermediate · 22 lessons · `quality` · paid

## Reach

In **1 track** — `qa`(8).

**Depends on it:** `non-functional-testing`

## Assumes, and leaves ready

**Assumes:** `javascript` and `manual-testing` — a language, and cases worth automating. **The ordering is the course's own argument**: you automate a case that already exists.

**Leaves ready:** the automation base, for `non-functional-testing`.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 22 |
| **hours per lesson** | **3.18** |
| section budget | ~150, about 6.8 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a browser driver and an application to drive** — Selenium, Cypress or Playwright against **an application with known flaws, that resets** — authored material rather than an environment |
| browser · database | **yes, centrally** · no |
| exercises **blocked** | **~500 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~60 — the WebDriver architecture, a Page Object, an explicit wait against an implicit one, the testing pyramid, a flaky test's timing drawn twice |

## Ageing

**Moderate to severe.** Lesson 11 alone names eight tools. Selenium, Cypress and Playwright are the three that matter and they move fast.

## Flags

**1 ·** **This repository is the fixture and the example at the same time.** `tools/a11y-test`, `tools/graph-test`, `tools/landing-test` and `tools/bundle-test` are Playwright suites driving a real application — lesson 10 is Playwright, lesson 12 is the Page Object pattern, lesson 16 is screenshots and traces for diagnosing a failure, lesson 19 is parallel execution. **The strongest teach-from-itself case in the entire sweep**, and stronger than `db-reliability`'s `restore-drill` because it is four suites rather than one.

**2 ·** **Lesson 14 is the course's hardest idea and the platform has lived it** — *"Flaky tests: causes, diagnosis and quarantine"*. Worth writing from real cases rather than in the abstract, and this repository has them.

**3 ·** **Lessons 21 and 22 are where the course stops selling automation** — the testing pyramid, and *"What not to automate: the test that costs more than the defect"*. That is judgement, it closes the course, and it is the part a reader who came for Selenium will skim. Same shape as `delivery-metrics`'s lesson 20.
