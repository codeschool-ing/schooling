---
title: O que o axe encontra no planner
version: 1
---

**O planner foi escrito na aula 1 sem ninguém verificar a acessibilidade dele, e a aula 3 corrigiu uma
coisa por acaso.** Eis o que o axe acha dele agora, com o servidor de desenvolvimento no ar:

```
ana@dev:~/planner$ node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/: 1 rule(s) broken
  image-alt (critical): Images must have alternative text
    a[href$="#/course/html-css"] > img  Element does not have an alt attribute
    a[href$="#/course/javascript"] > img  Element does not have an alt attribute
    a[href$="#/course/git"] > img  Element does not have an alt attribute
http://localhost:5173/#/course/javascript: 1 rule(s) broken
  color-contrast (serious): Elements must meet minimum color contrast ratio thresholds
    .done  Element has insufficient color contrast of 2.32 (foreground color: #aaaaaa, background color: #ffffff, font size: 12.0pt (16px), font weight: normal). Expected contrast ratio of 4.5:1
    span  Element has insufficient color contrast of 2.32 (foreground color: #aaaaaa, background color: #ffffff, font size: 12.0pt (16px), font weight: normal). Expected contrast ratio of 4.5:1
```

**Duas regras, cinco elementos.** Leia cada linha como o axe a escreveu:

- **`image-alt`, critical.** Os três ícones de livro da página inicial são elementos `<img>` sem `alt`
  nenhum. Um leitor de tela que encontra um deles diz alguma coisa, em geral o nome do arquivo, `book.svg`,
  três vezes numa lista de três cursos. É o critério 1.1.1 *Conteúdo não textual*, nível A.
- **`color-contrast`, serious.** As sessões marcadas como feitas aparecem em `#aaaaaa` sobre branco, a
  **2,32:1**, onde o AA pede 4,5:1 para texto deste tamanho. Dois elementos o quebram, a linha da sessão e
  a palavra *done* dentro dela. É o 1.4.3 *Contraste (Mínimo)*, nível AA.

## Um teste que segura o piso

O programa lê; um teste recusa. Salve isto como `e2e/a11y.spec.ts`:

```typescript
// e2e/a11y.spec.ts
import { expect, test } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const wcag22aa = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];
const pages = [
  ["the course list", "/"],
  ["a course page", "/#/course/javascript"],
];

for (const [name, address] of pages) {
  test(`${name} breaks no WCAG 2.2 AA rule axe can check`, async ({ page }) => {
    await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
    await page.goto(address);
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
    expect(violations.map((v) => `${v.id}: ${v.nodes.length}`)).toEqual([]);
  });
}
```

**A asserção é uma lista vazia, e a falha imprime o que há nela**: o id de cada regra e quantos elementos a
quebram, o que basta para saber em que rodar o `axe.mjs`.

```
ana@dev:~/planner$ npx playwright test e2e/a11y.spec.ts --reporter=list 2>&1 | grep -E "^  (✓|✘)|^    [-+] |passed|failed"
  ✘  1 [chromium] › e2e/a11y.spec.ts:12:3 › the course list breaks no WCAG 2.2 AA rule axe can check (1.4s)
  ✘  2 [chromium] › e2e/a11y.spec.ts:12:3 › a course page breaks no WCAG 2.2 AA rule axe can check (1.3s)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "image-alt: 3",
    + ]
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "color-contrast: 2",
    + ]
  2 failed
```
