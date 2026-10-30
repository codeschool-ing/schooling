---
title: Where inject() may be called
version: 1
---

**`inject()` works only while Angular is building something: in a constructor, in a field's
initialiser, and in a factory.** That window is the **injection context**. Angular knows which
injector to ask because it is the one doing the building at that moment; once the constructor has
returned, there is no current injector, and `inject()` has nobody to ask.

A method runs later, when somebody clicks, so a method that calls `inject()` fails:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Tally {
  readonly count = signal(0);
}

@Component({
  selector: 'app-bench',
  template: '<button type="button" (click)="report()">Report</button>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected report(): void {
    console.log('count', inject(Tally).count());
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Report' | grep -v '^    at '
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Report
[error] ERROR RuntimeError: NG0203: The `_Tally` token injection failed. `inject()` function must be called from an injection context such as a constructor, a factory function, a field initializer, or a function used with `runInInjectionContext`. Find more at https://v21.angular.dev/errors/NG0203
Report
```

`NG0203` lists the places that work. The fix is to ask while the bench is being built, in a field,
and use the answer later:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Tally {
  readonly count = signal(0);
}

@Component({
  selector: 'app-bench',
  template: '<button type="button" (click)="report()">Report</button>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly tally = inject(Tally);

  protected report(): void {
    console.log('count', this.tally.count());
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Report'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Report
count 0
Report
```

## A function that injects

The rule is about **when** `inject()` runs, not where it is written. A plain function may call it,
as long as the function itself is called from a field or a constructor:

```typescript
function injectWeek(): WeekRange {
  return weekOf(isoDay(inject(TODAY)));
}

export class Week {
  protected readonly week = injectWeek();
}
```

Such a function is usually named `injectSomething`, so whoever calls it knows it belongs in a field
or a constructor, where `inject` works. For the rare case of a callback that genuinely has to inject later,
`runInInjectionContext(injector, fn)` runs `fn` with a given injector as the current one; reach
for it only after a field has been ruled out.

## Putting the planner back

The bench has done its job. It goes, and `App` goes back to what git has:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M src/app/week/week.html
 M src/app/week/week.spec.ts
 M src/app/week/week.ts
?? src/app/today.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Dependency injection: today is a token"
```

What stays is the token, `Week` asking for it, the range it shows, and a test that names its own
day.
