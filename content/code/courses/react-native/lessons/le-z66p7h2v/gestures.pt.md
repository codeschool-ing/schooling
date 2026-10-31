---
title: Uma linha que segue o dedo
version: 1
---

**Um gesto é uma animação cujo próximo quadro depende de um dedo**, e é por isso que o driver nativo não
consegue fazê-lo e o Reanimated consegue. O planner ganha um: em *This week*, uma sessão ainda não feita
pode ser arrastada para a esquerda e, arrastada longe o bastante, fica marcada como feita.

**O botão *Mark done* fica.** Um swipe é invisível até alguém contar que ele existe, um leitor de tela
não consegue fazê-lo, e há quem não consiga arrastar. Toda ação que um gesto oferece precisa de um
controle que faça a mesma coisa; o gesto é um atalho para quem o conhece.

## A raiz do app

O React Native Gesture Handler reconhece toques do lado nativo, então precisa ficar na raiz do app, por
onde todo toque passa. Envolva o planner num `GestureHandlerRootView`:

```tsx
// App.tsx: the planner's root: gestures, safe areas, the query client, and the plan once it has arrived.
import { NavigationContainer } from "@react-navigation/native";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StatusBar } from "expo-status-bar";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { Pressable, Text, View } from "react-native";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { linking, RootNavigator } from "./src/navigation";
import { usePlanQuery } from "./src/planState";

const client = new QueryClient();

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
        <QueryClientProvider client={client}>
          <Loaded />
        </QueryClientProvider>
        <StatusBar style="auto" />
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

## A regra, separada

Quão longe é longe o bastante é uma decisão, e uma decisão merece um teste. Ela mora num arquivo próprio,
com a diretiva `"worklet"` para que o gesto possa chamá-la na thread de UI:

```tsx
// src/swipe.ts: how far a row must be dragged to count as done.
// A worklet, so the gesture can call it on the UI thread; in Jest it is an ordinary function.
export const SWIPE_DONE = 96;

export function swipeCompletes(dx: number) {
  "worklet";
  return dx < -SWIPE_DONE;
}
```

Fora de um worklet a diretiva é só uma string, então o Jest e o resto do app chamam a função como
qualquer outra.

## A linha

```schooling-example
{"language": "tsx", "file": "src/SwipeRow.tsx", "parts": [{"code": "// src/SwipeRow.tsx: a row that follows a finger to the left and, dragged far enough, marks itself done.\n// The row's own button does the same thing; the swipe is a shortcut, never the only way.\nimport type { ReactNode } from \"react\";\nimport { GestureDetector, usePanGesture } from \"react-native-gesture-handler\";\nimport Animated, { useAnimatedStyle, useSharedValue, withSpring } from \"react-native-reanimated\";\nimport { scheduleOnRN } from \"react-native-worklets\";\nimport { swipeCompletes } from \"./swipe\";\n\ntype Props = { onDone: () => void; children: ReactNode };\n", "note": "Três bibliotecas se encontram aqui: o gesto vem do Gesture Handler, o movimento do Reanimated e o caminho de volta ao JavaScript do Worklets."}, {"code": "export function SwipeRow({ onDone, children }: Props) {\n  const x = useSharedValue(0);", "note": "O `x` é quanto a linha andou. Começa em 0, e só a thread de UI o muda enquanto o dedo está na tela."}, {"code": "  const pan = usePanGesture({\n    activeOffsetX: [-12, 12],", "note": "Um **pan** é um dedo que se move. O `activeOffsetX` o faz esperar até o dedo andar 12 pontos para o lado antes de tomar o toque, e assim uma rolagem vertical pela lista continua rolando."}, {"code": "    onUpdate: (e) => {\n      x.value = Math.min(0, e.translationX);\n    },", "note": "Chamado a cada movimento, na thread de UI. O `translationX` é a distância desde onde o dedo pousou; o `Math.min` deixa a linha ir para a esquerda e nunca para a direita."}, {"code": "    onDeactivate: (e) => {\n      if (swipeCompletes(e.translationX)) scheduleOnRN(onDone);\n      x.value = withSpring(0);\n    },\n  });", "note": "Chamado uma vez, quando o dedo sobe. A decisão é um worklet, então pode rodar aqui; o `onDone` é uma função comum do planner, então o `scheduleOnRN` a entrega à thread do JavaScript. Nos dois casos a linha volta com uma mola: a lista a redesenha como feita se o servidor concordar."}, {"code": "  const moved = useAnimatedStyle(() => ({ transform: [{ translateX: x.value }] }));\n  return (\n    <GestureDetector gesture={pan}>\n      <Animated.View style={moved}>{children}</Animated.View>\n    </GestureDetector>\n  );\n}", "note": "O `GestureDetector` prende o gesto à view de dentro. O estilo acompanha o `x` a cada quadro sem renderização, que é o motivo disso tudo."}]}
```

E o `src/SessionList.tsx` envolve num deles cada sessão que ainda pode ser feita. A linha em si não
mudou, a não ser por um `testID` para um programa conseguir achá-la:

```tsx
// src/SessionList.tsx: sessions grouped under their day, each with a button to mark it done.
import { Pressable, SectionList, StyleSheet, Text, View } from "react-native";
import type { Session } from "./planner";
import { SwipeRow } from "./SwipeRow";
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
      renderItem={({ item }) => {
        const row = (
          <View testID={`session-${item.id}`} style={styles.row}>
            <Text style={[styles.session, { color: t.text }]}>
              {item.minutes} min{item.done ? ", done" : ""}
            </Text>
            {onDone && !item.done && (
              <Pressable
                role="button"
                aria-label={`Mark ${item.minutes} min on ${item.date} done`}
                onPress={() => onDone(item.id)}
                hitSlop={8}
              >
                <Text style={[styles.action, { color: t.accent }]}>Mark done</Text>
              </Pressable>
            )}
          </View>
        );
        // only a session that can still be marked done can be swiped
        return onDone && !item.done ? <SwipeRow onDone={() => onDone(item.id)}>{row}</SwipeRow> : row;
      }}
      ListEmptyComponent={<Text style={{ color: t.muted }}>No sessions yet.</Text>}
    />
  );
}

