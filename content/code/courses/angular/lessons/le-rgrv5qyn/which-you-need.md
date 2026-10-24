---
title: Which of them you need
version: 1
---

**With signals, a new component needs almost none of the hooks.** The question each hook answered has a
better answer now, and the hooks remain for the code written before that answer existed:

| the job | in new code | in the code you will read |
|---|---|---|
| set things up | field initialisers and the constructor, with `inject()` | `ngOnInit` |
| read an input | read it where it is needed; a `computed` waits for it | `ngOnInit`, because the constructor was too early |
| react to an input changing | a `computed`, or an `effect` for the outside world | `ngOnChanges` and a copied field |
| clean up | `inject(DestroyRef).onDestroy(…)` beside what it cleans | `ngOnDestroy`, far from the setup |
| touch the drawn DOM | `afterNextRender`, `afterEveryRender` | `ngAfterViewInit`, `ngAfterViewChecked` |
| check something on every check | nothing: a signal says when it changed | `ngDoCheck` |
| use projected content | `contentChild()`, a signal | `ngAfterContentInit` |

The planner, at the end of this lesson, has no hook at all, and nothing it does needs one. The bench
has taught what it came to; delete it, and put `App` back:

```
ana@dev:~/planner$ rm -r src/app/bench
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ git status --short
```

Nothing to commit: the bench came and went, and the planner is as lesson 8 left it.
