---
title: What typed forms buy, and the code from before them
version: 1
---

**Since Angular 14 every reactive form is typed, and the types come from the values the controls
are made with.** In this lesson the compiler has known that `minutes` is a number, that `date` is a
string, that `form.value` may be missing a field and `getRawValue()` may not, and that a draft sent
to `store.add` has every field `Session` needs but the id and `done`. A misspelt control name, a
string where the store wants a number, a field forgotten in the draft: each is a build error now,
where before it was a form that sent the wrong thing.

**Code written before Angular 14 is untyped**, and `ng update` kept it working by renaming its
classes: `UntypedFormGroup`, `UntypedFormControl`, `UntypedFormBuilder`. Each is the old behaviour
under a name that says so, with every value `any`. Replacing one with its typed version, in a form
you are changing anyway, is how such code becomes typed, one form at a time; the compiler then lists
what the old form was getting away with.

| you need | use |
|---|---|
| a fixed set of named fields | `FormGroup`, or `fb.group` |
| a list whose length changes | `FormArray`, or `fb.array` |
| named fields not known in advance, all of one type | `FormRecord`, keyed by string |
| one field on its own | `FormControl`, or `fb.control` |

Angular 21 also ships an experimental third kind, **Signal Forms**, in `@angular/forms/signals`:
the form is a signal of a plain object, and every field's value and status is a signal too. Lesson
16 puts the three side by side. Reactive forms are what Angular applications are written with
today, and what the planner keeps.

The form is the lesson's one new file, with the store's `add` beside it:

```
ana@dev:~/planner$ git status --short
 M src/app/course-page/course-page.html
 M src/app/course-page/course-page.ts
 M src/app/planner-store.ts
?? src/app/add-session/
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Reactive forms: add sessions to a course"
```