const styles = StyleSheet.create({
  day: { marginTop: 16, fontSize: 13, fontWeight: "600" },
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  session: { paddingVertical: 8, fontSize: 16 },
  action: { fontSize: 16, fontWeight: "600" },
});
```

## Jest e Reanimated, nesta gravação

Rode os testes da lista:

```
ana@dev:~/planner$ npx jest SessionList --forceExit 2>&1 | head -8
FAIL __tests__/SessionList.test.tsx
  ● Test suite failed to run

    TypeError: Cannot read properties of undefined (reading 'loadUnpackersWithCode')

      3 | import type { ReactNode } from "react";
      4 | import { GestureDetector, usePanGesture } from "react-native-gesture-handler";
    > 5 | import Animated, { useAnimatedStyle, useSharedValue, withSpring } from "react-native-reanimated";
```

**O erro não é seu.** O Reanimated 4.7.1 liga o runtime de worklets assim que é importado, e dentro do
`jest-expo` 58 não há módulo nativo para ele ligar. O Reanimated traz um substituto para testes, o
`react-native-reanimated/mock`, e *quando este curso foi gravado ele falhou no mesmo lugar, com
"`setCSSEventHandler` is not available"*. Pode muito bem estar corrigido quando você ler isto; confira as
notas da biblioteca sobre testes antes de copiar o contorno.

O contorno é impedir o Jest de chegar ao Reanimated. O `SwipeRow` é o único arquivo que o importa, então
os testes trocam o `SwipeRow` pelos filhos dele. As três últimas linhas do `jest.setup.ts` são novas:

```ts
// jest.setup.ts: runs before every test file.
// The libraries' own stand-ins: there is no native side in Jest to measure or to ask.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
jest.mock("@react-native-community/netinfo", () => require("@react-native-community/netinfo/jest/netinfo-mock.js"));
// Reanimated 4.7 cannot start inside jest-expo 58, not even as its own stand-in, so the one
// component that uses it is replaced by its children. The rule it applies is tested on its own.
jest.mock("./src/SwipeRow", () => ({ SwipeRow: ({ children }: { children: unknown }) => children }));
```

Isso não custa nada do que os testes conferiam: eles apertam botões e leem texto, e um `SwipeRow` que só
renderiza os filhos deixa os dois onde estavam. O que custa é qualquer teste do próprio gesto, e foi por
isso que a regra ficou separada. Salve o `__tests__/swipe.test.ts`:

```ts
import { SWIPE_DONE, swipeCompletes } from "../src/swipe";

test("a short drag is not a decision", () => {
  expect(swipeCompletes(-60)).toBe(false);
});

test("past the threshold to the left, the row is done", () => {
  expect(swipeCompletes(-(SWIPE_DONE + 1))).toBe(true);
});

