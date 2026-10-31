---
title: Testes, sem celular
version: 1
---

**O Jest roda os seus componentes no Node.js, sem tela.** O `jest-expo` o configura para um projeto Expo,
incluindo substitutos para os módulos nativos que não existem no Node, e a React Native Testing Library
renderiza componentes, encontra elementos pelo que uma pessoa vê (um texto, um papel, um rótulo) e os
aperta. Toda aula da 4 à 19 confere o próprio trabalho assim, porque é rápido, exato, e roda em qualquer
computador.

## Dois arquivos de teste

O primeiro testa as regras, que não precisam de renderização nenhuma. Salve-o como
`__tests__/planner.test.ts`:

```typescript
// __tests__/planner.test.ts: the rules, checked with no screen at all.
import data from "../src/courses.json";
import { addSession, markDone, mondayOf, weekTotal, type Plan } from "../src/planner";

const plan: Plan = data;

test("a week starts on Monday", () => {
  expect(mondayOf("2026-10-21")).toBe("2026-10-19");
  expect(mondayOf("2026-10-25")).toBe("2026-10-19");
});

test("the week's total counts planned and done minutes", () => {
  expect(weekTotal(plan, "2026-10-19")).toEqual({ planned: 125, done: 75 });
});

test("marking a session done moves the done total", () => {
  expect(weekTotal(markDone(plan, "s3"), "2026-10-19").done).toBe(95);
});

test("a session for a course that does not exist is refused", () => {
  expect(() => addSession(plan, "chemistry", "2026-10-23", 30)).toThrow("no course chemistry");
});
```

O segundo renderiza o app inteiro e o lê. Salve-o como `__tests__/App.test.tsx`:

```tsx
// __tests__/App.test.tsx: the first screen, rendered with no phone and no browser.
import { render, screen } from "@testing-library/react-native";
import App from "../App";

test("the first screen shows this week's total", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(<App />);
  expect(screen.getByRole("heading")).toHaveTextContent("Study planner");
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
});
```

O `render` é aguardado porque a React Native Testing Library 14 renderiza do jeito que o React faz num
app, de forma assíncrona. O `jest.useFakeTimers({ now })` troca o relógio, então o teste vê a semana do
curso seja qual for o dia em que roda; sem isso, o `src/today.ts` lê a data real e o total muda toda
segunda-feira. O `getByRole("heading")` encontra o elemento cujo papel é título, como um leitor de tela
faria, e falha se não houver nenhum ou houver mais de um.

**O TypeScript também precisa ser avisado sobre o Jest.** `test` e `expect` são globais que o Jest
fornece, e o TypeScript 6 só carrega os tipos globais de um pacote quando o projeto o cita. Sem isso, o
`npx tsc --noEmit` aponta cada `test` da pasta como um nome que não encontra. Deixe o `tsconfig.json`
assim:

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "types": ["jest"]
  }
}
```

E confira o projeto inteiro de novo, testes incluídos:

```
ana@dev:~/planner$ npx tsc --noEmit
```

## Rodando

O Jest precisa ser avisado para usar o preset. Acrescente estas duas entradas ao `package.json` com o
npm, que edita o arquivo por você:

```sh
npm pkg set scripts.test=jest jest.preset=jest-expo
```

Depois:

```
ana@dev:~/planner$ npm pkg get scripts.test jest
{
  "scripts.test": "jest",
  "jest": {
    "preset": "jest-expo"
  }
}
ana@dev:~/planner$ npm test

> planner@1.0.0 test
> jest

PASS __tests__/planner.test.ts
PASS __tests__/App.test.tsx

Test Suites: 2 passed, 2 total
Tests:       5 passed, 5 total
Snapshots:   0 total
Time:        1.07 s, estimated 2 s
Ran all test suites.
```

Cinco testes em dois arquivos, todos passando, em cerca de um segundo. **Um teste que renderiza o app e
encontra o total prova mais do que uma captura de tela provaria**: prova que o número é calculado a
partir dos dados, que o título é anunciado como título, e vai dizer isso no dia em que um dos dois
deixar de ser verdade.

Quando um teste falha, o Jest imprime o que esperava, o que recebeu, e a linha. Troque `125` por `120`
no primeiro arquivo e rode `npm test` de novo para ver um; depois desfaça a troca.
