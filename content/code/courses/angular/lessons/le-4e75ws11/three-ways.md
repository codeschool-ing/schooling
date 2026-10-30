---
title: Three ways to write a form, and which to use
version: 1
---

**Use reactive forms for anything that will grow, and recognise the other two when you meet them.**
The three are not competing styles of the same thing; each puts the form's model in a different
place, and that decides what is easy.

| | template-driven | reactive | Signal Forms |
|---|---|---|---|
| status in Angular 21 | stable | stable | experimental |
| the model | values in the class, controls made by the template | `FormGroup`, `FormArray`, `FormControl` in the class | a signal of a plain object, and a field tree over it |
| types | `any` | worked out from the controls | worked out from the model |
| rules | attributes and directives | validator functions | a schema function over paths |
| reading state | the template, or `NgForm` after a tick | `value`, `status`, `valueChanges` | signals: `value()`, `errors()`, `valid()` |
| where you meet it | older code, small forms | most Angular code of the last ten years | new code that accepts the risk |

**Template-driven** is fine for a search box or a newsletter sign-up: one or two fields, no rules
across them, nothing the class needs to read. **Reactive** is the default for everything else, and
what the planner uses. **Signal Forms** are worth trying on a new form where an API change would
cost an afternoon, and worth watching, because they are likely to become the default once they are
stable.

The bench goes, and the planner is as it was:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
```
