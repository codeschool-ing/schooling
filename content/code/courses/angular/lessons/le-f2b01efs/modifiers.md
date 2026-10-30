---
title: Optional, self, skipSelf and host
version: 1
---

**`inject` takes a second argument that changes how the question travels up the tree.** By default
it starts at the asking component's own injector, goes all the way to the top, and throws `NG0201`
if nothing answers. Four options adjust that, and older code writes each as a decorator on a
constructor parameter, `@Optional()`, `@Self()`, `@SkipSelf()` and `@Host()`:

| option | what it changes |
|---|---|
| `optional: true` | nothing answering gives `null` instead of an error |
| `self: true` | ask only this component's own injector |
| `skipSelf: true` | start one level up, at the parent's injector |
| `host: true` | stop at the component whose template this one sits in |

Two of them are worth seeing together. The counter keeps its own `Tally` and asks for a second one
with `skipSelf`, which skips its own injector, goes to the root, and finds the shared one. And it
asks for a note that nobody provides, with `optional`:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { ChangeDetectionStrategy, Component, Injectable, InjectionToken, inject, input, signal } from '@angular/core';\n\nconst NOTE = new InjectionToken<string>('NOTE');\n\n@Injectable({ providedIn: 'root' })\nexport class Tally {\n  readonly count = signal(0);\n}\n\n@Component({\n  selector: 'app-counter',\n  providers: [Tally],\n  template: `\n    <p>{{ name() }}: {{ own.count() }}, all: {{ shared.count() }}, {{ note }}</p>\n    <button type=\"button\" (click)=\"add()\">Add to {{ name() }}</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Counter {\n  readonly name = input.required<string>();", "note": "A token nobody provides: no `providedIn`, no factory, in no list."},
 {"code": "  protected readonly own = inject(Tally);\n  protected readonly shared = inject(Tally, { skipSelf: true });", "note": "The first `Tally` comes from the counter's own `providers`. The second question skips them and finds the root's."},
 {"code": "  protected readonly note = inject(NOTE, { optional: true }) ?? 'no note';\n\n  protected add(): void {\n    this.own.count.update((c) => c + 1);\n    this.shared.count.update((c) => c + 1);\n  }\n}", "note": "`optional` turns \"nobody provides this\" into `null`, and `??` supplies a default."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Counter],\n  template: '<app-counter name=\"first\" /><app-counter name=\"second\" />',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {}"}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Add to first' --do 'click Add to second'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add to first
-- click Add to second
first: 1, all: 2, no note

Add to first

second: 1, all: 2, no note

Add to second
```

Each counter's own tally counted its own click, and the shared one counted both. The note was
`null`, and the page shows the default.

**`optional` is for a dependency that is genuinely optional**, a feature that may or may not have
been set up. Used to quiet an `NG0201` that should not have happened, it turns a loud error at the
start into a `null` somewhere later, which is a worse place to find out. `self`, `skipSelf` and
`host` matter mostly to directives, lesson 20, that need to find a particular component around
them; in components you will mostly read them.
