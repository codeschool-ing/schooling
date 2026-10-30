---
title: A service that holds the planner
version: 1
---

**A service is a class an injector makes, holding state or logic that more than one component
needs.** The CLI writes the empty one:

```
ana@dev:~/planner$ npx ng generate service planner-store
CREATE src/app/planner-store.spec.ts (352 bytes)
CREATE src/app/planner-store.ts (117 bytes)
```

```typescript
// src/app/planner-store.ts
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class PlannerStore {}
```

There is no `Service` at the end of the name, as there is in most Angular code you will read: since
Angular 20 the CLI no longer adds the suffix, and the name says what the class is for instead.
`PlannerStore` because it stores the planner; the test file beside it, `planner-store.spec.ts`,
injects one and checks that it exists.

## What goes in it

The resource moves out of the components and into the store, and the store decides what the rest of
the application may see of it:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "import { Injectable, computed, resource } from '@angular/core';\nimport { loadPlanner } from './planner';\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly data = resource({ loader: loadPlanner });", "note": "The one `resource` in the application. It is `private`: no component reaches it."},
 {"code": "  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;", "note": "The resource's own signals, handed on as they are."},
 {"code": "  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));", "note": "`hasValue()` first, because `value()` throws while the resource is in its error state. Until the data arrives, both lists are empty."},
 {"code": "  toggle(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}", "note": "The one way to change a session, moved here from `CoursePage`."}
]}
```

`toggle` is the method `CoursePage` had, with the same body. It was only ever about the data, and
the component held it because the component held the data. Now the store holds both.
