---
title: Um alvo grande o bastante para acertar
version: 1
---

**Um controle precisa ser grande o bastante para ser apertado sem apertar o vizinho.** É uma questão para
quem tem tremor, para quem está no celular num ônibus em movimento, para quem tem dedos grandes. O 2.5.8
*Tamanho do alvo (Mínimo)*, nível AA e novo na WCAG 2.2, pede que cada alvo tenha **pelo menos 24 por 24
pixels CSS**, ou que um círculo de 24 pixels em volta do centro dele não toque outro alvo. O 2.5.5, no AAA,
pede 44 por 44.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l13-target\" aria-label=\"Dois desenhos na mesma escala. À esquerda, um quadrado tracejado de 24 por 24 pixels CSS ao lado do botão Done do planner antes da correção, 39 por 18: o botão é mais baixo que o quadrado. À direita, o mesmo quadrado ao lado do botão depois da correção, com pelo menos 24 pixels de altura, tão alto quanto o quadrado. Uma nota diz que um alvo menor que 24 pixels ainda passa se um círculo de 24 pixels em volta do centro dele não tocar outro alvo.\"><rect x=\"40\" y=\"40\" width=\"96\" height=\"96\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"152\" y=\"64\" width=\"156\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Done</text><text x=\"174.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">antes: 39 × 18</text><text x=\"88\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">24 × 24 px CSS</text><rect x=\"390\" y=\"40\" width=\"96\" height=\"96\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"502\" y=\"40\" width=\"188\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"596.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Done</text><text x=\"540.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">depois: pelo menos 24 de altura</text><text x=\"438\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">24 × 24 px CSS</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">menor ainda passa se um círculo de 24 px em volta não tocar outro alvo</text></svg>", "caption": "O 2.5.8 Tamanho do alvo (Mínimo), nível AA. A regra é sobre a caixa que a pessoa precisa acertar, não sobre o tamanho do texto dentro dela.", "same": ["Done"]}
```

A aula 1 desenhou o botão **Done** pequeno de propósito: `font-size: 0.7rem; padding: 1px 4px`. Um teste
que mede todo botão, num arquivo novo, `e2e/display.spec.ts`:

```typescript
// e2e/display.spec.ts
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
});

test("every button is at least 24 by 24 pixels", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  const small: string[] = [];
  for (const button of await page.getByRole("button").all()) {
    const box = (await button.boundingBox())!;
    if (box.width < 24 || box.height < 24) {
      small.push(`${await button.textContent()}: ${Math.round(box.width)}×${Math.round(box.height)}`);
    }
  }
  expect(small).toEqual([]);
});
```

O `boundingBox()` é o retângulo que o navegador desenhou, em pixels CSS, então é o tamanho que a pessoa
encontra.

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (349ms)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "Done: 39×18",
    + ]
  1 failed
```

**Dezoito pixels de altura.** Ele é largo o bastante, porque *Done* tem quatro letras, e baixo demais,
porque o padding é de um pixel. A correção mantém o texto pequeno e dá ao botão o tamanho em volta dele:

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index ee4b83f..c47851f 100644
--- a/src/style.css
+++ b/src/style.css
@@ -25,7 +25,7 @@ li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
 .courses img { vertical-align: middle; margin-right: 0.4rem; }
 .mins { color: var(--quiet); }
 .session.done { color: var(--done); }
-.tick { font-size: 0.7rem; padding: 1px 4px; }
+.tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }
 :focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
```

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (290ms)
  1 passed (3.3s)
ana@dev:~/planner$ git add -A && git commit -qm "A Done button at least 24 pixels square"
```

O `min-height` e o `min-width` definem o piso sem fixar o tamanho, então um rótulo maior, em outra língua,
ainda faz um botão maior.

**A regra é escrita para o `.tick`, e só para o `.tick`.** O outro botão passa porque por acaso é grande: o
formulário põe os campos numa linha só, e uma linha flex estica todo item até a altura do mais alto, o
textarea da nota. Guarde esse *por acaso* por duas seções.
