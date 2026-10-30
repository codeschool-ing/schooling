---
title: Composing directives onto a component
version: 1
---

**`hostDirectives` puts directives on a component's own element, from inside the component.** A
component that always wants a behaviour can carry it, instead of every template that uses the
component having to remember an attribute. The directive's inputs are not exposed unless they are
listed, so the component decides what its users may set.

```typescript
@Component({
  selector: 'app-card',
  hostDirectives: [{ directive: Highlight, inputs: ['appHighlight'] }],
  template: '<ng-content />',
})
export class Card {}
```

```html
<app-card appHighlight="khaki">Highlighted, with no directive written here.</app-card>
```

Every `<app-card>` now highlights on hover and focus, and `appHighlight` sets its colour. Angular's own
libraries use this to build components out of small behaviours, and lesson 21's CDK has many of them
to compose.

| a directive is | when |
|---|---|
| an attribute directive | a behaviour or look added to an existing element: focus, highlight, a host attribute |
| a structural directive | a template drawn conditionally or repeatedly, where `@if` and `@for` do not fit |
| in `hostDirectives` | a behaviour every instance of one component should have |
| a component | there is something new to draw |

The bench goes, and the two directives the planner uses stay:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M src/app/add-session/add-session.ts
?? src/app/aria-invalid.ts
?? src/app/autofocus.spec.ts
?? src/app/autofocus.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Directives: focus on arrival, and aria-invalid on every field"
```
