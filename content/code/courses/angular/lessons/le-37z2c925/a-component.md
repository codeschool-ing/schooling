---
title: What a component is made of
version: 1
---

**A component is a class, a template, and a decorator that joins them and says where they go.** The
class holds the data and the behaviour; the template is the HTML that draws them; the decorator tells
Angular the component's name in a template and what else its template may use. Everything else in
this course is built out of components, so this section reads one field by field.

The one `ng generate` wrote in lesson 2 has an empty template. Give it something to say, and a style
of its own:

```html
<!-- src/app/week-summary/week-summary.html -->
<p>This week: nothing planned yet.</p>
```

```css
/* src/app/week-summary/week-summary.css */
p {
  font-weight: 600;
}
```

The class is the one the CLI wrote, unchanged:

```schooling-example
{"language": "typescript", "file": "src/app/week-summary/week-summary.ts", "parts": [
 {"code": "import { Component } from '@angular/core';", "note": "`Component` is the decorator, imported from the framework like any other function."},
 {"code": "@Component({\n  selector: 'app-week-summary',", "note": "The **selector** is the tag that puts this component on a page. Any template that writes `<app-week-summary />` gets one."},
 {"code": "  imports: [],", "note": "What *this* template may use besides plain HTML: other components, directives and pipes. The next section is about this list."},
 {"code": "  templateUrl: './week-summary.html',\n  styleUrl: './week-summary.css',\n})", "note": "The template and the styles, each in a file beside the class. `template: '<p>…</p>'` and `styles: 'p { … }'` put them inline instead, which suits a component of a few lines."},
 {"code": "export class WeekSummary {}", "note": "The class. Empty for now: a template with no `{{ }}` in it reads nothing from it. Lesson 4 gives it fields."}
]}
```

## Standalone is the default

Every component you write in this course is **standalone**: it lists in its own `imports` what its
template uses, and nothing else needs to know about it. That has been the default since Angular 19,
which is why the decorator does not say so. Code written before that says `standalone: true` on
every component, and code that is not standalone says `standalone: false`, which this lesson's
section on NgModule code is about.

## Styles stay inside the component

The rule `p { font-weight: 600 }` in `week-summary.css` does not make every paragraph on the page
bold. Angular rewrites the component's styles so that they apply to its own template only, which is
called **view encapsulation**. The next section puts `WeekSummary` on the page, and once it is there
`look --html` shows how it works: with `--raw`, it keeps the attributes Angular adds.

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-week-summary --raw
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<app-week-summary _nghost-ng-c935675244=""><p _ngcontent-ng-c935675244="">This week: nothing planned yet.</p></app-week-summary>
```

Every element of the component carries the same invented attribute, `_ngcontent-` and a code. The
rule in the component's stylesheet is rewritten to match it, which `look --styles` shows by printing
every rule the browser holds:

```
ana@dev:~/planner$ look http://localhost:4200/ --styles
[vite] connecting...
[vite] connected.
Angular is running in development mode.
p[_ngcontent-ng-c935675244] { font-weight: 600; }
```

`p` became `p[_ngcontent-ng-c935675244]`. A `<p>` anywhere else lacks the attribute and keeps its
normal weight. The host element itself, `<app-week-summary>`, gets
`_nghost-` instead, which is what lets a stylesheet style the component's own box with `:host`.

You will rarely need to think about this. It matters on the day a style refuses to reach an element,
and the answer is almost always that the element belongs to a different component.
