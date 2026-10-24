---
title: Movimento que alguém pediu para não ver
version: 1
---

**Para algumas pessoas, movimento numa página não é decoração; é enjoo.** Distúrbios vestibulares fazem o
senso de equilíbrio do ouvido interno discordar do que os olhos informam, e um zoom, uma rolagem em
paralaxe ou um pulso podem trazer uma tontura que dura horas. Todo sistema importante tem um ajuste para
isso, *Reduzir movimento* no macOS e no iOS, *Efeitos de animação* no Windows, *Remover animações* no
Android, e o navegador o repassa à página como a media query `prefers-reduced-motion: reduce`.

O total da semana do planner pulsa três vezes quando a página é desenhada, desde a folha de estilo da aula
1. Os critérios são o 2.3.3 *Animação a partir de interações*, no AAA, e, para o que se move sozinho por
mais de cinco segundos, o 2.2.2 *Pausar, parar, ocultar*, no A. Três segundos de pulso ficam abaixo das
duas barras no AA, e o ajuste continua sendo um pedido que alguém fez; atendê-lo custa uma media query.

```typescript
// e2e/display.spec.ts, below what is there
test("with reduced motion asked for, nothing on the page moves", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  expect(await page.evaluate(() => document.getAnimations().map((a) => (a as CSSAnimation).animationName))).toEqual([]);
});
```

O `document.getAnimations()` lista toda animação rodando no documento, as de CSS incluídas, e cada animação
CSS leva o nome do seu `@keyframes`, então uma falha diz qual se moveu.

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts -g 'reduced motion' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/display.spec.ts:21:1 › with reduced motion asked for, nothing on the page moves (269ms)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "pulse",
    + ]
  1 failed
```

A correção põe a animação dentro de uma query que só casa quando ninguém pediu menos, de modo que o padrão
continua sendo o pulso e o pedido o tira:

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index c47851f..f02dc1e 100644
--- a/src/style.css
+++ b/src/style.css
@@ -28,6 +28,9 @@ li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
 .tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }
 :focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
-.week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
+.week { font-weight: bold; }
+@media (prefers-reduced-motion: no-preference) {
+  .week { animation: pulse 1s ease-in-out 3; }
+}
 @keyframes pulse { 50% { transform: scale(1.06); } }
 .note { white-space: pre-line; margin: 0.2rem 0 0; }
```

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (301ms)
  ✓  2 [chromium] › e2e/display.spec.ts:21:1 › with reduced motion asked for, nothing on the page moves (170ms)
  2 passed (3.6s)
ana@dev:~/planner$ git commit -qam "No pulse for somebody who asked for less motion"
```

**`no-preference` em vez de `reduce`** é o lado mais seguro: um navegador que não conhece a query não casa
com nenhuma das duas, e fica sem animação. O contrário, uma animação em toda parte e um bloco `reduce` que
a tira, dá a animação a todo mundo cujo navegador não repassa o ajuste.
