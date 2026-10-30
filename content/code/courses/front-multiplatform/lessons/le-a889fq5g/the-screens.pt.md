---
title: As duas telas do planner
version: 1
---

**Duas telas compartilham um plano**, então o plano não pode morar dentro de nenhuma delas. A resposta do
React é um **contexto**: um valor posto acima das telas uma vez, que qualquer tela abaixo consegue ler. O
`src/plan.tsx` guarda o plano em estado e oferece as duas mudanças que as telas fazem, feitas sobre o
`addSession` e o `markDone` do `planner.ts`, sem mudança:

```tsx
// src/plan.tsx: the plan, kept once for every screen of the app.
import { createContext, useContext, useState, type ReactNode } from "react";
import { addSession, markDone, type Plan } from "./planner";
import data from "./courses.json";

type Store = {
  plan: Plan;
  add: (course: string, date: string, minutes: number) => void;
  done: (session: string) => void;
};

const PlanContext = createContext<Store | null>(null);

export function PlanProvider({ children }: { children: ReactNode }) {
  const [plan, setPlan] = useState<Plan>(data);
  const store: Store = {
    plan,
    add: (course, date, minutes) => setPlan(addSession(plan, course, date, minutes)),
    done: (session) => setPlan(markDone(plan, session)),
  };
  return <PlanContext.Provider value={store}>{children}</PlanContext.Provider>;
}

export function usePlan(): Store {
  const store = useContext(PlanContext);
  if (!store) throw new Error("usePlan() outside <PlanProvider>");
  return store;
}

// The transcripts open the web build with ?today=2026-10-21, as lesson 1 does.
const query = typeof location === "undefined" ? "" : location.search;
export const today = new URLSearchParams(query).get("today") ?? new Date().toISOString().slice(0, 10);
```

O `add` chama o `addSession` diretamente, então uma sessão com data ruim lança um erro **antes** de o
estado mudar, e a tela que o chamou pode mostrar o motivo; a tela do curso faz isso abaixo. O layout põe
o plano em volta da pilha, então toda tela fica dentro dele:

```tsx
// app/_layout.tsx: every screen of the app, in one stack, around one plan.
import { Stack } from "expo-router";
import { PlanProvider } from "../src/plan";

export default function Layout() {
  return (
    <PlanProvider>
      <Stack />
    </PlanProvider>
  );
}
```

A primeira tela, a lista de cursos, numa `FlatList`. O `Stack.Screen` define o título da tela, que a
pilha desenha na barra de título:

```tsx
// app/index.tsx: the first screen, the courses and the week's total.
import { Stack, router } from "expo-router";
import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";
import { mondayOf, weekTotal } from "../src/planner";
import { today, usePlan } from "../src/plan";

export default function Courses() {
  const { plan } = usePlan();
  const total = weekTotal(plan, mondayOf(today));
  return (
    <View role="main" style={styles.screen}>
      <Stack.Screen options={{ title: "Study planner" }} />
      <Text style={styles.week}>This week: {total.done} of {total.planned} minutes done</Text>
      <FlatList
        data={plan.courses}
        keyExtractor={(course) => course.id}
        renderItem={({ item }) => (
          <Pressable role="button" style={styles.course} onPress={() => router.push(`/course/${item.id}`)}>
            <Text style={styles.name}>{item.name}</Text>
          </Pressable>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, padding: 16 },
  week: { fontSize: 16, marginBottom: 12 },
  course: { paddingVertical: 14, borderBottomWidth: 1, borderColor: "#d0d7de" },
  name: { fontSize: 20 },
});
```

E a tela do curso, com as sessões, dois campos e um botão:

```tsx
// app/course/[id].tsx: one course, its sessions, and a form to add one.
import { useState } from "react";
import { Stack, useLocalSearchParams } from "expo-router";
import { FlatList, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { mondayOf, weekTotal } from "../../src/planner";
import { today, usePlan } from "../../src/plan";

export default function Course() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { plan, add, done } = usePlan();
  const [date, setDate] = useState("");
  const [minutes, setMinutes] = useState("");
  const [problem, setProblem] = useState("");
  const course = plan.courses.find((c) => c.id === id);
  if (!course) return <Text role="alert">There is no course called {id}.</Text>;
  const total = weekTotal(plan, mondayOf(today));

  function submit() {
    try {
      add(course!.id, date, Number(minutes));
      setDate("");
      setMinutes("");
      setProblem("");
    } catch (e) {
      setProblem((e as Error).message);
    }
  }

  return (
    <View role="main" style={styles.screen}>
      <Stack.Screen options={{ title: course.name }} />
      <Text style={styles.week}>This week: {total.done} of {total.planned} minutes done</Text>
      <FlatList
        data={plan.sessions.filter((s) => s.course === course.id)}
        keyExtractor={(s) => s.id}
        renderItem={({ item: s }) => (
          <View style={styles.row}>
            <Text>{s.date}, {s.minutes} min</Text>
            {s.done ? <Text>done</Text> : (
              <Pressable role="button" onPress={() => done(s.id)}>
                <Text style={styles.action}>Mark done</Text>
              </Pressable>
            )}
          </View>
        )}
      />
      <TextInput aria-label="Date" placeholder="YYYY-MM-DD" value={date} onChangeText={setDate} style={styles.input} />
      <TextInput aria-label="Minutes" keyboardType="number-pad" value={minutes} onChangeText={setMinutes} style={styles.input} />
      <Pressable role="button" style={styles.add} onPress={submit}>
        <Text style={styles.addText}>Add session</Text>
      </Pressable>
      {problem ? <Text role="alert">{problem}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, padding: 16, gap: 8 },
  week: { fontSize: 16 },
  row: { flexDirection: "row", justifyContent: "space-between", paddingVertical: 10 },
  action: { color: "#0a58ca", fontWeight: "600" },
  input: { borderWidth: 1, borderColor: "#8c959f", borderRadius: 6, padding: 10, fontSize: 16 },
  add: { backgroundColor: "#0a58ca", borderRadius: 6, padding: 12, alignItems: "center" },
  addText: { color: "#ffffff", fontSize: 16, fontWeight: "600" },
});
```

- **Os campos são controlados**: `date` e `minutes` são estado, e cada tecla passa pelo `onChangeText`.
  O **`aria-label`** nomeia cada campo, que é o que um leitor de tela lê e por onde o `--fill` do
  `look.mjs` os encontra.
- **`keyboardType="number-pad"`** pede ao celular o teclado de dígitos, uma coisinha que um formulário
  web só ganha com o `inputmode` certo.
- **O erro é um `Text` com `role="alert"`**, que um leitor de tela anuncia assim que ele aparece, como a
  linha de status da aula 4.

Confira os tipos, e exporte:

```
ana@dev:~/planner-native$ npx tsc --noEmit
ana@dev:~/planner-native$ npx expo export --platform web > /dev/null
ana@dev:~/planner-native$ ls dist
_expo
assets
favicon.ico
index.html
metadata.json
```
