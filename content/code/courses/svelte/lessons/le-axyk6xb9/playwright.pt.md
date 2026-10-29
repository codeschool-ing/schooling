---
title: Playwright, e o planner num navegador de verdade
version: 1
---

**Um teste de ponta a ponta inicia a aplicação de verdade e a usa por um navegador de verdade**, como o
`look` fez o curso todo, só que confere o que encontra em vez de imprimir. O Playwright, sobre o qual o
`look` foi feito, tem um executor de testes próprio. Instale-o, na versão que o `look` usa, para que ele
ache o navegador que a aula 1 instalou e não precise baixar nada:

```
ana@dev:~/planner$ npm install --save-dev @playwright/test@1.63.0

added 3 packages, removed 1 package, and audited 77 packages in 1s

17 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## Uma cópia dos dados para os testes

Os testes vão acrescentar sessões, e não podem acrescentá-las ao planner que você usa de fato. O módulo
do servidor ganha uma mudança: o nome do arquivo de dados pode vir de uma variável de ambiente, que o
servidor dos testes define e nada mais define. Substitua o `src/lib/server/planner.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/server/planner.ts", "parts": [
 {"code": "// planner.ts: the planner's data, read from and written to the file the server keeps it in.\nimport { readFile, writeFile, rename } from 'node:fs/promises';\nimport type { PlannerData, Session } from '#lib/types.js';\n"},
 {"code": "// The data file: PLANNER_FILE when it is set, as the end-to-end tests set it.\nconst FILE = process.env.PLANNER_FILE ?? 'data/planner.json';\nexport async function readPlanner(): Promise<PlannerData> {\n\treturn JSON.parse(await readFile(FILE, 'utf8'));\n}\n\n// Changes run one at a time: each waits for the one before it to finish, so two\n// requests arriving together cannot both read the old file and lose a change.\nlet queue: Promise<unknown> = Promise.resolve();\n\nfunction change<T>(edit: (planner: PlannerData) => T): Promise<T> {\n\tconst result = queue.then(async () => {\n\t\tconst planner = await readPlanner();\n\t\tconst answer = edit(planner);\n\t\t// Write a new file and then put it in the old one's place, so that a crash\n\t\t// halfway through leaves the old file whole rather than half of a new one.\n\t\tawait writeFile(`${FILE}.new`, JSON.stringify(planner, null, '\\t') + '\\n');\n\t\tawait rename(`${FILE}.new`, FILE);\n\t\treturn answer;\n\t});\n\tqueue = result.catch(() => {});\n\treturn result;\n}\n\n/** Add a session; false if there is no such course. */\nexport function addSession({ course, date, minutes }: Omit<Session, 'id' | 'done'>) {\n\treturn change((planner) => {\n\t\tif (!planner.courses.some((c) => c.id === course)) return false;\n\t\tconst id = Math.max(0, ...planner.sessions.map((s) => s.id)) + 1;\n\t\tplanner.sessions.push({ id, course, date, minutes, done: false });\n\t\treturn true;\n\t});\n}\n\n/** Mark a session done or not done; the session, or undefined if there is none. */\nexport function setDone(id: number, done: boolean) {\n\treturn change((planner) => {\n\t\tconst session = planner.sessions.find((s) => s.id === id);\n\t\tif (session) session.done = done;\n\t\treturn session;\n\t});\n}", "note": "O `process.env` guarda as variáveis de ambiente com que o Node foi iniciado. Sem ela, o planner usa o próprio arquivo, como antes."}
]}
```

O Playwright escreve os resultados em duas pastas, que não pertencem ao Git:

```
ana@dev:~/planner$ printf '/test-results\n/playwright-report\n' >> .gitignore
```

## A configuração

Salve isto como `playwright.config.ts`, na raiz do projeto:

```schooling-example
{"language": "typescript", "file": "playwright.config.ts", "parts": [
 {"code": "// playwright.config.ts: build the planner, start it on a copy of the data, and test it in Chromium.\nimport { defineConfig } from '@playwright/test';\n\nexport default defineConfig({\n\ttestDir: 'e2e',"},
 {"code": "\twebServer: {\n\t\tcommand: 'npm run build && cp data/planner.json build/planner-e2e.json && node build',\n\t\tport: 4173,", "note": "O `webServer` é como o Playwright inicia o planner antes dos testes e o para depois. O comando faz o build, copia os dados para dentro de `build`, que o Git ignora, e inicia o servidor do build sobre essa cópia."},
 {"code": "\t\treuseExistingServer: false,", "note": "Um servidor que já estivesse rodando, de uma execução anterior, ainda guardaria as sessões que aqueles testes acrescentaram. Iniciar um novo a cada vez faz toda execução começar dos mesmos dados."},
 {"code": "\t\tenv: {\n\t\t\tPORT: '4173',\n\t\t\tORIGIN: 'http://localhost:4173',\n\t\t\tPLANNER_FILE: 'build/planner-e2e.json'\n\t\t}\n\t},\n\tuse: {\n\t\tbaseURL: 'http://localhost:4173'\n\t}\n});", "note": "As variáveis que o build e o servidor leem: a porta, a origem com que a checagem de CSRF da aula 15 compara, e o arquivo de dados."}
]}
```

## Os testes

Salve isto como `e2e/planner.test.ts`:

```schooling-example
{"language": "typescript", "file": "e2e/planner.test.ts", "parts": [
 {"code": "// planner.test.ts: the planner in a real browser, as a person uses it.\nimport { expect, test } from '@playwright/test';\n"},
 {"code": "test('the week page shows the week of the newest session', async ({ page }) => {\n\tawait page.goto('/');\n\tawait expect(page.getByText('Week of 19 Oct 2026')).toBeVisible();\n\tawait expect(page.getByText('225 minutes this week (3 h 45 min)')).toBeVisible();\n});\n", "note": "O `page` é uma aba do navegador, aberta para este teste e fechada depois dele. `getByText`, `getByRole` e `getByLabel` acham elementos do jeito que o `look` os nomeia: pelo que uma pessoa, ou um leitor de tela, vê."},
 {"code": "test('a session added on a course page is on the page and in the week', async ({ page }) => {\n\tawait page.goto('/courses/guitar?week=2026-10-19');\n\tawait page.getByLabel('Date').fill('2026-10-21');\n\tawait page.getByRole('button', { name: 'Add session' }).click();\n\tawait expect(page.getByText('21 Oct 2026, 30 min')).toBeVisible();\n\n\tawait page.getByRole('link', { name: 'Study planner' }).click();\n\tawait expect(page.getByText('255 minutes this week')).toBeVisible();\n});\n", "note": "O `expect(...).toBeVisible()` espera, até cinco segundos, o elemento aparecer. É isso que torna um teste assim confiável: ele espera a resposta em vez de adivinhar quanto tempo o servidor leva."},
 {"code": "test('a wrong number of minutes is refused with a message', async ({ page }) => {\n\tawait page.goto('/courses/guitar?week=2026-10-19');\n\tawait page.getByLabel('Date').fill('2026-10-22');\n\tawait page.getByLabel('Minutes').fill('3');\n\t// The browser would refuse three minutes itself. Switch its checks off for this form,\n\t// so that the server's are the ones being tested.\n\tawait page.getByRole('button', { name: 'Add session' }).evaluate((button) => {\n\t\t(button as HTMLButtonElement).form!.noValidate = true;\n\t});\n\tawait page.getByRole('button', { name: 'Add session' }).click();\n\tawait expect(page.getByRole('alert')).toHaveText('Minutes must be a whole number from 5 to 600.');\n});\n", "note": "O navegador recusaria três minutos antes de enviar o formulário. Este teste é sobre a checagem do servidor, então desliga a do navegador para este formulário."},
 {"code": "test.describe('with JavaScript off', () => {\n\ttest.use({ javaScriptEnabled: false });\n\n\ttest('a session can still be added', async ({ page }) => {\n\t\tawait page.goto('/courses/spanish?week=2026-10-19');\n\t\tawait page.getByLabel('Date').fill('2026-10-23');\n\t\tawait page.getByRole('button', { name: 'Add session' }).click();\n\t\tawait expect(page).toHaveURL(/\\/courses\\/spanish\\?week=2026-10-19$/);\n\t\tawait expect(page.getByText('23 Oct 2026, 30 min')).toBeVisible();\n\t});\n\n\ttest('the week moves with a link', async ({ page }) => {\n\t\tawait page.goto('/');\n\t\tawait page.getByRole('link', { name: 'Previous week' }).click();\n\t\tawait expect(page.getByText('Week of 12 Oct 2026')).toBeVisible();\n\t});\n});", "note": "O `test.use` muda o navegador para os testes deste grupo: JavaScript desligado, pela promessa da aula 14."}
]}
```

e um script para ele:

```
ana@dev:~/planner$ npm pkg set scripts.test:e2e='playwright test'
```

```
ana@dev:~/planner$ npm run test:e2e

