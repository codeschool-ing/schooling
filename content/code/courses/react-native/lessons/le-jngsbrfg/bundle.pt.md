---
title: Do que o bundle é feito
version: 1
---

**O tamanho do bundle é o que uma página web baixa antes de conseguir desenhar qualquer coisa**, e num
celular é o que o Hermes carrega a cada abertura. Os source maps da aula 18 dizem de onde veio cada byte, e o
`source-map-explorer` lê um e informa os bytes por arquivo de origem. Agrupada por pacote, a lista fica
legível. Salve o `packages.mjs`:

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

Exporte o build web com source maps e meça:

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

As duas linhas `npm warn` são o npm instalando o `source-map-explorer` na primeira vez que o `npx` o roda,
e reclamando de duas dependências antigas dele; elas não tocam no planner. **Mais de dois megabytes, e 43
por cento disso são o Reanimated e o Gesture Handler**: o swipe da aula 12,
um gesto numa linha. O React Native Web e o React DOM são o custo de rodar na web, a navegação vem em
seguida, e o código do próprio planner não entra entre os dez maiores. O `grep` mostra por que um `.web.tsx`
só para a linha não bastaria: o Gesture Handler exige o Reanimated por conta própria, então os dois chegam
juntos onde quer que o Gesture Handler seja importado, e o app o importa na raiz.

**Na web, um mouse não faz swipe**: o botão *Mark done* ao lado de cada linha faz o mesmo e é como qualquer
pessoa usa o build web. Então a raiz de gestos ganha uma versão web que é uma `View` simples. Salve o
`src/GestureRoot.tsx`:

```tsx
// src/GestureRoot.tsx: the root every gesture needs, on a phone.
export { GestureHandlerRootView as GestureRoot } from "react-native-gesture-handler";
```

e o `src/GestureRoot.web.tsx`:

```tsx
// src/GestureRoot.web.tsx: on the web there are no gestures to root, so a plain view, and neither
// Gesture Handler nor the Reanimated it brings with it is in the web bundle.
export { View as GestureRoot } from "react-native";
```

e o `App.tsx` usa o `GestureRoot` onde usava o `GestureHandlerRootView`:

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

O `SwipeRow.tsx` ainda importa as duas bibliotecas, então o build web ainda as levaria; na web ele precisa de
uma versão que renderiza os filhos, igual ao substituto do Jest na aula 12. Salve o `src/SwipeRow.web.tsx`:

```tsx
// src/SwipeRow.web.tsx: on the web the row does not swipe. A mouse has the button beside it, and the
// swipe's two libraries were nearly half the web bundle (lesson 19 measured it).
import type { ReactNode } from "react";

export function SwipeRow({ children }: { onDone: () => void; children: ReactNode }) {
  return children;
}
```

Meça de novo:

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

**De 2068 KB para 1093: o bundle web caiu quase pela metade**, e o bundle do celular fica intocado, swipe
incluído, porque o Metro só escolhe os arquivos `.web.tsx` para a web. A troca fica escrita: o build web não
tem swipe, e o `swipe.mjs` da aula 12 não acharia mais um lá. O que a medição comprou foi saber exatamente
quanto vale essa troca.
