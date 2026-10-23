---
title: Os mesmos testes no Jest
version: 1
---

**O Jest é o executor que a maioria dos projetos JavaScript usava antes do Vitest.** Os testes se
leem quase iguais nele, e o que muda é tudo em volta deles. Você vai encontrá-lo em projetos
existentes, então esta seção roda o `planner.test.ts` no Jest 30.5.2 numa pasta só dele,
`~/planner-jest`, ao lado do planner e não dentro, para os dois executores nunca pegarem os arquivos
um do outro.

```
ana@dev:~$ mkdir planner-jest
ana@dev:~$ cd planner-jest
ana@dev:~/planner-jest$ npm init -y > /dev/null
ana@dev:~/planner-jest$ npm pkg set type=module
ana@dev:~/planner-jest$ npm install --save-exact -D jest@30.5.2 @jest/globals@30.5.2 ts-jest@29.4.15 typescript@6.0.3
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me

added 291 packages, and audited 292 packages in 5s

found 0 vulnerabilities
ana@dev:~/planner-jest$ cp ../planner/src/planner.ts ../planner/public/courses.json .
```

O Jest roda JavaScript. Para ler TypeScript ele precisa de um transformador, e o `ts-jest` é o que
roda o compilador do TypeScript; ele traz a sua própria cópia do `typescript`, fixada como a do
planner. O teste é o do planner, com uma linha trocada, porque as funções do Jest vêm de
`@jest/globals` e não de `vitest`, e os dados agora ficam ao lado dele:

```typescript
// planner.test.ts
import { describe, expect, test } from "@jest/globals";
import { weekOf, weekTotal, type Plan } from "./planner";
import data from "./courses.json";

const plan: Plan = data;

describe("weekOf", () => {
  test("a Wednesday's week runs from the Monday before to the Sunday after", () => {
    expect(weekOf("2026-10-21")).toEqual(["2026-10-19", "2026-10-25"]);
  });
});

describe("weekTotal", () => {
  test("adds every session of the week, done or not", () => {
    expect(weekTotal(plan, "2026-10-21")).toBe(160);
  });
});
```

E um arquivo para dizer ao Jest qual transformador usar. Salve-o como `jest.config.js`:

```javascript
// jest.config.js
export default {
  preset: "ts-jest",
  testEnvironment: "node",
};
```

```
ana@dev:~/planner-jest$ npx jest
ts-jest[config] (WARN) message TS151001: If you have issues related to imports, you should consider setting `esModuleInterop` to `true` in your TypeScript configuration file (usually `tsconfig.json`). See https://blogs.msdn.microsoft.com/typescript/2018/01/31/announcing-typescript-2-7/#easier-ecmascript-module-interoperability for more information.
FAIL ./planner.test.ts
  ● Test suite failed to run

    planner.test.ts:4:18 - error TS7042: Module './courses.json' was resolved to '/home/ana/planner-jest/courses.json', but '--resolveJsonModule' is not used.

    4 import data from "./courses.json";
                       ~~~~~~~~~~~~~~~~

Test Suites: 1 failed, 1 total
Tests:       0 total
Snapshots:   0 total
Time:        1.364 s
Ran all test suites.
```

**Os testes não falharam; o arquivo não compilou.** O ts-jest confere os tipos antes de rodar, e o
TypeScript se recusa a importar um arquivo `.json` a menos que o `resolveJsonModule` esteja ligado. No
planner ele está ligado sem estar escrito, porque o template do Vite põe o `moduleResolution` em
`bundler` e essa configuração o permite; uma pasta sem `tsconfig.json` recebe os padrões antigos do
TypeScript, que não permitem. Essa é a diferença entre os dois executores numa linha: o Vitest usa a
configuração de Vite e TypeScript do projeto, e o Jest é uma segunda configuração que você mantém ao
lado. O aviso acima dela pede o `esModuleInterop` também. Salve isto como `tsconfig.json`:

```json
{
  "compilerOptions": {
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  }
}
```

```
ana@dev:~/planner-jest$ npx jest
Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.333 s
Ran all test suites.
```

O `isolatedModules` diz ao ts-jest para compilar cada arquivo sozinho, que é como o Vite os trata
também.

## O que é igual e o que não é

| | Vitest | Jest |
|---|---|---|
| testes | `describe`, `test`, `expect` de `vitest` | os mesmos nomes, de `@jest/globals` |
| uma função que registra chamadas | `vi.fn()` | `jest.fn()` |
| um relógio parado | `vi.useFakeTimers()`, `vi.setSystemTime()` | `jest.useFakeTimers()`, `jest.setSystemTime()` |
| um documento | `@vitest-environment jsdom` | `@jest-environment jsdom`, com o `jest-environment-jsdom` instalado |
| TypeScript | lido pelo Vite, nada para configurar | um transformador (`ts-jest`, `babel-jest`, `@swc/jest`) e a configuração dele |

**As asserções são a mesma biblioteca em tudo menos no nome**, e é por isso que passar uma suíte de
um para o outro é quase só buscar e substituir. Escolha pelo projeto: um projeto Vite já está
configurado para o Vitest, e uma suíte em Jest que já existe continua funcionando onde está.