> planner@0.0.1 test:e2e
> playwright test


Running 5 tests using 1 worker

  ✓  1 e2e/planner.test.ts:4:1 › the week page shows the week of the newest session (293ms)
  ✓  2 e2e/planner.test.ts:10:1 › a session added on a course page is on the page and in the week (430ms)
  ✓  3 e2e/planner.test.ts:20:1 › a wrong number of minutes is refused with a message (301ms)
  ✓  4 e2e/planner.test.ts:36:2 › with JavaScript off › a session can still be added (259ms)
  ✓  5 e2e/planner.test.ts:44:2 › with JavaScript off › the week moves with a link (194ms)

  5 passed (7.4s)
```

**Cinco testes, num navegador de verdade, contra o planner do build**, em poucos segundos. Os dois do
fim são os que nenhum outro tipo de teste consegue escrever: eles abrem o planner com o JavaScript
desligado, acrescentam uma sessão e mudam a semana, e só passam se os formulários e os links da aula 14
ainda funcionarem sozinhos. Uma mudança que, sem alarde, fizesse o planner depender de JavaScript de
novo, um botão que só funciona com um handler de clique, um formulário enviado com `fetch` e sem
`action`, faria os dois falharem na execução seguinte, muito antes de alguém com uma conexão lenta notar.
