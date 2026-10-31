---
title: A primeira tela de verdade do planner
version: 1
---

**As peças desta aula, juntas, fazem a tela em que o planner abre**: um título com o ícone do app, o total
da semana, e cada curso como um botão que diz quantas sessões guarda. Apertar um o abre, o que por
enquanto só diz qual curso está aberto; a aula 8 lhe dá uma tela própria. Salve isto como
`src/PlanScreen.tsx`:

```schooling-example
{"language": "tsx", "file": "src/PlanScreen.tsx", "parts": [{"code": "// src/PlanScreen.tsx: the planner's first screen, built from the core components.\nimport { useState } from \"react\";\nimport { Image, ScrollView, Text, View } from \"react-native\";\nimport { CourseRow } from \"./CourseRow\";\nimport { mondayOf, weekTotal, type Plan } from \"./planner\";\n", "note": "O `useState` é o único pedaço de estado React desta tela. Os componentes vêm de `react-native`, as regras do `src/planner.ts` da aula 3, sem mudança."}, {"code": "type Props = { plan: Plan; today: string };\n", "note": "A tela recebe o plano e a data como props em vez de lê-los sozinha, então um teste pode lhe entregar qualquer plano e qualquer dia."}, {"code": "export function PlanScreen({ plan, today }: Props) {\n  const [open, setOpen] = useState<string | null>(null);\n  const total = weekTotal(plan, mondayOf(today));\n  const course = plan.courses.find((c) => c.id === open);\n  return (\n    <ScrollView contentContainerStyle={{ padding: 24, paddingTop: 64 }}>", "note": "Tudo o que é calculado aqui é recalculado a cada renderização, a partir das props e do estado: o total, e o curso aberto, se houver. A tela inteira rola, com o padding no conteúdo."}, {"code": "      <View style={{ flexDirection: \"row\", alignItems: \"center\", gap: 12 }}>\n        <Image source={require(\"../assets/icon.png\")} style={{ width: 40, height: 40 }} aria-hidden />\n        <Text role=\"heading\" style={{ fontSize: 24, fontWeight: \"700\" }}>\n          Study planner\n        </Text>\n      </View>", "note": "Uma linha: o ícone e o título lado a lado. O ícone é decorativo, por isso `aria-hidden`; o título tem `role=\"heading\"`, que um leitor de tela usa para encontrá-lo."}, {"code": "      <Text style={{ marginVertical: 12 }}>\n        This week: {total.done} of {total.planned} minutes done\n      </Text>", "note": "O total, como um único `Text` com os números entre chaves, para ser uma frase só para um leitor de tela."}, {"code": "      <View role=\"list\">\n        {plan.courses.map((c) => (\n          <View role=\"listitem\" key={c.id}>\n            <CourseRow\n              course={c}\n              sessions={plan.sessions.filter((s) => s.course === c.id).length}\n              onOpen={setOpen}\n            />\n          </View>\n        ))}\n      </View>", "note": "A lista. `role=\"list\"` e `role=\"listitem\"` deixam um leitor de tela dizer *lista, três itens*. O `map` transforma cada curso num elemento, e o `key` diz ao React qual elemento é qual curso de uma renderização para a outra; a aula 7 explica por que precisa ser o id."}, {"code": "      {course && <Text role=\"status\" style={{ marginTop: 12 }}>Open: {course.name}</Text>}\n    </ScrollView>\n  );\n}", "note": "Mostrado só quando há um curso aberto. O `role=\"status\"` faz um leitor de tela anunciá-lo quando aparece, sem mudar o lugar do usuário."}]}
```

O `App.tsx` fica pequeno: ele passa os dados e a data de hoje para a tela, e acrescenta a barra de status.
Troque-o por:

```tsx
// App.tsx: the planner's root, which only hands the data to the first screen.
import { StatusBar } from "expo-status-bar";
import data from "./src/courses.json";
import { PlanScreen } from "./src/PlanScreen";
import type { Plan } from "./src/planner";
import { today } from "./src/today";

const plan: Plan = data;

export default function App() {
  return (
    <>
      <PlanScreen plan={plan} today={today()} />
      <StatusBar style="auto" />
    </>
  );
}
```

## Conferida num teste

O teste lê a tela do jeito que um leitor de tela lê, por papel e por nome. Salve-o como
`__tests__/PlanScreen.test.tsx`:

```tsx
// __tests__/PlanScreen.test.tsx: the screen, read the way a screen reader reads it.
import { fireEvent, render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { PlanScreen } from "../src/PlanScreen";
import type { Plan } from "../src/planner";

const plan: Plan = data;

test("every course is a button named for what it holds", async () => {
  await render(<PlanScreen plan={plan} today="2026-10-21" />);
  expect(screen.getAllByRole("button")).toHaveLength(3);
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
});

test("pressing a course opens it", async () => {
  await render(<PlanScreen plan={plan} today="2026-10-21" />);
  await fireEvent.press(screen.getByRole("button", { name: /Guitar/ }));
  expect(screen.getByRole("status")).toHaveTextContent("Open: Guitar");
});
```

O `getByRole("button", { name: … })` encontra o botão cujo nome acessível é exatamente aquele texto, que é
o texto de dentro dele juntado com espaços. Se alguém depois embrulhar o nome do curso numa `View` sem
papel, ou transformar a linha em algo que não é botão, isto falha, e diz qual elemento não encontrou. O
`fireEvent.press` o aperta, como um dedo faria, e a linha de status que aparece é encontrada pelo papel.

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npm test

> planner@1.0.0 test
> jest

PASS __tests__/planner.test.ts
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/App.test.tsx

Test Suites: 3 passed, 3 total
Tests:       7 passed, 7 total
Snapshots:   0 total
Time:        1.117 s, estimated 2 s
Ran all test suites.
```

## Conferida num navegador

Exporte o build web de novo, sirva-o como na aula 3, e leia-o:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done"
- list:
  - listitem:
    - button "Spanish A2 2 sessions planned"
  - listitem:
    - button "Statistics 2 sessions planned"
  - listitem:
    - button "Guitar 2 sessions planned"
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --click 'Guitar 2 sessions planned'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done"
- list:
  - listitem:
    - button "Spanish A2 2 sessions planned"
  - listitem:
    - button "Statistics 2 sessions planned"
  - listitem:
    - button "Guitar 2 sessions planned"
- status: "Open: Guitar"
```

Compare com o único trecho de texto da aula 3. **Agora há estrutura**: um título, uma lista de três itens,
e em cada um um botão cujo nome é tudo o que uma pessoa precisa para decidir se o aperta. O ícone nem
aparece na árvore, que é o que o `aria-hidden` pediu. O segundo comando apertou *Guitar*, e a linha de
status que apareceu é lida como `status`, que um leitor de tela anuncia sem mudar o lugar do usuário.

**O total da semana continua sendo texto simples**, a linha entre o título e a lista. Isso está certo por
enquanto. É um fato que a tela afirma, não algo para apertar ou para onde pular; a aula 9 o faz mudar
quando uma sessão é marcada como feita, e a aula 11 garante que um leitor de tela ouça que mudou.
