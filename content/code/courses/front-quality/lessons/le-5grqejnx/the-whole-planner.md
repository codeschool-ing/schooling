---
title: What the planner holds now
version: 1
---

**The planner started this course as an app nobody had tested, written with a wrong week, a placeholder for
a label, no defence against a script in a note, and a focus nobody could see.** Every one of those is now
a test that fails if it comes back: thirty-six unit and component tests, twenty-eight end-to-end, and
twenty-four commits of history saying when each arrived.

```
ana@dev:~/planner$ npx tsc --noEmit && npx vitest run 2>&1 | grep -E "Test Files|Tests "
 Test Files  6 passed (6)
      Tests  36 passed (36)
ana@dev:~/planner$ npx playwright test 2>&1 | tail -1
  28 passed (9.5s)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "A page that reflows at 320 pixels, and a size floor for every button"
ana@dev:~/planner$ git log --oneline | wc -l
24
```

| part of the course | what it left in the planner |
|---|---|
| testing, lessons 1 to 4 | unit tests of the pure functions, component tests with Testing Library, end-to-end tests with Playwright, and the time-zone bug they found |
| security, lessons 5 to 9 | a session in an `HttpOnly` cookie, a CORS policy, a CSP with its report, a note shown as text, an Origin check, and a page no other site can frame |
| accessibility, lessons 10 to 13 | axe at WCAG 2.2 AA in both themes, a keyboard path with a visible focus that stays where it makes sense, names and landmarks and a status line for a screen reader, contrast that is computed, targets that can be hit, motion that can be refused, and a page that reflows |

## What none of it replaces

Each third of this course ended on the same sentence in different words: **a test checks what somebody
thought to ask.** The unit tests do not know what the user meant; the security tests do not know the attack
nobody imagined; axe and every test of lessons 11 to 13 do not hear the page. The walk by keyboard, the
listening with a screen reader and the zoom to 400% are still somebody's job, once per change to a screen,
and the tests are what make that hour short enough to be done.
