---
title: Typed emits
version: 1
---

**`defineEmits` takes a type too: an object type whose keys are the events and whose values are the
lists of arguments each one carries.** `SessionRow`, in the last section, declares one event:

```typescript
const emit = defineEmits<{
  toggle: [id: string]
}>()
```

`[id: string]` is a *tuple*, a fixed list of arguments with names; an event with two would be
`[id: string, done: boolean]`. With it, the checker knows two things it could not know before: what
`emit` may be called with, inside the component, and what a listener will receive, outside it.

## Inside: a misspelt event

Change the row's `emit('toggle', session.id)` to `emit('toggel', session.id)`, as a slip of the fingers
would, and run the checker:

```
ana@dev:~/vue/planner$ sed -i "s/emit('toggle'/emit('toggel'/" src/components/SessionRow.vue
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit

src/components/SessionRow.vue(23,68): error TS2345: Argument of type '"toggel"' is not assignable to parameter of type '"toggle"'.
```

**The checker names the line and the event that does not exist.** Without types, the same slip emits an
event nobody listens to: the box does nothing when ticked, the console says nothing, and the bug is
found by a student. Put it back:

```
ana@dev:~/vue/planner$ sed -i "s/emit('toggel'/emit('toggle'/" src/components/SessionRow.vue
```

## Outside: what the listener receives

In `HomeView`, `@toggle="toggle"` hands the event's argument to the store's `toggle(id: string)`. The
checker compares the two: an event declared as `[id: number]` would fail there, at the listener, with
the event's type and the function's side by side. The contract of lesson 6, props down and events up, is
now written in a language a machine reads as well as a person.

## The runtime half

As with props, Vue keeps a runtime list of the declared events, generated from the type, so lesson 6's
fallthrough rule still knows that `toggle` is the component's own event and not a native one. What the
type cannot keep at run time is the argument check; a runtime validator, lesson 6's object form, is
still the way to have one, and with types it is rarely needed.
