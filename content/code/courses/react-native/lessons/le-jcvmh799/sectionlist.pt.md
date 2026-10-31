---
title: A SectionList, para itens que vêm em grupos
version: 1
---

**Uma `SectionList` é uma FlatList cujos dados vêm em seções, cada uma com um cabeçalho.** As sessões de um
curso agrupadas por dia são exatamente isso: uma data, depois as sessões nela, depois a próxima data. A aula 8
dá a cada curso uma tela própria, e esta é a lista dela.

## Agrupando primeiro

Uma SectionList recebe `sections`, um array de `{ title, data }`, e as sessões do planner são um array
simples, então o primeiro passo é uma função que as agrupa. Ela é exportada, para um teste poder conferi-la
sem desenhar nada. Salve isto como `src/SessionList.tsx`:

```tsx
// src/SessionList.tsx: one course's sessions, grouped under the day they fall on.
import { SectionList, StyleSheet, Text } from "react-native";
import type { Session } from "./planner";
import { useTheme } from "./theme";

type Props = { sessions: Session[] };

export function groupByDate(sessions: Session[]) {
  const days = new Map<string, Session[]>();
  for (const s of [...sessions].sort((a, b) => a.date.localeCompare(b.date))) {
    days.set(s.date, [...(days.get(s.date) ?? []), s]);
  }
  return [...days].map(([date, data]) => ({ title: date, data }));
}

export function SessionList({ sessions }: Props) {
  const t = useTheme();
  return (
    <SectionList
      sections={groupByDate(sessions)}
      keyExtractor={(s) => s.id}
      renderSectionHeader={({ section }) => (
        <Text role="heading" aria-level={2} style={[styles.day, { color: t.muted }]}>
          {section.title}
        </Text>
      )}
      renderItem={({ item }) => (
        <Text style={[styles.session, { color: t.text }]}>
          {item.minutes} min{item.done ? ", done" : ""}
        </Text>
      )}
      ListEmptyComponent={<Text style={{ color: t.muted }}>No sessions yet.</Text>}
    />
  );
}

const styles = StyleSheet.create({
  day: { marginTop: 16, fontSize: 13, fontWeight: "600" },
  session: { paddingVertical: 8, fontSize: 16 },
});
```

O `groupByDate` ordena uma cópia, nunca o array que recebeu, e depois junta as sessões sob a data num `Map`,
que guarda a ordem em que as datas apareceram. O `renderSectionHeader` desenha cada data como um título de
nível 2, abaixo do título da própria tela, para que um usuário de leitor de tela possa pular de dia em dia.
Os dois `keyExtractor`, o da FlatList e este, usam o mesmo id em que a seção anterior insistiu.

**O `ListEmptyComponent` diz alguma coisa quando não há nada.** Uma lista sem itens não desenha nada, e uma
tela em branco não se distingue de uma que falhou ao carregar.

## Testada de três jeitos

Salve isto como `__tests__/SessionList.test.tsx`:

```tsx
// __tests__/SessionList.test.tsx: sessions under their days, and an empty course.
import { render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { groupByDate, SessionList } from "../src/SessionList";

const spanish = data.sessions.filter((s) => s.course === "spanish");

test("sessions are grouped by day, in date order", () => {
  expect(groupByDate(spanish).map((g) => [g.title, g.data.length])).toEqual([
    ["2026-10-19", 1],
    ["2026-10-22", 1],
  ]);
});

test("each day is a heading, and each session a line under it", async () => {
  await render(<SessionList sessions={spanish} />);
  expect(screen.getAllByRole("heading").map((h) => h.props.children)).toEqual(["2026-10-19", "2026-10-22"]);
  expect(screen.getByText("30 min, done")).toBeOnTheScreen();
});

test("a course with no sessions says so", async () => {
  await render(<SessionList sessions={[]} />);
  expect(screen.getByText("No sessions yet.")).toBeOnTheScreen();
});
```

```
ana@dev:~/planner$ npx jest SessionList
PASS __tests__/SessionList.test.tsx
  ✓ sessions are grouped by day, in date order (16 ms)
  ✓ each day is a heading, and each session a line under it (226 ms)
  ✓ a course with no sessions says so (4 ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
Snapshots:   0 total
Time:        0.831 s, estimated 1 s
Ran all test suites matching SessionList.
```

O primeiro teste confere o agrupamento sem renderização nenhuma; o segundo, que cada dia é anunciado como
título e que a sessão sob ele diz que está feita; o terceiro, que um curso vazio diz isso. O *Spanish A2* tem
duas sessões em dois dias, pelos dados da aula 3.
