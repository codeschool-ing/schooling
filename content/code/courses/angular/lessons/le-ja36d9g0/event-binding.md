---
title: Events, and the value that came with them
version: 1
---

**`(event)="statement"` runs the statement every time the element fires that event.** Parentheses
for events, square brackets for properties: data goes out of the class into the DOM through
brackets, and comes back into the class through parentheses. The bench gets buttons and a field that
reports what was typed:

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-bench',
  imports: [],
  templateUrl: './bench.html',
  styleUrl: './bench.css',
})
export class Bench {
  protected minutes = 45;
  protected saved = 'nothing yet';

  protected add(m: number): void {
    this.minutes = Math.min(this.minutes + m, 240);
  }

  protected typed(event: Event): void {
    this.minutes = (event.target as HTMLInputElement).valueAsNumber || 0;
  }
}
```

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p>{{ minutes }} minutes</p>
<button type="button" (click)="add(15)">Add 15</button>
<button type="button" (click)="minutes = 0">Clear</button>

<label for="bench-minutes">Minutes</label>
<input id="bench-minutes" type="number" [value]="minutes" (input)="typed($event)" />

<label for="bench-note">Note</label>
<input id="bench-note" #note (keydown.enter)="saved = note.value" />
<p>Saved: {{ saved }}</p>
```

`look --do` performs actions in order, and prints each one before it does it. Click the first button
twice, type a number into the field, then type a note and press Enter:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Add 15' --do 'click Add 15' --do 'fill Minutes = 100' --do 'fill Note = revise the router' --do 'press Enter'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add 15
-- click Add 15
-- fill Minutes = 100
-- fill Note = revise the router
-- press Enter
Bench

100 minutes

Add 15ClearMinutesNote

Saved: revise the router
```

Three forms of the same idea:

- **`(click)="add(15)"`** calls a method with an argument. The method changes a field, and Angular
  draws the template again after the event, so `75` appeared without anybody asking.
- **`(click)="minutes = 0"`** is a statement written in place: an event binding is the one place a
  template may assign. Keep these to one short line; anything longer belongs in a method, where it can
  be read and tested.
- **`(input)="typed($event)"`** passes the event itself. `$event` is the DOM's own `Event`, and the
  method reads the field's value from its `target`. The `as HTMLInputElement` tells TypeScript what
  kind of element fired it, because `Event` alone does not say.

## A reference to an element

`#note` gives the second field a name that the rest of the template can use: a **template reference
variable**. `note.value` reads the field directly, with no field in the class and no `$event`.
`(keydown.enter)` is a key event with the key named in the binding, so the statement runs on Enter and
on no other key. A reference is the right tool when the value is only needed at the moment of the
event; when the class needs it all the time, bind it, as lesson 16's forms do.

**Every control here is a `<button>` or a labelled `<input>`.** That is not decoration: `look` found
them by their names, `Add 15` and `Minutes`, exactly as a screen reader does, and a `<div>` with a
`(click)` would have been found by neither. A clickable `<div>` also cannot be reached with Tab or
pressed with Enter. If it does something when clicked, it is a button, and the element should say so.
