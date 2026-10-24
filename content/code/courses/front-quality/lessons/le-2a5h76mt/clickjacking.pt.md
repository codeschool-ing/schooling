---
title: Clickjacking, e a linha que já o impede
version: 1
---

**O clickjacking põe uma página real dentro de outra, invisível, para a pessoa clicar num botão da página
real enquanto olha para a outra.** O planner logado, um botão Done posto debaixo de algo que diz *resgate
o seu prêmio*: o clique é verdadeiro, da pessoa, no planner, com o cookie dela, e nenhuma falsificação de
requisição é necessária porque nada é falsificado.

A defesa é uma linha, e o planner a tem desde a aula 8: **`frame-ancestors 'none'`** na Content Security
Policy, que diz ao navegador que nenhuma página pode pôr esta num frame. O cabeçalho mais antigo
`X-Frame-Options: DENY` diz o mesmo aos navegadores que não leem a diretiva, e todo navegador atual a lê.
O que falta ao planner é um teste de que a linha funciona, então eis um, com um controle ao lado. Salve
isto como `e2e/frame.spec.ts`:

```typescript
// e2e/frame.spec.ts
import { expect, test, type Page } from "@playwright/test";

async function framedBy(page: Page, address: string): Promise<string> {
  await page.setContent(`<h1>another site</h1><iframe src="${address}"></iframe>`);
  return page.frames()[1].url();
}

test("another site cannot put the built planner in a frame", async ({ page }) => {
  expect(await framedBy(page, "http://localhost:4173/")).toBe("chrome-error://chromewebdata/");
});

test("without the policy, the same frame loads: the control", async ({ page }) => {
  expect(await framedBy(page, "http://localhost:5173/")).toBe("http://localhost:5173/");
});
```

O `setContent` dá ao teste uma página que não pertence a site nenhum, no lugar de um outro site, com um
frame do planner. Quando um frame é recusado, o Chromium mostra a própria página de erro dentro dele, e o
endereço dela é `chrome-error://chromewebdata/`; esse endereço é do Chromium e o teste diz isso ao
nomeá-lo.

**O segundo teste é um controle.** Ele põe num frame o servidor de desenvolvimento, que não manda
política, e espera o frame carregar. Se ele algum dia falhasse, a aprovação do primeiro teste não
quereria dizer nada, porque um frame que não carrega por qualquer outro motivo também nunca mostra o
planner.

```
ana@dev:~/planner$ npx playwright test e2e/frame.spec.ts --reporter=list

Running 2 tests using 1 worker

  ✓  1 [chromium] › e2e/frame.spec.ts:9:1 › another site cannot put the built planner in a frame (114ms)
  ✓  2 [chromium] › e2e/frame.spec.ts:13:1 › without the policy, the same frame loads: the control (166ms)

  2 passed (3.7s)
```

Faça o commit:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Test that no other site can frame the built planner"
```
