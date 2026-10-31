---
title: Contando renderizações
version: 1
---

**Quando uma sessão é marcada como feita, que componentes renderizam de novo?** O plano muda, então toda
tela que o lê renderiza, e as listas dela renderizam as linhas. As linhas são onde está o desperdício: a
sessão de uma linha mudou, e toda linha visível renderiza para descobrir isso.

Para contá-las, as linhas precisam ser componentes. Até agora o `SessionList` montava cada linha ali mesmo,
no `renderItem`; leve-a para um arquivo próprio, o `src/SessionRow.tsx`:

```tsx
// src/SessionRow.tsx: one session in a list, with its button to mark it done and its swipe.
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Session } from "./planner";
import { SwipeRow } from "./SwipeRow";
import { useTheme } from "./theme";

type Props = { session: Session; onDone?: (id: string) => void };

export function SessionRow({ session, onDone }: Props) {
  const t = useTheme();
  const row = (
    <View testID={`session-${session.id}`} style={styles.row}>
      <Text style={[styles.session, { color: t.text }]}>
        {session.minutes} min{session.done ? ", done" : ""}
      </Text>
      {onDone && !session.done && (
        <Pressable
          role="button"
          aria-label={`Mark ${session.minutes} min on ${session.date} done`}
          onPress={() => onDone(session.id)}
          hitSlop={8}
        >
          <Text style={[styles.action, { color: t.accent }]}>Mark done</Text>
        </Pressable>
      )}
    </View>
  );
  // only a session that can still be marked done can be swiped
  return onDone && !session.done ? <SwipeRow onDone={() => onDone(session.id)}>{row}</SwipeRow> : row;
}

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  session: { paddingVertical: 8, fontSize: 16 },
  action: { fontSize: 16, fontWeight: "600" },
});
```

e o `src/SessionList.tsx` renderiza uma por sessão:

```tsx
// src/SessionList.tsx: sessions grouped under their day, each a SessionRow.
import { SectionList, StyleSheet, Text } from "react-native";
import type { Session } from "./planner";
import { SessionRow } from "./SessionRow";
import { useTheme } from "./theme";

type Props = { sessions: Session[]; onDone?: (id: string) => void };

export function groupByDate(sessions: Session[]) {
  const days = new Map<string, Session[]>();
  for (const s of [...sessions].sort((a, b) => a.date.localeCompare(b.date))) {
    days.set(s.date, [...(days.get(s.date) ?? []), s]);
  }
  return [...days].map(([date, data]) => ({ title: date, data }));
}

export function SessionList({ sessions, onDone }: Props) {
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
      renderItem={({ item }) => <SessionRow session={item} onDone={onDone} />}
      ListEmptyComponent={<Text style={{ color: t.muted }}>No sessions yet.</Text>}
    />
  );
}

const styles = StyleSheet.create({
  day: { marginTop: 16, fontSize: 13, fontWeight: "600" },
});
```

**Toda linha chama `useTheme` uma vez a cada renderização**, então contar as chamadas a `useTheme` conta as
renderizações. O teste troca o `useTheme` por um `jest.fn` que chama o de verdade, renderiza cinquenta
sessões, zera a contagem, e renderiza de novo com uma sessão marcada como feita. Ele faz isso duas vezes:
uma passando o mesmo callback nas duas vezes, outra passando um novo. Salve o
`__tests__/rowRenders.test.tsx`:

```tsx
// __tests__/rowRenders.test.tsx: how many components render again when one session of fifty is marked
// done. Every row reads the theme once per render, so counting useTheme counts renders.
import { render } from "@testing-library/react-native";
import { markDone, type Session } from "../src/planner";
import { SessionList } from "../src/SessionList";
import { useTheme } from "../src/theme";

jest.mock("../src/theme", () => {
  const actual = jest.requireActual("../src/theme");
  return { ...actual, useTheme: jest.fn(actual.useTheme) };
});
const counted = jest.mocked(useTheme);

const sessions: Session[] = Array.from({ length: 50 }, (_, i) => ({
  id: `s${i}`,
  course: "guitar",
  date: `2026-11-${String(1 + (i % 28)).padStart(2, "0")}`,
  minutes: 20,
  done: false,
}));
const after = markDone({ courses: [], sessions }, "s1").sessions;

test("a callback made once", async () => {
  const onDone = () => {};
  const view = await render(<SessionList sessions={sessions} onDone={onDone} />);
  counted.mockClear();
  await view.rerender(<SessionList sessions={after} onDone={onDone} />);
  console.log("rendered again, with the same callback:", counted.mock.calls.length);
});

test("a callback made on every render", async () => {
  const view = await render(<SessionList sessions={sessions} onDone={() => {}} />);
  counted.mockClear();
  await view.rerender(<SessionList sessions={after} onDone={() => {}} />);
  console.log("rendered again, with a new callback:", counted.mock.calls.length);
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest rowRenders --forceExit 2>&1 | grep -E "rendered again|Tests:"
    rendered again, with the same callback: 6
    rendered again, with a new callback: 6
Tests:       2 passed, 2 total
```

**Seis: a própria lista e cinco linhas**, as que uma `SectionList` desenha de início: dez vagas, e cada dia
ocupa uma com o cabeçalho e uma com o rodapé. As cinco renderizaram de novo, embora só uma sessão tenha
mudado. Agora o `React.memo`: envolva a linha, para o React comparar as props com as da última renderização
e pular a renderização quando cada uma for o mesmo objeto. No `src/SessionRow.tsx`, importe o `memo` e
envolva a função:

```tsx
// src/SessionRow.tsx: one session in a list, with its button to mark it done and its swipe. Memoised: it
// renders again only when its session or its callback is a different object.
import { memo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Session } from "./planner";
import { SwipeRow } from "./SwipeRow";
import { useTheme } from "./theme";

type Props = { session: Session; onDone?: (id: string) => void };

export const SessionRow = memo(function SessionRow({ session, onDone }: Props) {
  const t = useTheme();
  const row = (
    <View testID={`session-${session.id}`} style={styles.row}>
      <Text style={[styles.session, { color: t.text }]}>
        {session.minutes} min{session.done ? ", done" : ""}
      </Text>
      {onDone && !session.done && (
        <Pressable
          role="button"
          aria-label={`Mark ${session.minutes} min on ${session.date} done`}
          onPress={() => onDone(session.id)}
          hitSlop={8}
        >
          <Text style={[styles.action, { color: t.accent }]}>Mark done</Text>
        </Pressable>
      )}
    </View>
  );
  // only a session that can still be marked done can be swiped
  return onDone && !session.done ? <SwipeRow onDone={() => onDone(session.id)}>{row}</SwipeRow> : row;
});

const styles = StyleSheet.create({
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  session: { paddingVertical: 8, fontSize: 16 },
  action: { fontSize: 16, fontWeight: "600" },
});
```

```
ana@dev:~/planner$ npx jest rowRenders --forceExit 2>&1 | grep -E "rendered again|Tests:"
    rendered again, with the same callback: 2
    rendered again, with a new callback: 6
Tests:       2 passed, 2 total
```

**Com o mesmo callback, duas: a lista e a única linha cuja sessão mudou.** As outras linhas receberam o
mesmo objeto `session` de antes, porque o `markDone` da aula 9 só copia a sessão que muda, e o mesmo
`onDone`, então o React as pulou. **Com um callback novo a cada renderização, seis de novo**: uma função
criada dentro de uma renderização é um objeto novo a cada vez, a comparação falha para toda linha, e o
`memo` não faz nada além de comparar.
