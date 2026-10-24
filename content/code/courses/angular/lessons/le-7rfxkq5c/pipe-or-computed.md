---
title: A pipe, a computed, or a method?
version: 1
---

**A pipe formats a value for a template; a `computed` works out a value for the class.** Both are
remembered until their inputs change, which is what makes both cheap. A method called in a template
is remembered by nothing, and runs on every check of the component, like an impure pipe.

| the template needs | write | why |
|---|---|---|
| a value shown a particular way, in several components | a pipe | one definition, imported where it is used, tested with `new` |
| a value derived from state, for this component | a `computed` | tracked like any signal, and readable in the class too |
| a value worked out once per check, cheaply | a method | acceptable when it is cheap, like `asText()` in lesson 14 |
| state that is the same everywhere | in the store | lesson 11's rule: a fact about the planner moves there |

The planner has all four: `minutes` is a pipe because five templates say durations the same way;
`rows` in `Week` is a `computed` because it is that screen's shape; `shows()` in the form is a method
because it is two comparisons; `weekTotals` is in the store because every screen agrees on it.

The bench goes:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M angular.json
 M src/app/course-card/course-card.ts
 M src/app/course-page/course-page.html
 M src/app/course-page/course-page.ts
 M src/app/session-row/session-row.ts
 M src/app/week-summary/week-summary.html
 M src/app/week-summary/week-summary.ts
 M src/app/week/week.html
 M src/app/week/week.spec.ts
 M src/app/week/week.ts
?? src/app/minutes-pipe.spec.ts
?? src/app/minutes-pipe.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Pipes: dates in British English, and durations in words"
```
