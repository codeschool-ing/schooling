---
title: One element, four frameworks
version: 1
---

**An element registered with the browser can be written by anything that writes HTML.** That was the
reason for building one. This section releases it in the library, then shows the same row used from
React, Angular, Vue and Svelte.

## Released with the library

The element is exported beside the function components, so a consumer imports the class and the
function that registers it from the same package:

```
ana@dev:~/planner-ui$ echo 'export { PlannerSession, definePlannerSession } from "./session-element";' >> src/index.ts
ana@dev:~/planner-ui$ npx tsc && echo types ok
types ok
```

The changelog gets its entry before the version moves:

```
<!-- CHANGELOG.md -->
# Changelog

## 0.3.0

- Added `<planner-session>`, a Web Component for a session row, registered by `definePlannerSession()`.

## 0.2.0

- Added `progressBar`, which shows minutes done out of minutes planned.

## 0.1.0

- First release: the tokens, the type and spacing scales, two themes, `actionButton`, `sessionRow` and
  `weekSummary`.
```

Then the release from lesson 7, a minor version because nothing that worked before has changed:

```
ana@dev:~/planner-ui$ git add -A && git commit -qm "Export <planner-session>"
ana@dev:~/planner-ui$ npm version minor
v0.3.0
ana@dev:~/planner-ui$ git log --oneline --decorate -3
e197621 (HEAD -> main, tag: v0.3.0) 0.3.0
4bd022f Export <planner-session>
c68c1b3 Add <planner-session>, its demo page and its tests
ana@dev:~/planner-ui$ npm run build > /dev/null && npm publish 2>&1 | tail -1
+ @planner/ui@0.3.0
```

A page uses it in two lines and a tag:

```typescript
import { definePlannerSession } from "@planner/ui";
definePlannerSession();
```

The registration is a call rather than something the import does by itself, so a page decides when the
tag starts working, and an app that only uses the function components does not register an element
nobody writes.

## The same row, four ways

**None of the four was run for this course**: each would be a project of its own, with its own version to
pin. What is shown is the shape each one's documentation gives for using a custom element in October 2026.
All four have three things to say: that the tag is not one of theirs, how the attributes are passed, and
how the event is heard.

### React

React 19 passes props to a custom element as attributes or properties, and a prop that starts with `on`
becomes a listener for the event named by the rest. TypeScript has to be told the tag exists:

```tsx
// declare the tag once, for TypeScript
declare module "react" {
  namespace JSX {
    interface IntrinsicElements {
      "planner-session": React.HTMLAttributes<HTMLElement> & { date: string; minutes: number };
    }
  }
}

<planner-session id="session-6" date="2026-10-15" minutes={45} onsession-done={() => setDone(true)}>
  JavaScript
</planner-session>
```

React 18 and earlier set everything as attributes and do not listen for custom events: a listener goes on
through a `ref` and `addEventListener`.

### Angular

Angular refuses an element it does not know unless the component says custom elements are allowed:

```typescript
@Component({
  selector: "app-session",
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  template: `
    <planner-session id="session-6" [attr.date]="date" [attr.minutes]="minutes" (session-done)="done = true">
      JavaScript
    </planner-session>
  `,
})
export class SessionComponent {
  date = "2026-10-15";
  minutes = 45;
  done = false;
}
```

`[attr.date]` sets the attribute; a plain `[date]` would set a property, which this element does not have.
`(session-done)` listens for the event by its name.

### Vue

Vue tries to resolve every tag as one of its own components unless its compiler is told otherwise, in the
Vite plugin's options:

```typescript
// vite.config.ts
vue({ template: { compilerOptions: { isCustomElement: (tag) => tag.startsWith("planner-") } } })
```

```html
<planner-session id="session-6" :date="date" :minutes="minutes" @session-done="done = true">
  JavaScript
</planner-session>
```

Vue sets a bound value as a property when the element has one with that name, and as an attribute
otherwise, so `:minutes` becomes the attribute here.

### Svelte

Svelte needs no setting: a tag with a hyphen is a custom element to it. In Svelte 5 an attribute that
starts with `on` is a listener, so the event is heard the way `onclick` is:

```html
<planner-session id="session-6" {date} {minutes} onsession-done={() => (done = true)}>
  JavaScript
</planner-session>
```

Like Vue, Svelte sets a property when the element has one and an attribute otherwise.

## What the four agree on

Each of them writes the tag, passes the attributes and hears `session-done`, and none of them needs the
library to know which framework is on the other side. The differences are all on the framework's side,
in one setting or one declaration each, and they are the price of a component written once.
