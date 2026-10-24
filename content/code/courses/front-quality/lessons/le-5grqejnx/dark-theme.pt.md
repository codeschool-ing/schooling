---
title: Um tema escuro é uma segunda paleta
version: 1
---

**Um tema escuro não é o claro invertido; é um segundo conjunto de cores, e cada par nele precisa passar de
novo.** É por isso que a plataforma em que você está lendo isto roda o axe nos dois temas, e o planner está
prestes a precisar do mesmo.

O navegador diz qual a pessoa pediu, nos ajustes do sistema dela, pela media query `prefers-color-scheme`.
Uma folha de estilo que guarda as cores em propriedades personalizadas pode responder a ela redefinindo-as
uma vez. Reescreva o `src/style.css` desse jeito:

```css
/* src/style.css */
:root {
  color-scheme: light dark;
  --text: #1d1d1d;
  --page: #ffffff;
  --link: #2f6f4e;
  --quiet: #555555;
  --done: #6b6b6b;
  --line: #dddddd;
}
@media (prefers-color-scheme: dark) {
  :root {
    --text: #e6e6e6;
    --page: #161616;
    --quiet: #a3a3a3;
    --done: #8f8f8f;
    --line: #3a3a3a;
  }
}
body { font-family: system-ui, sans-serif; margin: 2rem auto; max-width: 36rem; padding: 0 1rem; color: var(--text); background: var(--page); }
a { color: var(--link); }
ul { padding: 0; list-style: none; }
li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
.courses img { vertical-align: middle; margin-right: 0.4rem; }
.mins { color: var(--quiet); }
.session.done { color: var(--done); }
.tick { font-size: 0.7rem; padding: 1px 4px; }
:focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
.add { display: flex; gap: 0.5rem; margin: 1rem 0; }
.week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
@keyframes pulse { 50% { transform: scale(1.06); } }
.note { white-space: pre-line; margin: 0.2rem 0 0; }
```

O `color-scheme: light dark` diz ao navegador que a página pode ser desenhada dos dois jeitos, então as
partes dele, os botões, os campos, as barras de rolagem, seguem o tema também. O verde fica como estava, do
jeito que uma primeira passada costuma deixar a cor que parecia boa na tela em que foi escolhida.

## Dois testes, de dois lados

**O primeiro pede a paleta**: o valor de cada propriedade personalizada, como o navegador a resolveu em cada
esquema, passado pela aritmética da última seção. É um teste do Playwright, porque só um navegador sabe que
bloco da folha de estilo vale; o Vitest não processa CSS a menos que mandem, e um arquivo CSS importado
num teste de unidade chega como texto vazio. Salve como `e2e/palette.spec.ts`:

```typescript
// e2e/palette.spec.ts
import { expect, test } from "@playwright/test";
import { contrast } from "../src/contrast";

const text = ["text", "link", "quiet", "done"];

for (const colorScheme of ["light", "dark"] as const) {
  test(`every text colour of the ${colorScheme} palette reaches 4.5:1 on the page`, async ({ page }) => {
    await page.emulateMedia({ colorScheme });
    await page.goto("/");
    const colours = await page.evaluate((names) => {
      const style = getComputedStyle(document.documentElement);
      return Object.fromEntries(names.map((n) => [n, style.getPropertyValue(`--${n}`).trim()]));
    }, ["page", ...text]);
    const short = text
      .map((n) => [n, contrast(colours[n], colours.page)] as const)
      .filter(([, ratio]) => !(ratio >= 4.5))
      .map(([n, ratio]) => `--${n}: ${ratio.toFixed(2)}:1`);
    expect(short).toEqual([]);
  });
}
```

O `page.emulateMedia` faz a página ver o esquema que recebe, e o teste importa o `contrast` direto de
`src/`, porque o Playwright também compila TypeScript. Uma propriedade que falta é lida como texto vazio, a
razão dela é `NaN`, e `!(NaN >= 4.5)` é verdadeiro, então uma cor que não está lá é relatada em vez de
passar em silêncio.

```
ana@dev:~/planner$ npx playwright test e2e/palette.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/palette.spec.ts:8:3 › every text colour of the light palette reaches 4.5:1 on the page (216ms)
  ✘  2 [chromium] › e2e/palette.spec.ts:8:3 › every text colour of the dark palette reaches 4.5:1 on the page (248ms)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "--link: 3.02:1",
    + ]
  1 failed
  1 passed (4.7s)
```

**O segundo pergunta à página, em cada tema.** A opção `colorScheme` do Playwright faz o navegador informar
o esquema que recebe. No `e2e/a11y.spec.ts`, o laço sobre as páginas vira um laço sobre as páginas e os dois
esquemas:

```
ana@dev:~/planner$ git diff e2e/a11y.spec.ts
diff --git a/e2e/a11y.spec.ts b/e2e/a11y.spec.ts
index 241c893..3f2ad80 100644
--- a/e2e/a11y.spec.ts
+++ b/e2e/a11y.spec.ts
@@ -8,12 +8,17 @@ const pages = [
   ["a course page", "/#/course/javascript"],
 ];
 
-for (const [name, address] of pages) {
-  test(`${name} breaks no WCAG 2.2 AA rule axe can check`, async ({ page }) => {
-    await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
-    await page.goto(address);
-    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
-    const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
-    expect(violations.map((v) => `${v.id}: ${v.nodes.length}`)).toEqual([]);
+for (const colorScheme of ["light", "dark"] as const) {
+  test.describe(`${colorScheme} theme`, () => {
+    test.use({ colorScheme });
+    for (const [name, address] of pages) {
+      test(`${name} breaks no WCAG 2.2 AA rule axe can check`, async ({ page }) => {
+        await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
+        await page.goto(address);
+        await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
+        const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
+        expect(violations.map((v) => `${v.id}: ${v.nodes.length}`)).toEqual([]);
+      });
+    }
   });
 }
```

