---
title: A FlatList, e a primeira tela do planner como uma
version: 1
---

**Uma FlatList precisa de três coisas: os `data`, um `renderItem` que desenha uma entrada, e um
`keyExtractor` que diz qual entrada é qual.**

```tsx
<FlatList
  data={plan.courses}
  keyExtractor={(c) => c.id}
  renderItem={({ item }) => <CourseRow course={item} sessions={0} onOpen={setOpen} />}
/>
```

O `renderItem` recebe `{ item, index }` e devolve o que desenhar para aquele item. Ele só é chamado para os
itens sendo renderizados, então não pode depender de ter sido chamado para todos.

## A lista é dona da rolagem

**Uma FlatList é ela mesma uma scroll view**, e pô-la dentro de uma `ScrollView` que rola na mesma direção a
quebra: a view de fora dá à lista toda a altura que ela pede, a lista conclui que todo item está visível, e
renderiza todos. O React Native avisa exatamente sobre isso, *VirtualizedLists should never be nested inside
plain ScrollViews with the same orientation*. Então a tela do planner vira do avesso: a FlatList vira a tela,
e o que ficava acima e abaixo da lista vai para dentro dela.

| prop | o que guarda |
|---|---|
| `ListHeaderComponent` | o que rola acima dos itens: aqui o título, o total e a barra |
| `ListFooterComponent` | o que rola abaixo deles: a linha de status e a frase da aula 6 |
| `ListEmptyComponent` | o que mostrar quando os `data` estão vazios |
| `contentContainerStyle` | o padding em volta de tudo, como numa ScrollView |

Troque o `src/PlanScreen.tsx` por isto:

```tsx
// src/PlanScreen.tsx: the first screen, with the courses in a FlatList.
import { useState } from "react";
import { FlatList, Image, StyleSheet, Text, View } from "react-native";
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
  const header = (
    <View>
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
    </View>
  );
  const footer = (
    <View>
      {course && (
        <Text role="status" style={[styles.total, { color: t.text }]}>
          Open: {course.name}
        </Text>
      )}
      <Text style={[styles.footer, { color: t.muted }]}>{savedWhere}</Text>
    </View>
  );
  return (
    <FlatList
      data={plan.courses}
      keyExtractor={(c) => c.id}
      renderItem={({ item }) => (
        <CourseRow
          course={item}
          sessions={plan.sessions.filter((s) => s.course === item.id).length}
          onOpen={setOpen}
        />
      )}
      ListHeaderComponent={header}
      ListHeaderComponentStyle={styles.listTop}
      ListFooterComponent={footer}
      style={{ backgroundColor: t.background }}
      contentContainerStyle={[styles.content, { paddingTop: insets.top + 24, paddingBottom: insets.bottom + 24 }]}
    />
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 24 },
  header: { flexDirection: "row", alignItems: "center", gap: 12 },
  icon: { width: 40, height: 40 },
  title: { fontSize: 24, fontWeight: "700" },
  total: { marginVertical: 12, fontSize: 15 },
  listTop: { marginBottom: 16 },
  footer: { marginTop: 24, fontSize: 13 },
});
```

O `header` e o `footer` são elementos construídos no componente, então enxergam o estado e o tema dele como
todo o resto.

## Conferida como antes

Os testes das aulas 4 e 6 encontram os mesmos botões e a mesma linha de status na tela nova, que é o objetivo
de testar pelo que uma pessoa vê e não por como a coisa é construída:

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest PlanScreen App
PASS __tests__/App.test.tsx
PASS __tests__/PlanScreen.test.tsx

Test Suites: 2 passed, 2 total
Tests:       3 passed, 3 total
Snapshots:   0 total
Time:        1.46 s
Ran all test suites matching PlanScreen|App.
```

O build web se lê como antes, um título, o total, a barra e três botões:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done"
- progressbar "Minutes done this week"
- button "Spanish A2 2 sessions planned"
- button "Statistics 2 sessions planned"
- button "Guitar 2 sessions planned"
- text: Saved in this browser
```

**Uma coisa se perdeu, e vale dizer.** A aula 4 pôs os cursos numa `View` com `role="list"`, para um leitor
de tela anunciar *lista, três itens*. Uma FlatList desenha as próprias células e não lhes dá papel, e um
`role="list"` na própria FlatList cobriria também o título e o rodapé, já que agora estão dentro dela; a
primeira gravação desta seção teve exatamente isso, uma `list` contendo o título. Então os três botões agora
ficam depois da barra sem uma lista em volta. Cada um ainda diz o que é e o que guarda, que é o que uma pessoa
precisa para escolher um.
