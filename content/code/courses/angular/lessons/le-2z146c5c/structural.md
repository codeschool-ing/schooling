---
title: A structural directive, and the star
version: 1
---

**A structural directive decides whether, or how many times, a piece of template is drawn.** Before
lesson 5's `@if` and `@for` there were `*ngIf` and `*ngFor`, and older code is full of them. The star
is shorthand: Angular wraps the element in an `<ng-template>`, a piece of template that is not drawn
by itself, and hands it to the directive, which draws it as often as it decides.

```html
<p *ngIf="late">Overdue</p>

<!-- is short for -->
<ng-template [ngIf]="late">
  <p>Overdue</p>
</ng-template>
```

A directive of that kind is given the template as a `TemplateRef`, and the place in the page where
it goes as a `ViewContainerRef`, and draws the one into the other. The bench's second directive is
the opposite of `*ngIf`, drawn when its condition is false:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "// src/app/bench/bench.ts\nimport {\n  ChangeDetectionStrategy,\n  Component,\n  Directive,\n  TemplateRef,\n  ViewContainerRef,\n  effect,\n  inject,\n  input,\n  signal,\n} from '@angular/core';\n\n@Directive({\n  selector: '[appHighlight]',\n  host: {\n    '[style.background-color]': 'active() ? colour() : null',\n    '(mouseenter)': 'active.set(true)',\n    '(mouseleave)': 'active.set(false)',\n    '(focusin)': 'active.set(true)',\n    '(focusout)': 'active.set(false)',\n  },\n})\nexport class Highlight {\n  readonly colour = input('yellow', { alias: 'appHighlight' });\n  protected readonly active = signal(false);\n}"},
 {"code": "@Directive({\n  selector: '[appUnless]',\n})\nexport class Unless {\n  readonly appUnless = input.required<boolean>();\n  private readonly template = inject(TemplateRef);\n  private readonly place = inject(ViewContainerRef);\n\n  constructor() {\n    effect(() => {\n      if (this.appUnless()) {\n        this.place.clear();\n      } else if (this.place.length === 0) {\n        this.place.createEmbeddedView(this.template);\n      }\n    });\n  }\n}", "note": "The template to draw and the place to draw it, both injected. An effect redraws when the condition changes, and draws at most one copy."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Highlight, Unless],\n  template: `\n    <p appHighlight>A plain highlight.</p>\n    <button type=\"button\" appHighlight=\"khaki\">A khaki button</button>\n    <p *appUnless=\"done()\">Still to do.</p>\n    <button type=\"button\" (click)=\"done.set(true)\">Mark done</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  protected readonly done = signal(false);\n}", "note": "`*appUnless=\"done()\"` draws the paragraph while `done()` is false."}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Mark done'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Mark done
A plain highlight.

A khaki buttonMark done
```

The paragraph was there, and the click took it away. **New code needs this rarely**, because the
built-in control flow covers the common cases and is faster: `@if` and `@for` are part of the
template language, compiled straight into the view, while a structural directive is a class with a
dependency on two services. What remains for structural directives is a template that a library
hands you to draw, such as a table row a data grid draws once per row, and reading the code from
before Angular 17.
