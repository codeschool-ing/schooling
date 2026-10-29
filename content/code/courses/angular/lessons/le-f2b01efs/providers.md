---
title: Providers, the four recipes
version: 1
---

**A provider is a recipe an injector keeps: when somebody asks for this, give them that.** The
thing asked for is the **token**; what comes back is decided by the recipe. `providedIn: 'root'` is
a recipe written on the class itself, and it is the commonest. The others go in a `providers` list,
and the application has one already, in `app.config.ts`:

```typescript
// src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes)
  ]
};
```

`provideRouter(routes)` is a function that returns providers, several of them, for the router's own
classes, gathered behind one name. Most of Angular's features arrive in an application that
way, `provideHttpClient()` in lesson 12 among them. The list is the root injector's, so anything in
it can be asked for anywhere in the application.

## Swapping the class

A provider written out in full is an object with `provide`, the token, and one of four keys saying
how to answer. `useClass` answers with an instance of a different class. A louder greeter,
added below `Greeter` in the bench:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Greeter {
  greet(name: string): string {
    return `Hello, ${name}`;
  }
}

@Injectable()
export class LoudGreeter extends Greeter {
  override greet(name: string): string {
    return super.greet(name).toUpperCase() + '!';
  }
}

@Component({
  selector: 'app-bench',
  template: '<p>{{ text }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly greeter = inject(Greeter);
  protected readonly text = this.greeter.greet('Ana');
}
```

And the swap, in the application's providers:

```typescript
// src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';
import { Greeter, LoudGreeter } from './bench/bench';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    { provide: Greeter, useClass: LoudGreeter },
  ]
};
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
HELLO, ANA!
```

The bench did not change. It still asks for `Greeter`, and the injector, following the recipe it
was given, answers with a `LoudGreeter`. **A provider in a list wins over `providedIn`**: the
class's own recipe is the default, used only when nothing more specific was written down.

## All four

| key | the injector answers with | typical use |
|---|---|---|
| `useClass` | a new instance of that class, made once | a different implementation of the same contract |
| `useValue` | that value, exactly as written | a constant, a configuration object, a fixed date in a test |
| `useFactory` | whatever the function returns, called once | a value worked out when it is first needed; the function may call `inject()` |
| `useExisting` | what another token already answers | an alias, so two tokens share one instance |

A bare class in the list, `providers: [Greeter]`, is the short form of
`{ provide: Greeter, useClass: Greeter }`. Every recipe makes its answer once per injector, and
hands that one answer to everybody who asks there. The next section uses `useFactory` and `useValue` on something that is not
a class.
