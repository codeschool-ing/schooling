---
title: Pure pipes, and the array that changed in place
version: 1
---

**A pipe is pure by default: Angular calls `transform` again only when an argument is a different
value from last time.** For a string or a number that means a different value. For an object or an
array it means a different object: the same array with an item pushed onto it is, to Angular, the
same argument, and the pipe's last answer is shown again without asking. That is what makes pure
pipes cheap, and it is the one trap they have.

A bench with a pipe that adds up a list, and logs every time it runs:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "// src/app/bench/bench.ts\nimport { ChangeDetectionStrategy, Component, Pipe, PipeTransform } from '@angular/core';\n\nlet calls = 0;\n\n@Pipe({ name: 'total' })\nexport class TotalPipe implements PipeTransform {\n  transform(values: number[]): number {\n    calls++;\n    console.log(`total ran, call ${calls}`);\n    return values.reduce((sum, value) => sum + value, 0);\n  }\n}", "note": "A pipe can live in the same file as the component that uses it. This one counts its calls."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [TotalPipe],\n  template: `\n    <p>{{ minutes.join(' + ') }} = {{ minutes | total }}</p>\n    <button type=\"button\" (click)=\"push()\">Push 10</button>\n    <button type=\"button\" (click)=\"replace()\">Replace with 10 more</button>\n    <button type=\"button\" (click)=\"nothing()\">Do nothing</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  protected minutes = [30, 60];\n\n  protected push(): void {\n    this.minutes.push(10);\n  }\n\n  protected replace(): void {\n    this.minutes = [...this.minutes, 10];\n  }\n\n  protected nothing(): void {}\n}", "note": "`minutes` is a plain array on purpose. `push` changes it in place; `replace` makes a new one."}
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

```
ana@dev:~/planner$ look http://localhost:4200/ --text 'app-bench p' --do 'click Push 10'
[vite] connecting...
[vite] connected.
total ran, call 1
Angular is running in development mode.
-- click Push 10
30 + 60 + 10 = 90
```

**`30 + 60 + 10 = 90`.** The click ran change detection on the bench, so `join` ran again and shows
three numbers, and the pipe did not, because `minutes` was the same array. The page now contradicts
itself, with no error anywhere.

```
ana@dev:~/planner$ look http://localhost:4200/ --text 'app-bench p' --do 'click Replace with 10 more'
[vite] connecting...
[vite] connected.
total ran, call 1
Angular is running in development mode.
-- click Replace with 10 more
total ran, call 2
30 + 60 + 10 = 100
```

A new array, and the pipe ran again: once for the first drawing, once for the new array. **Give a
pure pipe a new value when the value changes**, which is what the planner has done all along: lesson
6's signals, the store's `update` with a spread, lesson 11's `map` returning new sessions. Code that
mutates in place is the code where pure pipes go stale.