test("to the right, never", () => {
  expect(swipeCompletes(400)).toBe(false);
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest --forceExit
PASS __tests__/SessionList.test.tsx
PASS __tests__/done.test.tsx
PASS __tests__/swipe.test.ts
PASS __tests__/AddSession.test.tsx
PASS __tests__/WeekBar.test.tsx
PASS __tests__/virtual.test.tsx
  ● Console

    console.log
      ScrollView rows created: 1000

      at Object.log (__tests__/virtual.test.tsx:15:11)

    console.log
      FlatList rows created: 10

      at Object.log (__tests__/virtual.test.tsx:20:11)

PASS __tests__/App.test.tsx
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/keys.test.tsx
  ● Console

    console.log
      by index: statistics, guitar (open)

      at Object.log (__tests__/keys.test.tsx:29:13)

    console.log
      by id: statistics (open), guitar

      at Object.log (__tests__/keys.test.tsx:29:13)

PASS __tests__/navigation.test.tsx
PASS __tests__/renders.test.tsx
  ● Console

    console.log
      context: done rendered 3 times, theme rendered 3 times

      at Object.log (__tests__/renders.test.tsx:46:11)

    console.log
      store: done rendered 3 times, theme rendered 0 times

      at Object.log (__tests__/renders.test.tsx:58:11)

PASS __tests__/validate.test.ts
PASS __tests__/reducer.test.ts
PASS __tests__/planner.test.ts
PASS __tests__/platform.test.ts
  ● Console

    console.log
      ios | Saved on this iPhone | shadowColor shadowOpacity shadowRadius shadowOffset

      at Object.log (__tests__/platform.test.ts:8:11)

PASS __tests__/failure.test.tsx (8.518 s)
A worker process has failed to exit gracefully and has been force exited. This is likely caused by tests leaking due to improper teardown. Try running with --detectOpenHandles to find leaks. Active timers can also cause this, ensure that .unref() was called on them.

Test Suites: 16 passed, 16 total
Tests:       38 passed, 38 total
Snapshots:   0 total
Time:        9.405 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

## O gesto, num navegador

O que o Jest não consegue rodar, um navegador consegue: o Gesture Handler e o Reanimated funcionam os
dois na web, e arrastar o mouse é um pan com um dedo. Este programa abre uma tela pelo seu deep link,
acha a linha de uma sessão, a arrasta para a esquerda por uma distância dada em dez passos, como um dedo
faria, e imprime a linha antes e depois. Salve-o como `swipe.mjs`:

```javascript
// swipe.mjs: drag one session's row to the left with the mouse, as a finger would, and print the
// row's text before and after.
//
//   node swipe.mjs URL SESSION DISTANCE
//
// URL is the screen the row is on, as a deep link.
import { chromium } from "playwright";

const [url, session, distance] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url);
await page.waitForLoadState("networkidle");
const row = page.getByTestId(`session-${session}`);
const text = row.getByText(/min/);
console.log("before:", await text.innerText());
const box = await row.boundingBox();
const [x, y] = [box.x + box.width / 2, box.y + box.height / 2];
await page.mouse.move(x, y);
await page.mouse.down();
for (let step = 1; step <= 10; step++) await page.mouse.move(x - (distance * step) / 10, y);
await page.mouse.up();
await page.waitForTimeout(1000); // the spring back, and the server's answer if one was asked for
console.log("after: ", await text.innerText());
await browser.close();
```

Exporte o build web de novo, já que agora ele carrega as duas bibliotecas, suba o servidor do zero e
sirva o `dist/` como antes. Depois arraste a sessão do dia 22 duas vezes, 60 pontos e depois 150. O
endereço é o deep link da aula 8 para *This week*, com a semana fixada por `?today=` como o `frames.mjs`
a fixa:

```
ana@dev:~/planner$ node swipe.mjs 'http://localhost:8082/week?today=2026-10-21' s4 60
before: 30 min
after:  30 min
ana@dev:~/planner$ node swipe.mjs 'http://localhost:8082/week?today=2026-10-21' s4 150
before: 30 min
after:  30 min, done
```

**Com 60 pontos ela volta; com 150 fica feita.** O limite é 96, então o primeiro arraste termina com a
linha onde estava e nada enviado. O segundo o ultrapassa, e o log do servidor mostra o que isso custou:

```
listening on 8008
GET / 
GET /plan 
GET /plan 
POST /sessions/s4/done 
GET /plan 
```

Leia de cima: o servidor dizendo que subiu, depois o `GET /`, a máquina de gravação conferindo que ele
responde; um `GET /plan` por visita; e entre os dois últimos um único `POST /sessions/s4/done`, o que o
segundo arraste mandou. *Num celular o mesmo código roda o movimento na thread de UI, o que este curso não mediu; o
navegador tem uma thread só e o roda nela.*
