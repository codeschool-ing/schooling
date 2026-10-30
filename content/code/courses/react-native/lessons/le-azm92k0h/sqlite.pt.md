---
title: Um diário em SQLite
version: 1
---

**As sessões do planner moram no servidor; o que este celular fez com elas pode morar no celular.** O
diário é um registro de toda sessão marcada como feita aqui, com o horário, guardado mesmo quando o plano
do servidor muda. A pergunta feita a ele é uma consulta: *quantos minutos registrei por curso?* Isso é
trabalho do SQLite. Instale-o:

```
ana@dev:~/planner$ npx expo install expo-sqlite
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 1 SDK 58.0.0 compatible native module using npm
> npm install

added 2 packages, and audited 1122 packages in 4s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
› Added config plugin: expo-sqlite
```

O `expo install` também acrescentou o `expo-sqlite` aos plugins do `app.json`; ele tem código nativo,
então um development build precisa ser reconstruído para carregá-lo.

## O schema e as consultas

Tudo o que o diário sabe de SQL está num arquivo. Salve o `src/journal.ts`:

```ts
// src/journal.ts: a log, kept on this phone, of every session marked done here, and what it adds up to.
// It asks for three methods and no more, so a test can hand it any SQLite that has them.
export interface Sql {
  execAsync(source: string): Promise<void>;
  runAsync(source: string, ...params: (string | number)[]): Promise<unknown>;
  getAllAsync<T>(source: string, ...params: (string | number)[]): Promise<T[]>;
}

// Each entry moves the database one version on. Entries are only ever added at the end.
const MIGRATIONS = [
  "CREATE TABLE done (session TEXT PRIMARY KEY, course TEXT NOT NULL, minutes INTEGER NOT NULL, done_at TEXT NOT NULL)",
];

export async function migrate(db: Sql) {
  const [{ user_version: from }] = await db.getAllAsync<{ user_version: number }>("PRAGMA user_version");
  for (let v = from; v < MIGRATIONS.length; v++) {
    await db.execAsync(`BEGIN; ${MIGRATIONS[v]}; PRAGMA user_version = ${v + 1}; COMMIT;`);
  }
}

export type Done = { id: string; course: string; minutes: number };

export async function record(db: Sql, s: Done, at: string) {
  await db.runAsync(
    "INSERT OR IGNORE INTO done (session, course, minutes, done_at) VALUES (?, ?, ?, ?)",
    s.id, s.course, s.minutes, at,
  );
}

export function totals(db: Sql) {
  return db.getAllAsync<{ course: string; minutes: number }>(
    "SELECT course, sum(minutes) AS minutes FROM done GROUP BY course ORDER BY course",
  );
}
```

**O `Sql` são três métodos, os que o diário usa, e não o tipo inteiro do expo-sqlite.** O banco que o
`expo-sqlite` abre tem os três, então encaixa; e qualquer outro SQLite que os tenha também, que é o que o
teste da próxima seção usa.

- **O `migrate` leva o banco à versão mais nova.** O SQLite guarda um número em todo arquivo de banco, o
  `PRAGMA user_version`, que começa em 0 e quer dizer o que o app decidir. Aqui é quantas entradas de
  `MIGRATIONS` já rodaram. Um celular novo começa em 0 e roda todas; um atualizado roda só o que é novo.
  Cada uma roda numa transação junto com a mudança de versão, então uma migração que falha no meio deixa a
  versão antiga e o schema antigo, nunca uma mistura.
- **O `record` escreve uma linha.** Os `?` são preenchidos pelo SQLite com os valores depois da consulta,
  nunca colados no texto, então um curso chamado `x'); DROP TABLE done; --` é só um nome estranho. O
  `INSERT OR IGNORE` com a sessão como chave primária faz um segundo registro da mesma sessão não fazer
  nada: uma nova tentativa não a conta duas vezes.
- **O `totals` soma por curso**, numa consulta, que é o que um chave-valor não consegue.

## Ligando tudo

O banco é aberto uma vez, na raiz, pelo `SQLiteProvider`, que roda o `migrate` antes de qualquer coisa
abaixo dele renderizar. No `App.tsx` ele vai dentro do provider de consultas:

