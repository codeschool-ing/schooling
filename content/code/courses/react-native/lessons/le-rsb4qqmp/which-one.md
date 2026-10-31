---
title: Where a piece of state should live
version: 1
---

**Put state as close as possible to where it is used, and no closer than everybody who needs it.** The
planner now has all three levels, and each piece of its state is where it is for a reason.

| state | where it lives | why |
|---|---|---|
| whether a row is pressed | inside `Pressable` | nobody else cares |
| the text being typed in a field (lesson 11) | `useState` in the form | only the form reads it until it is saved |
| the plan | a context at the root | every screen reads it, and two change it |
| which screen is open, and its params | the navigation state | React Navigation owns it, and the address follows it |
| data from a server (lesson 10) | TanStack Query's cache | it has its own rules about freshness |
| thousands of items read row by row | a store with selectors | a context would redraw every row |

## Two mistakes worth recognising

**Copying props into state.** `const [name, setName] = useState(props.course.name)` takes the name once,
on the first render, and ignores every later change. Use the prop, or, if the component must edit a
draft, key the component by the course's id so that a different course starts a new draft.

**Keeping a value that can be computed.** The week's total is never stored: it is computed from the plan
on each render, so it cannot disagree with it. State that duplicates other state is two places to update
and one more way to be wrong.

## The rule behind all of it

**One owner for each fact.** The plan has one owner, the provider, and one way to change it, an action.
Screens read it and ask for changes; none of them keeps a copy. That is the same discipline the planner's
data follows when a session names its course by id, and the reason a press in one tab can be trusted to
show in the other.
