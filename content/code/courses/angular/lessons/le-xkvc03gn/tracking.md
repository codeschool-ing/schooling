---
title: What track is for
version: 1
---

**When a list changes, Angular keeps the DOM it already drew for every item whose track key it still
finds, and moves it, instead of drawing it again.** That is faster, and it is also what keeps what a
person typed, focused or scrolled attached to the right item. The track key decides what "the same
item" means, and a bad key quietly breaks it. Back to a bench to see it happen:

```
ana@dev:~/planner$ npx ng generate component bench --skip-tests
CREATE src/app/bench/bench.css (0 bytes)
CREATE src/app/bench/bench.ts (182 bytes)
CREATE src/app/bench/bench.html (20 bytes)
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-bench />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';
import { Bench } from './bench/bench';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {}
```

The bench draws the same three courses twice, once tracked by `course.id` and once by `$index`, with
an empty field on every row, and a button that reverses the list:

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';
import { Course } from '../planner';

@Component({
  selector: 'app-bench',
  imports: [],
  templateUrl: './bench.html',
  styleUrl: './bench.css',
})
export class Bench {
  protected courses: Course[] = [
    { id: 'html-css', name: 'HTML and CSS' },
    { id: 'javascript', name: 'JavaScript' },
    { id: 'git', name: 'Git' },
  ];

  protected reverse(): void {
    this.courses = [...this.courses].reverse();
  }
}
```

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<button type="button" (click)="reverse()">Reverse</button>
<h3>Tracked by id</h3>
@for (course of courses; track course.id) {
  <p><label>by id: {{ course.name }} <input /></label></p>
}
<h3>Tracked by position</h3>
@for (course of courses; track $index) {
  <p><label>by position: {{ course.name }} <input /></label></p>
}
```

Type 25 into the Git row of each list, then reverse:

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-bench --do 'fill by id: Git = 25' --do 'fill by position: Git = 25' --do 'click Reverse'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill by id: Git = 25
-- fill by position: Git = 25
-- click Reverse
- heading "Bench" [level=2]
- button "Reverse" [focused]
- heading "Tracked by id" [level=3]
- paragraph
  - LabelText
    - text: by id: Git 
    - textbox "by id: Git ": 25
- paragraph
  - LabelText
    - text: by id: JavaScript 
    - textbox "by id: JavaScript "
- paragraph
  - LabelText
    - text: by id: HTML and CSS 
    - textbox "by id: HTML and CSS "
- heading "Tracked by position" [level=3]
- paragraph
  - LabelText
    - text: by position: Git 
    - textbox "by position: Git "
- paragraph
  - LabelText
    - text: by position: JavaScript 
    - textbox "by position: JavaScript "
- paragraph
  - LabelText
    - text: by position: HTML and CSS 
    - textbox "by position: HTML and CSS ": 25
```

**Tracked by id, the 25 moved with Git** to the top of the list: Angular found the key `git` again,
kept that row's DOM, field and all, and moved it. **Tracked by position, the 25 stayed in the third
row, which is now HTML and CSS.** Position 2 was still there after the reverse, so Angular kept the
third row's DOM and only changed its text. Nothing errored, and the value a person typed is now
next to the wrong course.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two lists of three rows, before and after the list is reversed. Each row is a piece of DOM with a field; the Git row&#x27;s field holds 25. Tracked by id, the Git row&#x27;s DOM moves to the top, with its 25. Tracked by position, every row&#x27;s DOM stays where it was and only its text changes, so the 25 stays in the third row, which now says HTML and CSS.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tracked by id</text><text x=\"130\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">before</text><text x=\"590\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after Reverse</text><rect x=\"30\" y=\"42\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTML and CSS</text><rect x=\"170\" y=\"47\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"76\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JavaScript</text><rect x=\"170\" y=\"81\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"110\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Git</text><rect x=\"170\" y=\"115\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">25</text><rect x=\"490\" y=\"42\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Git</text><rect x=\"630\" y=\"47\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">25</text><rect x=\"490\" y=\"76\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JavaScript</text><rect x=\"630\" y=\"81\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"490\" y=\"110\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTML and CSS</text><rect x=\"630\" y=\"115\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M232 126 C 360 126, 360 56, 486 56\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"480\" y1=\"56\" x2=\"486\" y2=\"56\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"486.0,56.0 478.6,59.1 478.6,52.9\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the Git row moves, field and all</text><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tracked by position</text><text x=\"130\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">before</text><text x=\"590\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after Reverse</text><rect x=\"30\" y=\"182\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTML and CSS</text><rect x=\"170\" y=\"187\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"216\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JavaScript</text><rect x=\"170\" y=\"221\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"250\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Git</text><rect x=\"170\" y=\"255\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">25</text><rect x=\"490\" y=\"182\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Git</text><rect x=\"630\" y=\"187\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"490\" y=\"216\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JavaScript</text><rect x=\"630\" y=\"221\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"490\" y=\"250\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTML and CSS</text><rect x=\"630\" y=\"255\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">25</text><line x1=\"232\" y1=\"196\" x2=\"486\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"486.0,196.0 478.6,199.1 478.6,192.9\" fill=\"var(--wire)\"></polygon><line x1=\"232\" y1=\"230\" x2=\"486\" y2=\"230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"486.0,230.0 478.6,233.1 478.6,226.9\" fill=\"var(--wire)\"></polygon><line x1=\"232\" y1=\"264\" x2=\"486\" y2=\"264\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"486.0,264.0 478.6,267.1 478.6,260.9\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each row stays; only its text changes</text></svg>", "caption": "The key decides what counts as the same row. By position, the 25 ends up next to the wrong course."}
```

## Choosing the key

The key should be what makes an item *that* item, and never changes while it exists:

- **an id from the data**, `course.id` or `session.id`, is almost always right;
- **`$index`** is right only for a list that never reorders, inserts or removes, which is rarer than
  it looks;
- **the item itself**, `track course`, works when the same objects stay in the list, and fails as soon
  as the list is rebuilt from a server answer, because every object is new and nothing is recognised.

The code written before `@for` used `*ngFor`, where tracking was optional and usually missing. Without
it, every item is recognised by its object, and a list reloaded from the server is drawn again from
nothing. The last section of this lesson meets that code.