```
ana@dev:~/planner$ npx playwright test e2e/a11y.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/a11y.spec.ts:15:7 › light theme › the course list breaks no WCAG 2.2 AA rule axe can check (1.1s)
  ✓  2 [chromium] › e2e/a11y.spec.ts:15:7 › light theme › a course page breaks no WCAG 2.2 AA rule axe can check (1.0s)
  ✘  3 [chromium] › e2e/a11y.spec.ts:15:7 › dark theme › the course list breaks no WCAG 2.2 AA rule axe can check (1.2s)
  ✘  4 [chromium] › e2e/a11y.spec.ts:15:7 › dark theme › a course page breaks no WCAG 2.2 AA rule axe can check (1.3s)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "color-contrast: 3",
    + ]
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "color-contrast: 1",
    + ]
  2 failed
  2 passed (9.2s)
```

**Os dois dizem a mesma coisa de dois lados.** O verde do planner, `#2f6f4e`, chega a 5,99:1 sobre o
branco e a 3,02:1 sobre `#161616`. O teste da paleta nomeia a cor; o axe nomeia os elementos, o link de
voltar na página de curso e os três links de curso na lista. Um verde para a página escura, escolhido com a
aritmética, chega a 8,71:1, e vai para o bloco escuro:

```
ana@dev:~/planner$ sed -n '/prefers-color-scheme: dark/,/^}/p' src/style.css
@media (prefers-color-scheme: dark) {
  :root {
    --text: #e6e6e6;
    --page: #161616;
    --link: #6fc596;
    --quiet: #a3a3a3;
    --done: #8f8f8f;
    --line: #3a3a3a;
  }
}
```

```
ana@dev:~/planner$ npx playwright test e2e/palette.spec.ts e2e/a11y.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/palette.spec.ts:8:3 › every text colour of the light palette reaches 4.5:1 on the page (279ms)
  ✓  3 [chromium] › e2e/palette.spec.ts:8:3 › every text colour of the dark palette reaches 4.5:1 on the page (214ms)
  ✓  2 [chromium] › e2e/a11y.spec.ts:15:7 › light theme › the course list breaks no WCAG 2.2 AA rule axe can check (1.2s)
  ✓  4 [chromium] › e2e/a11y.spec.ts:15:7 › light theme › a course page breaks no WCAG 2.2 AA rule axe can check (965ms)
  ✓  5 [chromium] › e2e/a11y.spec.ts:15:7 › dark theme › the course list breaks no WCAG 2.2 AA rule axe can check (966ms)
  ✓  6 [chromium] › e2e/a11y.spec.ts:15:7 › dark theme › a course page breaks no WCAG 2.2 AA rule axe can check (998ms)
  6 passed (7.5s)
ana@dev:~/planner$ git add -A && git commit -qm "A dark theme, its palette and its pages tested in both schemes"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l13-pairs\" aria-label=\"Quatro pares de cores desenhados como texto sobre o seu fundo, cada um com a sua razão. Tema claro: #aaaaaa sobre branco, 2,32 para 1, falha; #6b6b6b sobre branco, 5,33 para 1, passa. Tema escuro: o verde do tema claro, #2f6f4e, sobre #161616, 3,02 para 1, falha; #6fc596 sobre #161616, 8,71 para 1, passa. Uma nota diz que o AA pede 4,5 para 1 para texto.\"><text x=\"190\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">tema claro</text><text x=\"530\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">tema escuro</text><rect x=\"30\" y=\"36\" width=\"150\" height=\"64\" rx=\"4\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" fill=\"#aaaaaa\">Done</text><text x=\"105\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#aaaaaa / #ffffff</text><text x=\"105\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">2,32:1</text><text x=\"105\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">falha</text><rect x=\"202\" y=\"36\" width=\"150\" height=\"64\" rx=\"4\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"277\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" fill=\"#6b6b6b\">Done</text><text x=\"277\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#6b6b6b / #ffffff</text><text x=\"277\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">5,33:1</text><text x=\"277\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">passa</text><rect x=\"374\" y=\"36\" width=\"150\" height=\"64\" rx=\"4\" fill=\"#161616\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"449\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" fill=\"#2f6f4e\">Done</text><text x=\"449\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#2f6f4e / #161616</text><text x=\"449\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">3,02:1</text><text x=\"449\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">falha</text><rect x=\"546\" y=\"36\" width=\"150\" height=\"64\" rx=\"4\" fill=\"#161616\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"621\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" fill=\"#6fc596\">Done</text><text x=\"621\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#6fc596 / #161616</text><text x=\"621\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">8,71:1</text><text x=\"621\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">passa</text><text x=\"690\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">AA para texto: 4,5:1</text></svg>", "caption": "As duas falhas que este curso encontrou e as duas cores que as substituíram. Uma cor que passa num fundo pode falhar no outro: o verde é o mesmo numa falha e num acerto.", "same": ["Done"]}
```

O anel de foco também usa o `--link`, então mudou junto: 3,02:1 teria atendido os 3:1 de que um anel
precisa, por pouco, e 8,71:1 os atende com folga.
