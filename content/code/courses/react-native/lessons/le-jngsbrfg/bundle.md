---
title: What the bundle is made of
version: 1
---

**The bundle's size is what a web page downloads before it can draw anything**, and on a phone it is what
Hermes loads at every start. Lesson 18's source maps say where every byte of it came from, and
`source-map-explorer` reads one and reports bytes per source file. Grouped per package, the list becomes
readable. Save `packages.mjs`:

```javascript
// packages.mjs: add up source-map-explorer's bytes per file into bytes per package, and print the ten
// largest, with the planner's own code as one line of its own.
//
//   npx -y source-map-explorer@2.5.3 BUNDLE BUNDLE.map --no-border-checks --json | node packages.mjs
import { text } from "node:stream/consumers";

const { results } = JSON.parse(await text(process.stdin));
const [{ files, totalBytes }] = results;
const sizes = new Map();
for (const [file, { size }] of Object.entries(files)) {
  const pkg = file.match(/node_modules\/((?:@[^/]+\/)?[^/]+)\/(?!.*node_modules\/)/)?.[1]
    ?? (file.startsWith("/src/") || file.startsWith("/App") ? "(the planner)" : "(other)");
  sizes.set(pkg, (sizes.get(pkg) ?? 0) + size);
}
console.log(`${(totalBytes / 1024).toFixed(0)} KB in all`);
for (const [pkg, size] of [...sizes].sort((a, b) => b[1] - a[1]).slice(0, 10)) {
  console.log(`${(size / 1024).toFixed(0).padStart(5)} KB  ${((100 * size) / totalBytes).toFixed(1).padStart(4)}%  ${pkg}`);
}
```

Export the web build with source maps and measure:

```
ana@dev:~/planner$ f=$(ls dist/_expo/static/js/web/index-*.js); npx -y source-map-explorer@2.5.3 $f $f.map --no-border-checks --json | node packages.mjs
npm warn deprecated rimraf@2.6.3: Rimraf versions prior to v4 are no longer supported
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated glob@7.2.3: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
2068 KB in all
  637 KB  30.8%  react-native-reanimated
  263 KB  12.7%  react-native-gesture-handler
  234 KB  11.3%  react-native-web
  203 KB   9.8%  react-dom
  112 KB   5.4%  (other)
   88 KB   4.3%  @react-navigation/core
   60 KB   2.9%  @tanstack/query-core
   38 KB   1.8%  expo-notifications
   33 KB   1.6%  expo-sqlite
   33 KB   1.6%  @react-navigation/elements
ana@dev:~/planner$ grep -n "require('react-native-reanimated')" node_modules/react-native-gesture-handler/lib/module/handlers/gestures/reanimatedWrapper.js
16:  Reanimated = require('react-native-reanimated');
```

The two `npm warn` lines are npm installing `source-map-explorer` the first time `npx` runs it, and
complaining about two of its old dependencies; they do not touch the planner. **More than two megabytes,
and 43 percent of it is Reanimated and Gesture Handler**: the swipe of lesson 12,
one gesture on one row. React Native Web and React DOM are the cost of running on the web at all, the
navigation is the next, and the planner's own code does not reach the top ten. The `grep` shows why a
`.web.tsx` for the row alone would not be enough: Gesture Handler requires Reanimated itself, so the two
arrive together wherever Gesture Handler is imported, and the app imports it at the root.

**On the web, a mouse does not swipe**: the *Mark done* button beside each row does the same and is how
anybody uses the web build. So the gesture root gets a web version that is a plain `View`. Save
`src/GestureRoot.tsx`:

```tsx
// src/GestureRoot.tsx: the root every gesture needs, on a phone.
export { GestureHandlerRootView as GestureRoot } from "react-native-gesture-handler";
```

and `src/GestureRoot.web.tsx`:

```tsx
// src/GestureRoot.web.tsx: on the web there are no gestures to root, so a plain view, and neither
// Gesture Handler nor the Reanimated it brings with it is in the web bundle.
export { View as GestureRoot } from "react-native";
```

and `App.tsx` uses `GestureRoot` where it used `GestureHandlerRootView`:

```tsx
// App.tsx: the planner's root: gestures, safe areas, the query client and its stored copy, the journal's
// database, and the plan once it has arrived.
import { NavigationContainer } from "@react-navigation/native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { createAsyncStoragePersister } from "@tanstack/query-async-storage-persister";
import { QueryClient } from "@tanstack/react-query";
import { PersistQueryClientProvider } from "@tanstack/react-query-persist-client";
import * as Notifications from "expo-notifications";
import { SQLiteProvider } from "expo-sqlite";
import { StatusBar } from "expo-status-bar";
import { Pressable, Text, View } from "react-native";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { migrate } from "./src/journal";
import { ErrorBoundary } from "./src/ErrorBoundary";
import { GestureRoot } from "./src/GestureRoot";
import { linking, RootNavigator } from "./src/navigation";
import { usePlanQuery } from "./src/planState";

// A reminder that arrives while the planner is open is still shown, as a banner, without a sound.
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: false,
    shouldSetBadge: false,
  }),
});

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
      <ErrorBoundary>
        <NavigationContainer linking={linking}>
          <RootNavigator />
        </NavigationContainer>
      </ErrorBoundary>
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
    <GestureRoot style={{ flex: 1 }}>
      <SafeAreaProvider initialMetrics={initialWindowMetrics}>
        <PersistQueryClientProvider client={client} persistOptions={persistOptions}>
          <SQLiteProvider databaseName="planner.db" onInit={migrate}>
            <Loaded />
          </SQLiteProvider>
        </PersistQueryClientProvider>
        <StatusBar style="auto" />
      </SafeAreaProvider>
    </GestureRoot>
  );
}
```

`SwipeRow.tsx` still imports both libraries, so the web build would still carry them; on the web it needs a
version that renders its children, the same as Jest's stand-in in lesson 12. Save `src/SwipeRow.web.tsx`:

```tsx
// src/SwipeRow.web.tsx: on the web the row does not swipe. A mouse has the button beside it, and the
// swipe's two libraries were nearly half the web bundle (lesson 19 measured it).
import type { ReactNode } from "react";

export function SwipeRow({ children }: { onDone: () => void; children: ReactNode }) {
  return children;
}
```

Measure again:

```
ana@dev:~/planner$ f=$(ls dist/_expo/static/js/web/index-*.js); npx -y source-map-explorer@2.5.3 $f $f.map --no-border-checks --json | node packages.mjs
1093 KB in all
  225 KB  20.6%  react-native-web
  203 KB  18.6%  react-dom
   88 KB   8.1%  @react-navigation/core
   79 KB   7.2%  (other)
   60 KB   5.5%  @tanstack/query-core
   38 KB   3.4%  expo-notifications
   33 KB   3.1%  expo-sqlite
   33 KB   3.0%  @react-navigation/elements
   28 KB   2.6%  @react-navigation/native
   24 KB   2.2%  (the planner)
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest --forceExit 2>&1 | tail -5
Tests:       64 passed, 64 total
Snapshots:   0 total
Time:        9.576 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**From 2068 KB to 1093: the web bundle nearly halved**, and the phone's bundle is untouched, swipe
included, because Metro picks the `.web.tsx` files only for the web. The trade is written down: the web
build has no swipe, and lesson 12's `swipe.mjs` would no longer find one there. What the measurement bought
is knowing exactly what that trade is worth.
