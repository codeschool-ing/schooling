---
title: Modules and standalone, in the same application
version: 1
---

**Modules and standalone components work together in both directions, and that is why a migration
can go one file at a time.** The previous section showed one direction, a module importing a
standalone component. This section shows the others, because a real codebase sits in the middle of
the move for a long time.

## A standalone component that imports a module

A library written before standalone ships its pieces as an NgModule. A standalone component puts the
module in its `imports`, and the template may then use everything the module exports:

```typescript
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-note',
  imports: [FormsModule],
  template: '<input [(ngModel)]="text" />',
})
export class Note {
  text = '';
}
```

`FormsModule` exports `ngModel`, which lesson 16 is about, and this is still how it is imported in
Angular 21. Angular's own packages are mostly standalone now, and some of their modules remain as a
convenient bundle of related pieces.

## Providers that came from a module

Modules also carried **providers**, the things a component can ask to be given. `HttpClientModule`
used to make `HttpClient` available; `RouterModule.forRoot(routes)` sets up the router. A standalone
application has no module to import them into, so Angular gave each one a function instead:

| a module-based app imports | a standalone app provides |
|---|---|
| `RouterModule.forRoot(routes)` | `provideRouter(routes)` |
| `HttpClientModule` | `provideHttpClient()` |
| `StoreModule.forRoot(reducers)`, from NgRx (lesson 22) | `provideStore(reducers)` |

For a module with no such function yet, usually from a library, there is
**`importProvidersFrom(SomeModule)`**: it takes the providers out of the module and hands them to the
standalone application. That is the wrapper the migration wrote into `~/legacy`'s `main.ts`, and it
is the bridge every half-migrated application crosses. The tidy version of that file is the shape the
planner's `app.config.ts` already has:

```typescript
bootstrapApplication(App, {
  providers: [provideBrowserGlobalErrorListeners(), provideRouter(routes)],
});
```

`BrowserModule` drops out entirely, because `bootstrapApplication` sets up everything it provided.

## Reading a mixed codebase

Three questions sort out most of the confusion in a codebase half-way through:

1. **Does the component say `standalone: false`, or nothing in a project older than Angular 19?**
   Then its template scope is a module's, and the module that declares it is where to look.
2. **Is the component standalone?** Then its own `imports` is the whole of what its template may use.
3. **Is a provider missing at run time?** Then look for a `provide…()` function, or an
   `importProvidersFrom` around the module that used to provide it.

`~/legacy` has done its job. Delete it, and its 320 MB with it:

```
ana@dev:~$ rm -rf ~/legacy
```
