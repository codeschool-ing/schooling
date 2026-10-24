---
title: Um foco que dá para ver
version: 1
---

**A folha de estilo da aula 1 tem uma linha que esconde onde o foco está:**

```css
button:focus { outline: none; }
```

É uma das linhas mais comuns da web, e é escrita por um bom motivo aplicado do jeito errado. Os navegadores
desenhavam o anel de foco em volta de um botão sempre que ele era clicado, as pessoas achavam o anel feio
depois de um clique, e o jeito mais rápido de tirá-lo era tirá-lo de todo mundo. A pessoa de quem ele foi
tirado é justamente a que precisa dele: alguém no teclado, que agora aperta Tab e não vê nada se mexer.
Isso falha no 2.4.7 *Foco visível*, nível AA.

## O teste

Um contorno é um estilo, então este teste pergunta ao navegador o estilo do elemento com foco. Acrescente-o
ao `e2e/keyboard.spec.ts`:

```typescript
// e2e/keyboard.spec.ts, below what is there
test("the focused control can be seen", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await tabThrough(page, 2);
  const done = page.getByRole("button", { name: "Done" });
  await expect(done).toBeFocused();
  const outline = await done.evaluate((e) => {
    const style = getComputedStyle(e);
    return { style: style.outlineStyle, width: parseFloat(style.outlineWidth) };
  });
  expect(outline.style).not.toBe("none");
  expect(outline.width).toBeGreaterThanOrEqual(2);
});
```

O foco chega pelo Tab, do jeito que chega para a pessoa por quem o teste fala. O teste pede um contorno
desenhado e com pelo menos dois pixels de largura, que é a espessura que o 2.4.13 *Aparência do foco* pede
no AAA; o AA só pede que o foco possa ser visto.

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts -g 'can be seen' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (370ms)
    Expected: not "none"
  1 failed
```

## A correção: `:focus-visible`

**O CSS tem um seletor exatamente para o caso que a linha antiga tentava resolver.** O `:focus-visible`
casa com um elemento com foco só quando o navegador julga que a pessoa precisa ver o foco: sempre depois de
uma tecla, e não depois de um clique do mouse num botão. Um campo de texto casa com ele seja como for que
foi alcançado, porque a pessoa vai digitar nele. Troque a linha:

```css
:focus-visible { outline: 3px solid #2f6f4e; outline-offset: 2px; }
```

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index ada6bc6..69ba45a 100644
--- a/src/style.css
+++ b/src/style.css
@@ -7,7 +7,7 @@ li { padding: 0.4rem 0; border-bottom: 1px solid #ddd; }
 .mins { color: #555; }
 .session.done { color: #6b6b6b; }
 .tick { font-size: 0.7rem; padding: 1px 4px; }
-button:focus { outline: none; }
+:focus-visible { outline: 3px solid #2f6f4e; outline-offset: 2px; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
 @keyframes pulse { 50% { transform: scale(1.06); } }
```

A cor é o verde dos links do planner, a **5,99:1** contra o branco, bem acima dos 3:1 de que um indicador de
foco precisa para se destacar do que está em volta. O deslocamento põe dois pixels de branco entre o botão
e o anel, de modo que o anel seja visto contra a página e não contra o cinza do próprio botão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l11-focus\" aria-label=\"Dois desenhos do mesmo botão Done com o foco nele. À esquerda, sob a regra button:focus { outline: none; }, o botão fica igual a quando não tem o foco: nada mostra que o Tab chegou. À direita, sob :focus-visible { outline: 3px solid #2f6f4e; outline-offset: 2px; }, um anel verde de três pixels de espessura envolve o botão, com um espaço de dois pixels entre eles.\"><defs><marker id=\"l11-focus-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">button:focus { outline: none; }</text><rect x=\"145\" y=\"62\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Done</text><text x=\"180\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">o Tab chegou, e nada mostra</text><text x=\"540\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:focus-visible { outline: 3px … }</text><rect x=\"500\" y=\"57\" width=\"80\" height=\"46\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></rect><rect x=\"505\" y=\"62\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Done</text><text x=\"540\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">um anel de 3px, a 2px, a 5,99:1</text><path d=\"M350 80 L370 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-focus-ah-paper-dim)\"></path></svg>", "caption": "O mesmo botão, focado pelo teclado, sob a regra antiga e a nova. O anel é desenhado fora do botão, então é visto contra a página.", "same": ["Done"]}
```

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (340ms)
  ✓  2 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (253ms)
  2 passed (4.7s)
```

**Como o navegador decide.** Uma tecla torna visível o foco seguinte; um clique do mouse num botão não. Um
foco movido por um script herda a decisão do que a pessoa fez por último, e é nisso que as duas próximas
seções se apoiam: o foco que elas mandam para algum lugar depois de uma tecla mostra o anel, e depois de um
clique não mostra.
