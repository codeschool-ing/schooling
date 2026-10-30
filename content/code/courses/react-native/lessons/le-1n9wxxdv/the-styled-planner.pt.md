---
title: O planner, com estilo
version: 1
---

**Esta seção põe a aula no planner**: o tema em toda parte, a barra da semana sob o total, e cada estilo num
`StyleSheet`. Dois arquivos mudam por inteiro. Salve a linha como `src/CourseRow.tsx`:

```tsx
// src/CourseRow.tsx: one course in the list, as a button that says what it holds.
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Course } from "./planner";
import { useTheme } from "./theme";

type Props = { course: Course; sessions: number; onOpen: (id: string) => void };

export function CourseRow({ course, sessions, onOpen }: Props) {
  const t = useTheme();
  return (
    <Pressable
      testID={`row-${course.id}`}
      role="button"
      accessibilityHint={`Opens ${course.name}`}
      onPress={() => onOpen(course.id)}
      hitSlop={8}
      style={({ pressed }) => [styles.row, { borderColor: t.line }, pressed && { backgroundColor: t.pressed }]}
    >
      <View>
        <Text style={[styles.name, { color: t.text }]}>{course.name}</Text>
        <Text style={[styles.count, { color: t.muted }]}>
          {sessions} {sessions === 1 ? "session" : "sessions"} planned
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { paddingVertical: 12, paddingHorizontal: 16, borderBottomWidth: 1 },
  name: { fontSize: 17, fontWeight: "600" },
  count: { fontSize: 14 },
});
```

O `testID` é um nome para testes e ferramentas, e só para eles: um leitor de tela nunca o anuncia. No build
web ele vira um atributo `data-testid`, que é o que o `boxes.mjs` procura. E a tela, como
`src/PlanScreen.tsx`:

```tsx
// src/PlanScreen.tsx: the planner's first screen, styled, with the week as a bar.
import { useState } from "react";
import { Image, ScrollView, StyleSheet, Text, View } from "react-native";
import { CourseRow } from "./CourseRow";
import { mondayOf, weekTotal, type Plan } from "./planner";
import { useTheme } from "./theme";
import { WeekBar } from "./WeekBar";

type Props = { plan: Plan; today: string };

export function PlanScreen({ plan, today }: Props) {
  const t = useTheme();
  const [open, setOpen] = useState<string | null>(null);
  const total = weekTotal(plan, mondayOf(today));
  const course = plan.courses.find((c) => c.id === open);
  return (
    <ScrollView style={{ backgroundColor: t.background }} contentContainerStyle={styles.content}>
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
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { padding: 24, paddingTop: 64 },
  header: { flexDirection: "row", alignItems: "center", gap: 12 },
  icon: { width: 40, height: 40 },
  title: { fontSize: 24, fontWeight: "700" },
  total: { marginVertical: 12, fontSize: 15 },
  list: { marginTop: 16 },
});
```

A linha de status agora ocupa várias linhas, `{course && ( … )}`, que é a mesma expressão de antes com espaço
para o estilo.

## Um teste da barra

Salve isto como `__tests__/WeekBar.test.tsx`. Ele confere os números que a barra recebeu, que é a metade que um
teste consegue ver:

```tsx
// __tests__/WeekBar.test.tsx: the bar's two parts grow in the ratio of done to left.
import { render, screen } from "@testing-library/react-native";
import { WeekBar } from "../src/WeekBar";

test("done and left share the bar by flex", async () => {
  await render(<WeekBar done={75} planned={125} />);
  expect(screen.getByTestId("week-done")).toHaveStyle({ flex: 75 });
  expect(screen.getByTestId("week-left")).toHaveStyle({ flex: 50 });
  expect(screen.getByRole("progressbar")).toHaveAccessibilityValue({ min: 0, max: 125, now: 75 });
});
```

O `toHaveStyle` confere um estilo que foi definido; o `toHaveAccessibilityValue` confere o que um leitor de
tela diria sobre o valor da barra. Depois a suíte inteira, e os tipos:

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npm test

> planner@1.0.0 test
> jest

PASS __tests__/WeekBar.test.tsx
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/App.test.tsx
PASS __tests__/planner.test.ts

Test Suites: 4 passed, 4 total
Tests:       8 passed, 8 total
Snapshots:   0 total
Time:        1.217 s
Ran all test suites.
```

## Mais largo que um celular

A seção do flexbox mediu a tela nos 390 pontos de um celular. O mesmo comando em 768 por 1024 é um tablet em
pé:

```
ana@dev:~/planner$ node boxes.mjs 'http://localhost:8082/?today=2026-10-21' 768 1024
header       x=24 y=64 w=720 h=40  rgba(0, 0, 0, 0)
week-bar     x=24 y=147 w=720 h=12  rgb(230, 235, 240)
week-done    x=24 y=147 w=432 h=12  rgb(47, 111, 78)
week-left    x=456 y=147 w=288 h=12  rgba(0, 0, 0, 0)
row-spanish  x=24 y=175 w=720 h=62  rgba(0, 0, 0, 0)
row-statistics x=24 y=237 w=720 h=62  rgba(0, 0, 0, 0)
row-guitar   x=24 y=299 w=720 h=62  rgba(0, 0, 0, 0)
```

Toda largura cresceu, e nenhum estilo cita 768. O conteúdo tem 720 de largura, a janela menos o padding; a
barra continua com 60 partes feitas para 40 que faltam, agora 432 para 288; as linhas se esticam. **Esse é um
leiaute escrito em proporções e não em tamanhos**, e é o que deixa uma tela servir aos dois. Um tablet
geralmente mereceria mais que um leiaute de celular esticado, duas colunas por exemplo, e essa é uma decisão
para o `useWindowDimensions`, tomada no componente que sabe para que serve a segunda coluna.
