---
title: When a rune is enough, and when a store is not
version: 1
---

**For state an application owns, a class or an object with runes is now the better tool, and it is what
Svelte's own documentation recommends.** It is plain JavaScript with a few runes in it, it can be
created per use rather than shared by import, it works in `.svelte.js` files and components alike, and
it needs no `$`, no `subscribe`, no `get`. The planner's state is that kind of state, and it moved into a
class.

Stores still earn their place in three situations, and the timer was one of them:

| reach for… | when | because |
|---|---|---|
| runes, in a class or a `.svelte.js` module | state the application owns: the planner's sessions, a form's fields, a selection | it reads as ordinary code, and Svelte tracks it without a subscription |
| `readable` | a value that arrives from outside over time, and should only be listened to while somebody watches | the start and stop functions are exactly that lifecycle |
| the store contract | a library that already offers it, such as an RxJS observable | anything with `subscribe` works with `$`, without an adapter |
| `derived` | a value computed from other stores | it keeps the computation in the store world |

## Moving between the two

The two worlds meet in `svelte/store`. **`fromStore(store)`** gives back an object whose `current` is
the store's value, as reactive as a `$state` field, for using a store from a `.svelte.js` module where
`$` does not exist. **`toStore(get, set)`** wraps runes in a store, for handing your state to code that
expects one. Neither is needed often; both exist so that the choice is never a wall.

## The singleton trap

There is one way a `.svelte.js` module can be worse than a class, and it is the same way a store
module can be. A module that **exports one instance**, `export const planner = new Planner(…)`, gives
every component that imports it the same object, which feels convenient and works in the browser,
where there is one visitor. On the server there is one module for **every** visitor, and an instance
created at module level is shared between all of their requests. The timer's `startedAt` is such a
value: harmless in a demonstration, dangerous for anything that belongs to one person.

That is why `Planner.svelte` creates its own `Planner`, and does not import one. The next lesson shows
the danger happening, and the tool that shares one instance with the components that need it without
making it global: context.

Delete the timer before going on, `rm -r src/routes/timer src/lib/timer.js`: it was an experiment, and
the planner has no use for it.
