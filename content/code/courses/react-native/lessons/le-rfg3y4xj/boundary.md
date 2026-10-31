---
title: A way out when a screen throws
version: 1
---

**When a component throws while rendering, React unmounts the whole tree above it.** In development that
is LogBox's red screen, which a developer reads. In release there is no LogBox: the app goes blank, and the
person closes it and perhaps never opens it again. An **error boundary** is a component that catches errors
thrown by its children while they render and shows something else in their place. Save
`src/ErrorBoundary.tsx`:

```tsx
// src/ErrorBoundary.tsx: when a screen throws while rendering, show a way out instead of a blank app,
// and say what happened where a developer will see it.
import { Component, type ErrorInfo, type ReactNode } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";

type State = { error: Error | null };

// A class, because only a class component can catch an error thrown by its children while they render.
export class ErrorBoundary extends Component<{ children: ReactNode }, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    // In a release build this is where a crash reporter would be told; here, the log is enough.
    console.error("render failed:", error.message, "\n", error.stack, info.componentStack);
  }

  render() {
    if (!this.state.error) return this.props.children;
    return (
      <View style={styles.screen}>
        <Text role="alert" style={styles.text}>
          Something went wrong on this screen. Your sessions are safe.
        </Text>
        <Pressable role="button" onPress={() => this.setState({ error: null })} hitSlop={8}>
          <Text style={styles.action}>Try again</Text>
        </Pressable>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  screen: { flex: 1, justifyContent: "center", padding: 24, gap: 12 },
  text: { fontSize: 17 },
  action: { fontSize: 16, fontWeight: "600" },
});
```

- **It has to be a class.** Hooks have no way to catch a render error; `getDerivedStateFromError` and
  `componentDidCatch` exist only on class components, and this is the one place React still asks for one.
- **`getDerivedStateFromError` decides what to render**, by putting the error in state.
  **`componentDidCatch` reports it**: here to the log, in a released app to a crash reporter, the last
  section's subject.
- **The message reassures and the button retries.** *Try again* clears the error and renders the children
  again, which is enough when the cause was passing: a plan that arrives complete the second time.

It wraps the navigation in `App.tsx`, inside the providers, so a crash in any screen keeps the query cache,
the journal and the safe areas:

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
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { Pressable, Text, View } from "react-native";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { migrate } from "./src/journal";
import { ErrorBoundary } from "./src/ErrorBoundary";
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
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider initialMetrics={initialWindowMetrics}>
        <PersistQueryClientProvider client={client} persistOptions={persistOptions}>
          <SQLiteProvider databaseName="planner.db" onInit={migrate}>
            <Loaded />
          </SQLiteProvider>
        </PersistQueryClientProvider>
        <StatusBar style="auto" />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

And a test, with a screen that throws until it is told not to. Save `__tests__/ErrorBoundary.test.tsx`:

```tsx
// __tests__/ErrorBoundary.test.tsx: a screen that throws is replaced by a way out, and the way out works.
import { fireEvent, render, screen } from "@testing-library/react-native";
import { Text } from "react-native";
import { ErrorBoundary } from "../src/ErrorBoundary";

let broken = true;
function Screen() {
  if (broken) throw new Error("the plan has no sessions");
  return <Text>The week</Text>;
}

test("a throw becomes a message and a button, and the button tries again", async () => {
  jest.spyOn(console, "error").mockImplementation(() => {}); // React and the boundary both report it
  await render(
    <ErrorBoundary>
      <Screen />
    </ErrorBoundary>,
  );
  expect(screen.getByRole("alert")).toHaveTextContent(/Something went wrong/);
  broken = false;
  await fireEvent.press(screen.getByRole("button", { name: "Try again" }));
  expect(screen.getByText("The week")).toBeOnTheScreen();
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest ErrorBoundary --verbose --forceExit 2>&1 | grep -E "✓|Tests:"
  ✓ a throw becomes a message and a button, and the button tries again (63 ms)
Tests:       1 passed, 1 total
```

`console.error` is silenced inside the test because React reports a caught error too, and the test's
output should show what failed, not what was expected to.
