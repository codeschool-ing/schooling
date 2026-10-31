---
title: "Parâmetros: o id, e só o id"
version: 1
---

**Uma tela recebe o que precisa saber em `route.params`**, passado por quem navegou até ela:
`navigation.navigate("Course", { id: "guitar" })`. O tipo dos parâmetros de cada rota é declarado uma vez, em
`RootParams`, e o TypeScript recusa uma navegação que deixe um de fora ou passe o tipo errado.

## Passe o id, nunca o objeto

É tentador passar o curso inteiro, `{ course }`, porque a tela vai precisar do nome dele. **Passe o id.** Três
motivos, cada um um bug que alguém já lançou:

- **Os parâmetros são uma cópia.** Um curso passado como objeto é o curso como estava quando o botão foi
  apertado. Renomeie-o, marque uma sessão como feita, e a tela aberta continua mostrando a cópia antiga.
- **Parâmetros viram endereços.** A próxima seção transforma `course/:id` num link; um link carrega
  `guitar`, e não carrega um objeto.
- **Parâmetros são estado.** Eles moram no estado de navegação, que um app pode salvar e restaurar, e que na
  web é o endereço. Um objeto grande ali é memória carregada para todo lado, e um objeto com funções dentro
  não pode ser salvo.

A tela então **procura o curso pelo id**, que é a mesma ligação que os dados do planner usam em toda parte.
Salve isto como `src/CourseScreen.tsx`:

```tsx
// src/CourseScreen.tsx: one course, reached with its id and nothing else.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useLayoutEffect } from "react";
import { StyleSheet, Text, View } from "react-native";
import data from "./courses.json";
import type { RootParams } from "./navigation";
import type { Plan } from "./planner";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";

const plan: Plan = data;

export function CourseScreen({ route, navigation }: NativeStackScreenProps<RootParams, "Course">) {
  const t = useTheme();
  const course = plan.courses.find((c) => c.id === route.params.id);
  useLayoutEffect(() => {
    navigation.setOptions({ title: course?.name ?? "Not found" });
  }, [navigation, course]);
  if (!course) {
    return (
      <View style={[styles.screen, { backgroundColor: t.background }]}>
        <Text style={[styles.missing, { color: t.text }]}>There is no course called {route.params.id}.</Text>
      </View>
    );
  }
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <SessionList sessions={plan.sessions.filter((s) => s.course === course.id)} />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  missing: { marginTop: 24, fontSize: 17 },
});
```

O `useLayoutEffect` define o título do cabeçalho a partir do curso assim que ele é encontrado, antes de a
tela ser desenhada, para o cabeçalho nunca mostrar um texto provisório. **Um id que não casa com nada não é um
erro para esconder**: um link velho, um curso apagado, um erro de digitação num endereço. A tela diz claramente
que esse curso não existe, e a próxima seção abre um para prová-lo.

## Testado apertando

Salve isto como `__tests__/navigation.test.tsx`:

```tsx
// __tests__/navigation.test.tsx: pressing a course opens its screen, and an address opens it too.
import { getStateFromPath, NavigationContainer } from "@react-navigation/native";
import { fireEvent, render, screen } from "@testing-library/react-native";
import { linking, RootNavigator } from "../src/navigation";

test("pressing a course pushes its screen", async () => {
  await render(
    <NavigationContainer>
      <RootNavigator />
    </NavigationContainer>,
  );
  await fireEvent.press(screen.getByRole("button", { name: /^Guitar/ }));
  expect(screen.getAllByRole("heading").map((h) => h.props.children)).toEqual(["2026-10-21", "2026-10-28"]);
  expect(screen.getAllByText("20 min")).toHaveLength(2);
});

test("the address course/statistics reaches the Course screen with its id", () => {
  const state = getStateFromPath("course/statistics", linking.config);
  expect(state?.routes.at(-1)).toMatchObject({ name: "Course", params: { id: "statistics" } });
});
```

O primeiro teste renderiza os navegadores de verdade, aperta *Guitar*, e encontra os dois dias do curso e as
duas sessões de 20 minutos. O Jest não desenha o cabeçalho nativo, então o teste confere o que a própria tela
mostra. O segundo confere um endereço sem renderizar nada, que é o assunto da próxima seção.

O `__tests__/PlanScreen.test.tsx` da aula 6 renderizava a tela com props que ela não recebe mais, então ele
muda também, para renderizar os navegadores com os insets do celular com recorte:

```tsx
// __tests__/PlanScreen.test.tsx: the Courses tab, read the way a screen reader reads it,
// inside a safe-area provider that pretends to be a phone with a notch.
import { NavigationContainer } from "@react-navigation/native";
import { render, screen } from "@testing-library/react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { RootNavigator } from "../src/navigation";

const phone = { frame: { x: 0, y: 0, width: 390, height: 844 }, insets: { top: 47, left: 0, right: 0, bottom: 34 } };

test("every course is a button named for what it holds, beside the two tabs", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(
    <SafeAreaProvider initialMetrics={phone}>
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>
    </SafeAreaProvider>,
  );
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
  expect(screen.getByText("This week")).toBeOnTheScreen(); // the second tab's label
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest navigation PlanScreen App
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/App.test.tsx
PASS __tests__/navigation.test.tsx

Test Suites: 3 passed, 3 total
Tests:       4 passed, 4 total
Snapshots:   0 total
Time:        2.291 s
Ran all test suites matching navigation|PlanScreen|App.
```
