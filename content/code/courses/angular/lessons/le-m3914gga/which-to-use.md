---
title: Signals in a service, NgRx, or NgRx's SignalStore
version: 1
---

**Start with a service of signals, and move to a library when the application, or the team, has
outgrown what one person can hold in their head.** The planner never will. Many company applications
did, years ago, and you will meet NgRx in them.

| | a service of signals | NgRx Store | NgRx SignalStore |
|---|---|---|---|
| the state | private signals in a service | one object for the whole application | signals, built by a function from features |
| changing it | a method | dispatching an action to a reducer | a method, declared with `withMethods` |
| reading it | `computed` | selectors | `computed`, declared with `withComputed` |
| what it adds | nothing to install | a log of every change, devtools, one shape for every feature | conventions and reusable features, with less ceremony than Store |
| what it costs | discipline the team keeps by itself | actions, reducers and selectors for every change, and a package | a package, and its way of doing things |

**NgRx SignalStore**, in `@ngrx/signals`, is the newer of NgRx's two libraries: a store made of signals,
built by a function from parts such as `withState` and `withMethods`, much closer to what the planner
already does. Code written since signals arrived often uses it where earlier code used Store.

Whichever is used, lesson 11's questions decide where a piece of state goes: is it a fact more than one
screen reads, or one screen's own business? A library changes how the answer is written down, not
what the answer is.

```
ana@dev:~/planner$ git status --short
 M src/app/course-sessions/course-sessions.ts
?? src/app/preferences.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "State: a preference store that lasts between visits"
```
