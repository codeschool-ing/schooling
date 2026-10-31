---
title: O plano, guardado para a próxima abertura
version: 1
---

**O TanStack Query já guarda o plano na memória; ele também consegue anotar essa memória.** Um *persister*
salva o cache de consultas num armazenamento depois que ele muda e o devolve quando o app abre, então a
primeira tela desenha o plano de ontem na hora e o pedido pelo de hoje roda por trás. Num trem sem sinal,
o plano de ontem é muito melhor que um indicador girando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l14-restore\" aria-label=\"Na abertura o persister lê o cache guardado no AsyncStorage e devolve o plano ao cache de consultas, e a tela o desenha na hora. Depois a consulta busca o plano no servidor. Se o servidor responde, o plano novo substitui o guardado na tela e é escrito no AsyncStorage de novo. Se não responde, o plano guardado fica na tela.\"><defs><marker id=\"l14-restore-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o app abre</text><rect x=\"170\" y=\"40\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"255.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o plano guardado volta</text><rect x=\"370\" y=\"40\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a tela o desenha na hora</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o plano é pedido</text><path d=\"M140 58 L170 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><path d=\"M340 58 L370 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><path d=\"M530 58 L560 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><rect x=\"185\" y=\"130\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"255.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AsyncStorage</text><path d=\"M255 130 L255 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><rect x=\"400\" y=\"150\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resposta: plano novo na tela,</text><text x=\"475.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e guardado de novo</text><rect x=\"570\" y=\"150\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"640.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sem resposta: o plano</text><text x=\"640.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guardado fica na tela</text><path d=\"M600 76 L480 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><path d=\"M650 76 L640 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path><path d=\"M400 172 L325 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-restore-ah-paper-dim)\"></path></svg>", "caption": "Restaurar primeiro e buscar depois é o que torna a primeira tela instantânea, com rede ou sem."}
```

O AsyncStorage é o lugar para isso: o cache é uma string, escrita de vez em quando e lida uma vez. Instale
ele, e os dois pacotes do TanStack que ligam os dois:

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

O `npx expo install` escolhe o AsyncStorage que o SDK 58 espera. Os pacotes do TanStack são da mesma
versão do `@tanstack/react-query` que a aula 10 instalou, com a qual precisam combinar. Depois o
`App.tsx`:

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

**O `PersistQueryClientProvider` toma o lugar do `QueryClientProvider`**, com o mesmo cliente e um
persister. Três números e uma string decidem o que é guardado:

- **O `gcTime`, no cliente, é quanto tempo uma consulta que nenhuma tela está usando fica na memória**. O
  padrão é cinco minutos; o persister só consegue salvar o que ainda está na memória, então ele sobe para
  um dia.
- **O `maxAge` é a idade máxima de uma cópia guardada** antes de ser jogada fora em vez de mostrada. Um dia
  aqui: um plano da semana passada seria pior que um *carregando* honesto.
- **O `buster` é uma versão para o formato guardado.** Mude os campos do plano numa versão futura e uma
  cópia guardada pela antiga seria lida como nova; mudar o `buster` invalida toda cópia antiga.
- **O `shouldDehydrateQuery` escolhe o que é salvo**, e aqui é só o plano. O que mais o cache guardar
  depois fica na memória.

Os testes que renderizam o `App` agora passam pelo AsyncStorage, que é código nativo. A biblioteca traz um
substituto para o Jest que guarda tudo num objeto JavaScript, e o `jest.setup.ts` o ganha:

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

**Os 43 testes passam com o provider trocado**, que é o motivo de mantê-lo na raiz: nenhuma tela sabe que
o cache é guardado.
