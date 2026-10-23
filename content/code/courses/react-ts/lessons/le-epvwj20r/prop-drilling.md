---
title: Passing props through components that do not use them
version: 1
---

**Props travel one level at a time.** When a value is needed three components down, every component
in between has to receive it and pass it on, whether it uses it or not. That is called **prop
drilling**, and the planner already does a little of it. `toggleDone` is created in `usePlanner`,
returned to `App`, passed to `CourseScreen` as `onToggle`, and only there used by a checkbox. `onOpen`
goes from `App` through `CourseList`, which never calls it, to `CourseCard`, which does.

```schooling-figure
{"svg": "<svg data-fig=\"drilling\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The planner's tree before this lesson. toggleDone travels from usePlanner to App and from App to CourseScreen as onToggle, where a checkbox uses it. onOpen travels from App through CourseList, which does not use it, to CourseCard, which does. The components that only pass a prop on are marked.\"><rect x=\"290\" y=\"14\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">App</text><rect x=\"90\" y=\"90\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseScreen</text><rect x=\"460\" y=\"90\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"545.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseList</text><rect x=\"90\" y=\"170\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;input checkbox&gt;</text><rect x=\"460\" y=\"170\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseCard</text><line x1=\"330\" y1=\"44\" x2=\"175\" y2=\"90\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"175.0,90.0 181.3,84.8 183.1,90.9\" fill=\"var(--phosphor)\"></polygon><text x=\"200\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">onToggle</text><line x1=\"175\" y1=\"120\" x2=\"175\" y2=\"170\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"175.0,170.0 171.8,162.5 178.2,162.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"390\" y1=\"44\" x2=\"545\" y2=\"90\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,90.0 536.9,90.9 538.7,84.8\" fill=\"var(--amber)\"></polygon><text x=\"520\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">onOpen</text><line x1=\"545\" y1=\"120\" x2=\"545\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,170.0 541.8,162.5 548.2,162.5\" fill=\"var(--amber)\"></polygon><text x=\"640\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">only passes it on</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">solid: uses the prop · dashed: only hands it down</text></svg>", "caption": "Prop drilling: a value passed through components that only hand it on."}
```

**Two levels of drilling is not a problem**, and the honest first lesson about global state is that
most apps reach for it too early. Props are explicit: reading `CourseList`'s props tells you every
value it depends on, and the type checker follows each one. The cost appears at a different scale:
when a value is read by many components at different depths, when the components in between change
often, or when the same few values, the signed-in user, the theme, the planner's data, are passed down
almost every branch of the tree. Then every intermediate component carries props that are not its
business, and moving a component means rewiring its ancestors.

The planner is heading there. Lesson 17 gives each screen its own address, so the course screen will
no longer be rendered by `App` with its data in hand; it will be rendered by a router, and it will
need the sessions and `toggleDone` from somewhere else. That somewhere is what this lesson builds,
first with React's own tool, context, and then with the three libraries most React teams choose
between.

| keep props when | reach for shared state when |
|---|---|
| a value passes through one or two components | many components at different depths read the same value |
| the components in between are stable | the tree in between changes, or the reader moves |
| you want each component's dependencies visible in its props | the value is app-wide: the user, the theme, the app's data |
