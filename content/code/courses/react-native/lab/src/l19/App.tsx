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
