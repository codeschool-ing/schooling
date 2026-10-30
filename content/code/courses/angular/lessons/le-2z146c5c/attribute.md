---
title: An attribute directive, behaviour without a template
version: 1
---

**A directive is a component without a template: a class Angular attaches to an element that matches
its selector, to change how that element looks or behaves.** A component draws something new; a
directive works on something already there. Every `routerLink`, every `formControlName`, every
`ngModel` in this course has been a directive.

An **attribute directive** is written as an attribute and changes its element. The classic first
one, on a bench: a highlight that marks an element while the pointer is over it, or while it has the
keyboard's focus, which matters as much:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "// src/app/bench/bench.ts\nimport { ChangeDetectionStrategy, Component, Directive, input, signal } from '@angular/core';\n\n@Directive({\n  selector: '[appHighlight]',", "note": "The selector in brackets matches an attribute: any element with `appHighlight` on it gets one of these."},
 {"code": "  host: {\n    '[style.background-color]': 'active() ? colour() : null',\n    '(mouseenter)': 'active.set(true)',\n    '(mouseleave)': 'active.set(false)',\n    '(focusin)': 'active.set(true)',\n    '(focusout)': 'active.set(false)',\n  },\n})\nexport class Highlight {", "note": "`host` binds the element the directive sits on, as a template binds an element: properties and attributes in brackets, events in parentheses."},
 {"code": "  readonly colour = input('yellow', { alias: 'appHighlight' });\n  protected readonly active = signal(false);\n}", "note": "The input takes the directive's own name as its alias, so `appHighlight=\"khaki\"` sets the colour in one attribute."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Highlight],\n  template: `\n    <p appHighlight>A plain highlight.</p>\n    <button type=\"button\" appHighlight=\"khaki\">A khaki button</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {}"}
]}
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<nav aria-label="Planner">
  <a routerLink="/" routerLinkActive="current" [routerLinkActiveOptions]="{ exact: true }" ariaCurrentWhenActive="page">This week</a>
</nav>
<main>
  <router-outlet />
</main>
<app-bench />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { Bench } from './bench/bench';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

`Tab` moves the focus from one thing that can take it to the next. The bench comes after the
navigation's link and the week's three course links, so the fifth press reaches its button:

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-bench --do 'press Tab' --do 'press Tab' --do 'press Tab' --do 'press Tab' --do 'press Tab'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- press Tab
-- press Tab
-- press Tab
-- press Tab
-- press Tab
<app-bench><p apphighlight="">A plain highlight.</p><button type="button" apphighlight="khaki" style="background-color: khaki;">A khaki button</button></app-bench>
```

The paragraph is untouched, and the button has the background its attribute asked for, because it
has the focus. **`host` is how a directive changes its element.** Older code writes the same with
decorators on class members, `@HostBinding('style.background-color')` on a property and
`@HostListener('mouseenter')` on a method; the `host` object does the same and keeps every binding
in one place, which is what the Angular style guide now recommends.
