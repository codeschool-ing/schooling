---
title: Choosing, and what none of them is for
version: 1
---

**All four versions of the planner behave identically, and differ in what they ask you to write and
what they make easy.** Here is the code each needed, counted, and the versions each installed:

```
ana@dev:~$ wc -l planner/src/plannerContext.ts planner/src/PlannerProvider.tsx planner-*/src/store.ts planner-*/src/atoms.ts planner-*/src/plannerContext.ts planner-*/src/PlannerProvider.tsx
  14 planner/src/plannerContext.ts
   8 planner/src/PlannerProvider.tsx
  45 planner-redux/src/store.ts
  31 planner-zustand/src/store.ts
  10 planner-jotai/src/atoms.ts
  11 planner-jotai/src/plannerContext.ts
   9 planner-redux/src/plannerContext.ts
  13 planner-zustand/src/plannerContext.ts
  29 planner-jotai/src/PlannerProvider.tsx
  10 planner-redux/src/PlannerProvider.tsx
  10 planner-zustand/src/PlannerProvider.tsx
 190 total
ana@dev:~$ cd planner-zustand && npm ls zustand; cd ../planner-redux && npm ls @reduxjs/toolkit react-redux; cd ../planner-jotai && npm ls jotai
planner@0.0.0 /home/ana/planner-zustand
└── zustand@5.0.16

planner@0.0.0 /home/ana/planner-redux
├─┬ @reduxjs/toolkit@2.13.0
│ └── react-redux@9.3.0 deduped
└── react-redux@9.3.0

planner@0.0.0 /home/ana/planner-jotai
└── jotai@3.0.1
```

| | context | Zustand | Redux Toolkit | Jotai |
|---|---|---|---|---|
| lines for this planner | 22 | 54 | 64 | 50 |
| a provider is needed | yes | no | yes | no, by default |
| a component re-renders when | the context's value changes | its selected slice changes | its selected slice changes | an atom it reads changes |
| the state lives | in a component, `usePlanner` | in a store outside React | in one store outside React | in atoms, in Jotai's store |
| best known for | no dependency at all | small API, little ceremony | conventions, devtools, middleware | fine-grained, independent pieces |

The line counts are from `wc -l` above, with each provider and hook file added to its store; context
needs no store, because its state is still `usePlanner`. They measure ceremony, not quality: Redux's
extra lines buy conventions a team of twenty can follow, and its browser devtools show every action
with the state before and after.

How to choose, for an app you start:

- **Start with props and context.** The planner after this lesson uses context, with no dependency,
  and nothing it does strains it.
- **Add Zustand when context's re-renders start to cost**, or when state needs to be read outside
  components, as in a fetch helper. It is the smallest step up.
- **Use Redux Toolkit where it is already**, and on a large team that wants its conventions. Many React
  codebases that have global state use it.
- **Use Jotai when the shared state is many small, independent values**, such as the open and closed
  state of dozens of panels.

## What none of them is for

**Data that belongs to a server.** The planner's courses and sessions are copies of what the server
holds, and keeping a copy correct means knowing when it went stale, refetching, retrying, and showing
the user what is loading: four jobs none of the libraries above does for you. Lesson 11 moves that data
into React Query, which does exactly those four, and what is left for global state is small: which
week is chosen, which course is open, and in lesson 17 even those move into the address. The three
copies were deleted at the end of the transcript; the planner keeps its context.
