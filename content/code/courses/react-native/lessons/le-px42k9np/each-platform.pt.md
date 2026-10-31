---
title: Um teste, quatro plataformas
version: 1
---

**Uma diferença que você escreveu é uma diferença que você deve conferir, em cada plataforma.** O
`jest-expo` deixa isso barato: além do preset que o planner usa, que roda cada teste como iOS, ele tem um por
plataforma, e um preset `universal` que roda cada teste uma vez como cada uma delas, iOS, Android, web e
Node.js.

## Um teste que diz onde rodou

Salve isto como `__tests__/platform.test.ts`. Ele importa o estilo do cartão e a frase, e imprime o que cada
plataforma recebeu:

```typescript
// __tests__/platform.test.ts: one test, run once for each platform jest-expo knows.
import { Platform } from "react-native";
import { card } from "../src/card";
import { savedWhere } from "../src/savedWhere";

test("each platform gets its own file and its own shadow", () => {
  const shadow = Object.keys(card).filter((k) => /shadow|elevation/i.test(k));
  console.log(Platform.OS, "|", savedWhere, "|", shadow.join(" "));
  expect(shadow.length).toBeGreaterThan(0);
});
```

O `console.log` está ali para mostrar o resultado na página; um teste seu usaria `expect` nos valores, e este
também confere que toda plataforma recebeu alguma sombra.

## Rodando quatro vezes

O `--config` aceita a configuração como JSON na linha de comando, o que roda o preset universal num comando
só sem mudar o `package.json`; o `platform` escolhe o arquivo:

```
ana@dev:~/planner$ npx jest --config '{"preset":"jest-expo/universal"}' platform
PASS Android __tests__/platform.test.ts
  ● Console

    console.log
      android | Saved on this Android device | elevation

      at Object.log (__tests__/platform.test.ts:8:11)

PASS iOS __tests__/platform.test.ts
  ● Console

    console.log
      ios | Saved on this iPhone | shadowColor shadowOpacity shadowRadius shadowOffset

      at Object.log (__tests__/platform.test.ts:8:11)

PASS Node __tests__/platform.test.ts
  ● Console

    console.log
      web | Saved in this browser | boxShadow

      at Object.log (__tests__/platform.test.ts:8:11)

PASS Web __tests__/platform.test.ts
  ● Console

    console.log
      web | Saved in this browser | boxShadow

      at Object.log (__tests__/platform.test.ts:8:11)


Test Suites: 4 passed, 4 total
Tests:       4 passed, 4 total
Snapshots:   0 total
Time:        1.008 s
Ran all test suites matching platform in 4 projects.
```

**Quatro execuções de um arquivo**, cada uma com o próprio `Platform.OS`, a própria resolução de
`./savedWhere` e o próprio ramo do `Platform.select`. O Android recebeu a `elevation`, o iOS as quatro
propriedades de sombra, e a web e o Node.js o `default`, o `boxShadow`. É a mesma escolha que o Metro fez nos
bundles duas seções atrás, feita aqui pelo resolvedor do Jest configurado do mesmo jeito, que é o que torna o
teste digno de confiança.

## E a suíte inteira, como sempre

A execução comum continua sendo o preset de iOS, agora com o arquivo de setup antes de cada teste:

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npm test

> planner@1.0.0 test
> jest

PASS __tests__/App.test.tsx
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/WeekBar.test.tsx
PASS __tests__/platform.test.ts
  ● Console

    console.log
      ios | Saved on this iPhone | shadowColor shadowOpacity shadowRadius shadowOffset

      at Object.log (__tests__/platform.test.ts:8:11)

PASS __tests__/planner.test.ts

Test Suites: 5 passed, 5 total
Tests:       9 passed, 9 total
Snapshots:   0 total
Time:        1.213 s
Ran all test suites.
```

O teste de plataforma imprime a linha dele aqui também, como iOS. **O teste do App é o que o arquivo de setup
salvou**: sem o substituto, o provider de verdade não renderiza nada no Jest enquanto espera uma medição que
nunca vem, e o teste não encontra título nenhum. Tire a linha do `package.json` e rode `npm test` para vê-lo
falhar assim; depois ponha-a de volta.

## O que isto não substitui

O Jest roda o seu JavaScript com a resolução e as constantes de cada plataforma. Ele não roda o UIKit nem as
views do Android, então uma sombra definida corretamente e que ainda assim fica feia é encontrada num
aparelho. *Conferir a sombra do cartão num celular e num emulador não foi feito para este curso.* O que as
quatro execuções provam é que o código escolheu o que você quis que ele escolhesse, em toda plataforma, toda
vez que os testes rodam.
