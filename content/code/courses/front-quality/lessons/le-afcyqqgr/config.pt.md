---
title: A configuração, e dois executores num projeto
version: 1
---

**O Playwright Test lê o `playwright.config.ts` na raiz do projeto: onde estão os testes, que
navegador usar, e como subir o app antes do primeiro teste.** Salve isto como `playwright.config.ts`:

```typescript
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "e2e",
  use: {
    baseURL: "http://localhost:5173",
    timezoneId: "America/Sao_Paulo",
    trace: "retain-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    command: "npm run dev",
    url: "http://localhost:5173",
    reuseExistingServer: true,
  },
});
```

- **O `testDir: "e2e"`** deixa os testes de navegador numa pasta só deles, `e2e/`, separados dos testes
  unitários e de componente que ficam ao lado do código em `src/`.
- **O `baseURL`** deixa um teste dizer `page.goto("/")` em vez do endereço inteiro.
- **O `timezoneId`** dá ao navegador um fuso próprio, seja qual for o da máquina. A aula 2 mostrou o
  que um fuso faz com o planner; assim a execução de cada estudante vê a mesma semana.
- **O `trace: "retain-on-failure"`** grava tudo o que um teste que falhou fez, para o visualizador de
  duas seções adiante.
- **O `webServer`** sobe o `npm run dev` e espera a porta 5173 responder antes do primeiro teste; o
  `reuseExistingServer` usa o que já está rodando no seu outro terminal, se houver um.

As pastas de saída do Playwright não são fonte, e o Git não deve guardá-las:

```
ana@dev:~/planner$ printf "test-results\nplaywright-report\n" >> .gitignore
ana@dev:~/planner$ cat .gitignore
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

node_modules
dist
dist-ssr
*.local

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?
coverage
test-results
playwright-report
```

## Dois executores, um projeto

Um arquivo de teste do Playwright é um arquivo `.spec.ts`, e um do Vitest também: o padrão do Vitest
é qualquer coisa que termine em `.test.ts` ou `.spec.ts`. Então, no momento em que `e2e/` tem um teste,
o `npm test` o acha e o roda com o executor errado. A próxima seção escreve o primeiro, e eis o que o
`npm test` diz depois:

```
ana@dev:~/planner$ npm test 2>&1 | head -n 20

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ❯ e2e/planner.spec.ts (0 test)

⎯⎯⎯⎯⎯⎯ Failed Suites 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  e2e/planner.spec.ts [ e2e/planner.spec.ts ]
Error: Playwright Test did not expect test.beforeEach() to be called here.
Most common reasons include:
- You are calling test.beforeEach() in a configuration file.
- You are calling test.beforeEach() in a file that is imported by the configuration file.
- You have two different versions of @playwright/test. This usually happens
  when one of the dependencies in your package.json depends on @playwright/test.
- You are calling test.beforeEach() from an async test.describe() block. Only sync ones are supported.
 ❯ _TestTypeImpl._currentSuite node_modules/playwright/lib/common/index.js:2224:13
```

**Cada executor precisa ser avisado do que não é dele.** O arquivo de configuração do Vite também guarda
as configurações do Vitest. Salve isto como `vite.config.ts`:

```typescript
// vite.config.ts
import { configDefaults, defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    exclude: [...configDefaults.exclude, "e2e/**"],
  },
});
```

O `configDefaults.exclude` é o que o Vitest já deixa de fora, o `node_modules` entre outros; a linha
acrescenta o `e2e/` a ele em vez de substituí-lo.

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner


 Test Files  4 passed (4)
      Tests  27 passed (27)
   Start at  19:53:37
   Duration  1.27s (environment 59%, tests 20%, import 10%, transform 10%, worker 1%)
```
