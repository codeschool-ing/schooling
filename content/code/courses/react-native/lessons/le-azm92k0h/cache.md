---
title: The plan, kept for the next launch
version: 1
---

**TanStack Query already holds the plan in memory; it can also write that memory down.** A *persister*
saves the query cache to a store after it changes and puts it back when the app starts, so the first
screen draws yesterday's plan at once and the request for today's runs behind it. On a train with no
signal, yesterday's plan is far better than a spinner.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l14-restore\" aria-label=\"At launch the persister reads the stored cache from AsyncStorage and puts the plan back into the query cache, so the screen draws it at once. Then the query fetches the plan from the server. If the server answers, the fresh plan replaces the stored one on screen and is written to AsyncStorage again. If it does not, the stored plan stays on screen.\"><defs><marker id=\"l14-restore-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the app starts</text><rect x=\"170\" y=\"40\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"255.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the stored plan is restored</text><rect x=\"370\" y=\"40\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the screen draws it at once</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the plan is requested</text><path d=\"M140 58 L170 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><path d=\"M340 58 L370 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><path d=\"M530 58 L560 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><rect x=\"185\" y=\"130\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"255.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AsyncStorage</text><path d=\"M255 130 L255 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><rect x=\"400\" y=\"150\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">answer: fresh plan shown,</text><text x=\"475.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and stored again</text><rect x=\"570\" y=\"150\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"640.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no answer: the stored</text><text x=\"640.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">plan stays on screen</text><path d=\"M600 76 L480 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><path d=\"M650 76 L640 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><path d=\"M400 172 L325 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path></svg>", "caption": "Restoring first and fetching second is what makes the first screen instant, online or not."}
```

AsyncStorage is the store for it: the cache is one string, written now and then and read once. Install it,
and the two TanStack packages that connect the two:

```
ana@dev:~/planner$ npx expo install @react-native-async-storage/async-storage
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 1 SDK 58.0.0 compatible native module using npm
> npm install

added 3 packages, and audited 1117 packages in 6s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npm install -E @tanstack/query-async-storage-persister@5.105.0 @tanstack/react-query-persist-client@5.105.0

added 3 packages, and audited 1120 packages in 3s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

`npx expo install` picks the AsyncStorage that SDK 58 expects. The TanStack packages are the same release
as the `@tanstack/react-query` lesson 10 installed, which they have to match. Then `App.tsx`:

```tsx
// App.tsx: the planner's root: gestures, safe areas, the query client and its stored copy, and the plan
// once it has arrived.
import { NavigationContainer } from "@react-navigation/native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { createAsyncStoragePersister } from "@tanstack/query-async-storage-persister";
import { QueryClient } from "@tanstack/react-query";
import { PersistQueryClientProvider } from "@tanstack/react-query-persist-client";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { Pressable, Text, View } from "react-native";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { linking, RootNavigator } from "./src/navigation";
import { usePlanQuery } from "./src/planState";

const DAY = 24 * 60 * 60 * 1000;
// A cached plan is kept for a day, in memory and in storage, so the app opens with it even offline.
const client = new QueryClient({ defaultOptions: { queries: { gcTime: DAY } } });
const persister = createAsyncStoragePersister({ storage: AsyncStorage, key: "planner-cache" });
const persistOptions = {
  persister,
  maxAge: DAY,
  buster: "1", // change it when the plan's shape changes, and every stored copy is thrown away
  dehydrateOptions: { shouldDehydrateQuery: (q: { queryKey: readonly unknown[] }) => q.queryKey[0] === "plan" },
};

function Loaded() {
  const { data, error, refetch, isFetching } = usePlanQuery();
  if (data) {
    return (
      <NavigationContainer linking={linking}>
        <RootNavigator />
      </NavigationContainer>
    );
  }
  return (
    <View style={{ flex: 1, justifyContent: "center", padding: 24, gap: 12 }}>
      <Text role="status">{error ? `The plan could not be loaded: ${error.message}` : "Loading the plan"}</Text>
      {error && !isFetching && (
        <Pressable role="button" onPress={() => refetch()}>
          <Text>Try again</Text>
        </Pressable>
      )}
    </View>
  );
}

export default function App() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider initialMetrics={initialWindowMetrics}>
        <PersistQueryClientProvider client={client} persistOptions={persistOptions}>
          <Loaded />
        </PersistQueryClientProvider>
        <StatusBar style="auto" />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

**`PersistQueryClientProvider` takes the place of `QueryClientProvider`**, with the same client and a
persister. Three numbers and a string decide what is kept:

- **`gcTime`, on the client, is how long a query no screen is using stays in memory**. The default is five
  minutes; the persister can only save what is still in memory, so it is raised to a day.
- **`maxAge` is how old a stored copy may be** before it is thrown away instead of shown. A day here: a plan
  from last week would be worse than an honest *loading*.
- **`buster` is a version for the stored shape.** Change the plan's fields in a later release and a copy
  stored by the old one would be read as the new; changing the `buster` makes every old copy invalid.
- **`shouldDehydrateQuery` chooses what is saved**, and here it is only the plan. Whatever else the cache
  holds later stays in memory.

Tests that render `App` now go through AsyncStorage, which is native code. The library ships a stand-in
for Jest that keeps everything in a JavaScript object, and `jest.setup.ts` gains it:

```ts
// jest.setup.ts: runs before every test file.
// The libraries' own stand-ins: there is no native side in Jest to measure or to ask.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
jest.mock("@react-native-community/netinfo", () => require("@react-native-community/netinfo/jest/netinfo-mock.js"));
// Reanimated 4.7 cannot start inside jest-expo 58, not even as its own stand-in, so the one
// component that uses it is replaced by its children. The rule it applies is tested on its own.
jest.mock("./src/SwipeRow", () => ({ SwipeRow: ({ children }: { children: unknown }) => children }));
// AsyncStorage's own stand-in keeps everything in memory, so every test file starts with nothing stored.
jest.mock("@react-native-async-storage/async-storage", () =>
  require("@react-native-async-storage/async-storage/jest/async-storage-mock"),
);
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest --forceExit 2>&1 | tail -5
Tests:       43 passed, 43 total
Snapshots:   0 total
Time:        11.077 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**All 43 tests pass with the provider swapped**, which is the point of keeping it at the root: no screen
knows the cache is stored.
