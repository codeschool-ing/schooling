---
title: Context, so every screen reads the same plan
version: 1
---

**A context hands a value to every component below its provider, without passing it through each
level's props.** The second half of `src/planState.tsx` is one: `PlanProvider` keeps the plan with
`useReducer` and puts `{ plan, dispatch }` into `PlanContext`, and `usePlan()` reads it from anywhere
below.

Three details in that half are deliberate:

- **The context starts as `null`**, and `usePlan` throws a sentence when it finds `null`. A component used
  outside the provider, in a test that forgot it for instance, fails with *usePlan must be used inside a
  PlanProvider* instead of reading a plan that is not there.
- **`dispatch` travels with the plan.** A screen that marks a session done calls
  `dispatch({ type: "done", id })`; it never sees `markDone`, and it cannot change the plan any other way.
- **The provider takes the starting plan as a prop**, `initial`, rather than importing the data file. The
  app passes the data; a test passes whatever plan it needs; lesson 14 passes the plan it loaded from
  storage.

## Where the provider goes

High enough that every screen is inside it, which here means around the navigators. Replace `App.tsx`:

```tsx
// App.tsx: the planner's root: safe areas, the shared plan, then navigation.
import { NavigationContainer } from "@react-navigation/native";
import { StatusBar } from "expo-status-bar";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import data from "./src/courses.json";
import { linking, RootNavigator } from "./src/navigation";
import { PlanProvider } from "./src/planState";
import type { Plan } from "./src/planner";

const initial: Plan = data;

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <PlanProvider initial={initial}>
        <NavigationContainer linking={linking}>
          <RootNavigator />
        </NavigationContainer>
      </PlanProvider>
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l09-context\" aria-label=\"The plan's provider at the root of the app, around the navigators. It holds the plan and dispatch. The Courses, This week and Course screens all read it with usePlan. The This week and Course screens send a done action through dispatch; the reducer returns a new plan; every reader renders again.\"><defs><marker id=\"l09-context-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-context-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"200\" y=\"20\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlanProvider: plan + dispatch</text><rect x=\"520\" y=\"20\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planReducer</text><path d=\"M460 40 L520 40\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-context-ah-amber)\" marker-start=\"url(#l09-context-ah-amber)\"></path><rect x=\"60\" y=\"160\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Courses</text><path d=\"M330 60 L140 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-context-ah-paper-dim)\"></path><rect x=\"280\" y=\"160\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">This week</text><path d=\"M330 60 L360 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-context-ah-paper-dim)\"></path><rect x=\"500\" y=\"160\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Course</text><path d=\"M330 60 L580 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-context-ah-paper-dim)\"></path><text x=\"170\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">usePlan()</text><text x=\"560\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">{ type: \"done\", id }</text><path d=\"M580 160 L600 64\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l09-context-ah-amber)\"></path></svg>", "caption": "One plan at the root: screens read it, and change it only by sending an action."}
```

## What context costs

**When the value in a provider changes, every component that reads it renders again**, whichever part of
the value it uses. For the planner that is three screens, and redrawing them on a press costs nothing
anybody could measure. The section on stores counts it, and shows the shape of app where it starts to
matter.
