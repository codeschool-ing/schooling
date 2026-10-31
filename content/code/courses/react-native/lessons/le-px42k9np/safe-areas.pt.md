---
title: Áreas seguras, em volta do recorte e do indicador de início
version: 1
---

**Uma área segura é a parte da tela sobre a qual nada do sistema desenha.** As bordas dela, os **insets**,
são diferentes em cada modelo: zero num celular antigo de tela retangular simples, por volta de 47 pontos no
topo e 34 no pé num iPhone recente, outros valores no Android. O planner até aqui pôs 64 pontos fixos de
padding no topo, o que é demais num celular e de menos em outro, e nada no pé.

## A biblioteca

A `SafeAreaView` do próprio React Native cobre só o iOS. A biblioteca que todo mundo usa, e que o SDK do Expo
inclui, é a `react-native-safe-area-context`. Instale a versão que o SDK 58 indica:

```
ana@dev:~/planner$ npm install -E react-native-safe-area-context@5.10.1

added 3 packages, and audited 1069 packages in 6s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

Ela tem duas partes. Um **provider** na raiz do app mede os insets a partir do lado nativo e os mantém
atualizados, ao girar por exemplo. Um **hook**, o `useSafeAreaInsets`, os devolve em qualquer lugar abaixo
dele, como `{ top, right, bottom, left }` em pontos.

## A raiz do planner e a tela dele

O `App.tsx` embrulha tudo no provider. Troque-o por:

```tsx
// App.tsx: the planner's root, inside the provider that measures the safe areas.
import { StatusBar } from "expo-status-bar";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import data from "./src/courses.json";
import { PlanScreen } from "./src/PlanScreen";
import type { Plan } from "./src/planner";
import { today } from "./src/today";

const plan: Plan = data;

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <PlanScreen plan={plan} today={today()} />
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
```

O `initialMetrics={initialWindowMetrics}` dá ao provider os insets que o lado nativo já sabia quando o app
começou, para ele desenhar o primeiro quadro na hora. Sem isso, o provider não renderiza nada até chegar a
primeira medição, o que é um quadro em branco num celular e, como a próxima seção descobre, uma tela vazia num
teste.

A tela pede os insets e os soma ao padding, e ganha no pé a frase da seção das extensões de arquivo. Troque o
`src/PlanScreen.tsx` por:

```tsx
// src/PlanScreen.tsx: the first screen, clear of the notch and the home indicator.
import { useState } from "react";
import { Image, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { CourseRow } from "./CourseRow";
import { mondayOf, weekTotal, type Plan } from "./planner";
import { savedWhere } from "./savedWhere";
import { useTheme } from "./theme";
import { WeekBar } from "./WeekBar";

type Props = { plan: Plan; today: string };

export function PlanScreen({ plan, today }: Props) {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const [open, setOpen] = useState<string | null>(null);
  const total = weekTotal(plan, mondayOf(today));
  const course = plan.courses.find((c) => c.id === open);
  return (
    <ScrollView
      style={{ backgroundColor: t.background }}
      contentContainerStyle={[styles.content, { paddingTop: insets.top + 24, paddingBottom: insets.bottom + 24 }]}
    >
      <View testID="header" style={styles.header}>
        <Image source={require("../assets/icon.png")} style={styles.icon} aria-hidden />
        <Text role="heading" style={[styles.title, { color: t.text }]}>
          Study planner
        </Text>
      </View>
      <Text style={[styles.total, { color: t.muted }]}>
        This week: {total.done} of {total.planned} minutes done
      </Text>
      <WeekBar done={total.done} planned={total.planned} />
      <View role="list" style={styles.list}>
        {plan.courses.map((c) => (
          <View role="listitem" key={c.id}>
            <CourseRow
              course={c}
              sessions={plan.sessions.filter((s) => s.course === c.id).length}
              onOpen={setOpen}
            />
          </View>
        ))}
      </View>
      {course && (
        <Text role="status" style={[styles.total, { color: t.text }]}>
          Open: {course.name}
        </Text>
      )}
      <Text style={[styles.footer, { color: t.muted }]}>{savedWhere}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 24 },
  header: { flexDirection: "row", alignItems: "center", gap: 12 },
  icon: { width: 40, height: 40 },
  title: { fontSize: 24, fontWeight: "700" },
  total: { marginVertical: 12, fontSize: 15 },
  list: { marginTop: 16 },
  footer: { marginTop: 24, fontSize: 13 },
});
```

O conteúdo agora começa 24 pontos abaixo de qualquer que seja o inset do topo, e termina 24 acima do de
baixo. Num celular sem recorte os dois insets valem zero, e o padding é o 24 das laterais.

## Nos testes: o substituto da biblioteca

**O Jest não tem lado nativo para medir nada**, então a biblioteca traz um substituto para testes, que informa
as métricas que um teste lhe dá, ou insets zero numa tela de 320 por 640. Todo arquivo de teste precisa dele,
então ele vai num arquivo de setup que o Jest roda antes de cada um. Salve isto como `jest.setup.ts`:

```typescript
// jest.setup.ts: runs before every test file.
// The library's own stand-in: there is no native side in Jest to measure the safe areas.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
```

E avise o Jest no `package.json`:

```sh
npm pkg set "jest.setupFiles[0]=./jest.setup.ts"
```

O teste da tela pode então fingir ser um celular com recorte, dando ao próprio provider as métricas de um.
Troque o `__tests__/PlanScreen.test.tsx` por:

```tsx
// __tests__/PlanScreen.test.tsx: the screen, read the way a screen reader reads it,
// inside a safe-area provider that pretends to be a phone with a notch.
import { fireEvent, render, screen } from "@testing-library/react-native";
import type { ReactElement } from "react";
import { SafeAreaProvider } from "react-native-safe-area-context";
import data from "../src/courses.json";
import { PlanScreen } from "../src/PlanScreen";
import type { Plan } from "../src/planner";

const plan: Plan = data;
const phone = { frame: { x: 0, y: 0, width: 390, height: 844 }, insets: { top: 47, left: 0, right: 0, bottom: 34 } };
const inPhone = (ui: ReactElement) => <SafeAreaProvider initialMetrics={phone}>{ui}</SafeAreaProvider>;

test("every course is a button named for what it holds", async () => {
  await render(inPhone(<PlanScreen plan={plan} today="2026-10-21" />));
  expect(screen.getAllByRole("button")).toHaveLength(3);
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
});

test("pressing a course opens it", async () => {
  await render(inPhone(<PlanScreen plan={plan} today="2026-10-21" />));
  await fireEvent.press(screen.getByRole("button", { name: /Guitar/ }));
  expect(screen.getByRole("status")).toHaveTextContent("Open: Guitar");
});
```
