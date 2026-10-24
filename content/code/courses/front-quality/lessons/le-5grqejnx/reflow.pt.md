---
title: Com zoom, e numa tela estreita
version: 1
---

**As pessoas aumentam as páginas, e muito.** O 1.4.4 *Redimensionar texto*, nível AA, pede que o texto possa ficar duas vezes maior sem perder conteúdo
nem função. O 1.4.10 *Refluxo*, nível AA, pede que com **320 pixels CSS** de largura a página funcione sem
rolar de lado, a não ser o que precisa de duas dimensões, como um mapa ou uma tabela de dados. 320 não é um celular qualquer: é o que uma tela de 1280 pixels de
largura vira com zoom de 400%, então uma página que reflui em 320 também sobrevive ao zoom que alguém com
baixa visão usa todo dia.

```typescript
// e2e/display.spec.ts, below what is there
test("at 320 pixels wide, nothing scrolls sideways", async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 640 });
  for (const address of ["/", "/#/course/javascript"]) {
    await page.goto(address);
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth), address).toBeLessThanOrEqual(320);
  }
});
```

O `scrollWidth` é a largura do documento, desenhado; um valor maior que a largura da janela é uma página
que rola de lado. O segundo argumento do `expect` é impresso junto com uma falha, então ele diz qual página
falhou.

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts -g '320' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/display.spec.ts:28:1 › at 320 pixels wide, nothing scrolls sideways (283ms)
    Expected: <= 320
    Received:    473
  1 failed
```

A lista de cursos cabe; a página de curso tem 473 pixels de largura. O formulário põe os três campos e o
botão numa linha só com `display: flex`, e uma linha que não pode quebrar é tão larga quanto o que está
nela. **Uma propriedade a deixa quebrar:**

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index f02dc1e..a07fbf4 100644
--- a/src/style.css
+++ b/src/style.css
@@ -27,7 +27,7 @@ li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
 .session.done { color: var(--done); }
 .tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }
 :focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
-.add { display: flex; gap: 0.5rem; margin: 1rem 0; }
+.add { display: flex; flex-wrap: wrap; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; }
 @media (prefers-reduced-motion: no-preference) {
   .week { animation: pulse 1s ease-in-out 3; }
```

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (343ms)
  ✓  2 [chromium] › e2e/display.spec.ts:21:1 › with reduced motion asked for, nothing on the page moves (242ms)
  ✓  3 [chromium] › e2e/display.spec.ts:28:1 › at 320 pixels wide, nothing scrolls sideways (216ms)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "Add session: 89×21",
    + ]
  1 failed
  2 passed (4.8s)
```

**O teste do refluxo passa, e o teste de alvo falha: o *Add session* tem 21 pixels de altura.** Quebrar o
formulário pôs o botão numa linha só dele, na altura dele, onde antes ele era esticado até a do textarea.
Nada no botão mudou, e o piso em que ele se apoiava era um acaso do layout. É por isso que o teste mede todo
botão e não só aquele de que a correção tratava, e por isso que o teste de cada critério roda com todos os
outros. O piso pertence a todo botão, então ele vai para o `button`:

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index f02dc1e..cdb5b63 100644
--- a/src/style.css
+++ b/src/style.css
@@ -25,9 +25,10 @@ li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
 .courses img { vertical-align: middle; margin-right: 0.4rem; }
 .mins { color: var(--quiet); }
 .session.done { color: var(--done); }
-.tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }
+button { min-width: 24px; min-height: 24px; }
+.tick { font-size: 0.7rem; padding: 2px 8px; }
 :focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
-.add { display: flex; gap: 0.5rem; margin: 1rem 0; }
+.add { display: flex; flex-wrap: wrap; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; }
 @media (prefers-reduced-motion: no-preference) {
   .week { animation: pulse 1s ease-in-out 3; }
```

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (290ms)
  ✓  2 [chromium] › e2e/display.spec.ts:21:1 › with reduced motion asked for, nothing on the page moves (179ms)
  ✓  3 [chromium] › e2e/display.spec.ts:28:1 › at 320 pixels wide, nothing scrolls sideways (200ms)
  3 passed (3.7s)
```

Teste também à mão, no navegador: dê zoom de 400% com Ctrl e +, ou Cmd e + num Mac, numa janela de 1280
pixels de largura, e leia a página de curso de cima a baixo sem rolar de lado.
