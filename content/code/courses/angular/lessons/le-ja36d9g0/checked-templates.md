---
title: Templates are checked like code
version: 1
---

**The CLI type-checks every template against its class, at build time, as strictly as it checks the
TypeScript.** Lesson 2 pointed at the switch, `strictTemplates`, in `tsconfig.json`. This section is
what it buys: mistakes that would have reached the browser in a framework that reads its
templates at run time. Break the bench's template in three places at once:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p>{{ minuts }} minutes</p>
<button type="button" (click)="add()">Add</button>
<progress [value]="minutes" [max]="'240'"></progress>
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A1 ERROR
✘ [ERROR] TS2551: Property 'minuts' does not exist on type 'Bench'. Did you mean 'minutes'? [plugin angular-compiler]

--
✘ [ERROR] TS2554: Expected 1 arguments, but got 0. [plugin angular-compiler]
```

Two errors, each a TypeScript error code from lesson 1, now pointing into HTML:

- **`TS2551`**, the misspelt field, with the same *Did you mean* that `tsc` offered for `minuts` in
  lesson 1. A template that read a field nobody has would show an empty paragraph, and nobody would
  notice until a user did.
- **`TS2554`**, a method called without the argument it requires. The compiler knows `add` takes one
  number, because it read the class.

And one mistake it let through: `[max]="'240'"` hands a string to a property that holds a number.
**Bindings to the properties of plain HTML elements are not type-checked**; the browser converts the
string, and here it converts it correctly, so the bar works. The checking covers what is yours: your
class's fields and methods, and from lesson 8 your components' inputs. Write `[max]="240"`, without the
inner quotes, all the same: it says what you mean.

None of these would have stopped the page from loading. Each would have been a small wrong thing on a
screen, which is the most expensive kind of bug to find. **A template that compiles is a template
whose every name exists and whose every call fits its method.** It does not mean the page says the
right thing; that is what tests are for.

The dev server reports the same errors in its terminal and shows them over the page in the browser,
as an overlay, so you see them without looking away from what you were checking. The next section
removes the bench, errors and all.