```tsx
// App.tsx: the planner's root: gestures, safe areas, the query client and its stored copy, the journal's
// database, and the plan once it has arrived.
import { NavigationContainer } from "@react-navigation/native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { createAsyncStoragePersister } from "@tanstack/query-async-storage-persister";
import { QueryClient } from "@tanstack/react-query";
import { PersistQueryClientProvider } from "@tanstack/react-query-persist-client";
import { SQLiteProvider } from "expo-sqlite";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { Pressable, Text, View } from "react-native";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { migrate } from "./src/journal";
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

O `src/planState.tsx` registra uma sessão quando o servidor a confirma, e oferece os totais como uma
consulta, para a tela renderizar de novo quando o diário cresce:

```tsx
// src/planState.tsx: the plan comes from the server through TanStack Query; every change is an action,
// and every session the server agrees is done goes into the journal on this phone.
import { onlineManager, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import NetInfo from "@react-native-community/netinfo";
import { useSQLiteContext } from "expo-sqlite";
import { createSession, fetchPlan, sendDone, type NewSession } from "./api";
import { record, totals } from "./journal";
import { addSession, markDone, type Plan } from "./planner";

export type Action =
  | { type: "done"; id: string }
  | { type: "add"; course: string; date: string; minutes: number };

export function planReducer(plan: Plan, action: Action): Plan {
  switch (action.type) {
    case "done":
      return markDone(plan, action.id);
    case "add":
      return addSession(plan, action.course, action.date, action.minutes);
  }
}

// TanStack Query pauses requests while offline; on a phone, NetInfo is what knows.
onlineManager.setEventListener((setOnline) => NetInfo.addEventListener((s) => setOnline(!!s.isConnected)));

export function usePlanQuery() {
  return useQuery({ queryKey: ["plan"], queryFn: fetchPlan, staleTime: 30_000 });
}

function useMarkDone() {
  const client = useQueryClient();
  const db = useSQLiteContext();
  return useMutation({
    mutationFn: sendDone,
    onMutate: async (id: string) => {
      await client.cancelQueries({ queryKey: ["plan"] });
      const before = client.getQueryData<Plan>(["plan"]);
      client.setQueryData<Plan>(["plan"], (p) => p && planReducer(p, { type: "done", id }));
      return { before };
    },
    onError: (_error, _id, context) => client.setQueryData(["plan"], context?.before),
    // only once the server has agreed, so the journal never logs a session that was rolled back
    onSuccess: async (session) => {
      await record(db, session, new Date().toISOString());
      await client.invalidateQueries({ queryKey: ["journal"] });
    },
    onSettled: () => client.invalidateQueries({ queryKey: ["plan"] }),
  });
}

// What the journal adds up to, through the same cache as the plan, so a screen re-renders when it grows.
export function useJournal() {
  const db = useSQLiteContext();
  return useQuery({ queryKey: ["journal"], queryFn: () => totals(db), networkMode: "always" });
}

// Adding waits for the server, which gives the session its id; then the plan is fetched again.
export function useAddSession() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (s: NewSession) => createSession(s),
    onSuccess: () => client.invalidateQueries({ queryKey: ["plan"] }),
  });
}

// The screens' view of all this is the same as in lesson 9.
export function usePlan() {
  const { data } = usePlanQuery();
  const markDone = useMarkDone();
  if (!data) throw new Error("usePlan must be used once the plan has loaded");
  const dispatch = (action: Action) => {
    if (action.type === "done") markDone.mutate(action.id);
  };
  return { plan: data, dispatch, error: markDone.error };
}
```

**`onSuccess`, não `onMutate`.** A atualização otimista da aula 10 mostra a sessão feita antes de o servidor
responder e a desfaz se ele recusar. O diário é um registro, e o registro de algo que foi desfeito seria
falso, então ele espera o sim do servidor. O `networkMode: "always"` diz ao TanStack Query que esta
consulta lê o celular, não a rede, então ela roda offline também.

E o `src/WeekScreen.tsx` mostra os totais acima da semana:

```tsx
// src/WeekScreen.tsx: every session of this week, whatever its course; any can be marked done, and what
// this phone has logged sits above them.
import { StyleSheet, Text, View } from "react-native";
import { useJournal, usePlan } from "./planState";
import { mondayOf } from "./planner";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";
import { today } from "./today";

export function WeekScreen() {
  const { plan, dispatch } = usePlan();
  const t = useTheme();
  const monday = mondayOf(today());
  const week = plan.sessions.filter((s) => mondayOf(s.date) === monday);
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <Logged />
      <SessionList sessions={week} onDone={(id) => dispatch({ type: "done", id })} />
    </View>
  );
}

// What this phone has logged, from the journal: it survives a restart, and it is this phone's alone.
function Logged() {
  const { plan } = usePlan();
  const t = useTheme();
  const { data } = useJournal();
  if (!data) return null;
  const name = (id: string) => plan.courses.find((c) => c.id === id)?.name ?? id;
  const text = data.length
    ? "Logged on this phone: " + data.map((r) => `${name(r.course)} ${r.minutes} min`).join(", ")
    : "Nothing logged on this phone yet";
  return <Text style={[styles.logged, { color: t.muted }]}>{text}</Text>;
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  logged: { marginTop: 16, fontSize: 15 },
});
```
